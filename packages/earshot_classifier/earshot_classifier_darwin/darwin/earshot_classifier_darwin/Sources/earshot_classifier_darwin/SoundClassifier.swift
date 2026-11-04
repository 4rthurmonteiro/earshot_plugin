import AVFoundation
import SoundAnalysis

#if os(iOS)
  import UIKit
#endif

/// Classifies the microphone with SoundAnalysis for any number of sessions.
///
/// The sessions share one `AVAudioEngine` input tap, because an input node
/// has one tap per bus, and each session has its own `SNAudioStreamAnalyzer`
/// and `SNClassifySoundRequest` (version 1). The engine starts with the first
/// session and stops, releasing the microphone, with the last one.
///
/// Every method must be called on the main thread, and `onEvent` runs on the
/// main thread. Analyzers run on a serial background queue.
///
/// Interruptions are handled as in earshot_capture (ADR 0013): the engine
/// stops and restarts on its own afterwards, and every analyzer is rebuilt for
/// the new input format. Timestamps are rebased on the time elapsed since each
/// session started, so gaps show up as jumps. If every restart attempt fails,
/// every session ends with an `audioUnavailable` error event.
final class SoundClassifier {
  var onEvent: (ClassifierEventMessage) -> Void = { _ in }

  private var engine = AVAudioEngine()
  private var tapInstalled = false
  private var sessions: [Int64: Session] = [:]
  private var running = false
  /// Whether the first session opened the microphone and the last one has
  /// not released it yet.
  private var active = false
  private var retries = 0
  /// Incremented on every engine (re)start and stop, to drop stale results
  /// and retries.
  private var generation = 0
  private var observers: [NSObjectProtocol] = []
  private var engineObserver: NSObjectProtocol?
  private let analysis = AnalysisQueue()

  private static let maxRetries = 10
  private static let retryDelay: TimeInterval = 0.5
  private static let tapBufferSize: AVAudioFrameCount = 8192

  /// Whether SoundAnalysis can classify on this OS. Never prompts the user.
  static func isAvailable() -> Bool {
    (try? SNClassifySoundRequest(classifierIdentifier: .version1)) != nil
  }

  /// Starts classifying for session `id`.
  func start(id: Int64, minConfidence: Double, permission: Bool) throws {
    guard permission else {
      throw PigeonError(
        code: "permissionDenied", message: "Microphone access has not been granted.", details: nil)
    }
    stop(id: id)
    let session = Session(
      id: id, minConfidence: minConfidence, startUptime: ProcessInfo.processInfo.systemUptime)
    sessions[id] = session

    if sessions.count == 1 {
      active = true
      do {
        #if os(iOS)
          let audioSession = AVAudioSession.sharedInstance()
          // .measurement turns off the voice processing and automatic gain.
          try audioSession.setCategory(.record, mode: .measurement, options: [])
          try audioSession.setActive(true)
        #endif
        retries = 0
        try startEngine()
      } catch {
        sessions[id] = nil
        stopAll()
        throw Self.pigeonError(error, opening: true)
      }
      addObservers()
    } else if running {
      // Join the running engine: the analyzer starts at frame zero.
      do {
        try attach(session, format: engine.inputNode.outputFormat(forBus: 0), baseMicros: 0)
      } catch {
        sessions[id] = nil
        throw Self.pigeonError(error, opening: false)
      }
    }
    // Otherwise the engine is interrupted, and the restart attaches it.
  }

  /// Stops session `id`. Safe to call when it is not running.
  func stop(id: Int64) {
    guard sessions.removeValue(forKey: id) != nil else { return }
    analysis.remove(id: id)
    if sessions.isEmpty { stopAll() }
  }

  /// Stops every session and releases the microphone.
  func stopAll() {
    let wasActive = active
    active = false
    generation += 1
    sessions.removeAll()
    removeObservers()
    stopEngine()
    #if os(iOS)
      if wasActive {
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
      }
    #endif
  }

  // MARK: - Engine

  private func startEngine() throws {
    generation += 1
    let input = engine.inputNode
    let format = input.outputFormat(forBus: 0)
    guard format.sampleRate > 0, format.channelCount > 0 else {
      throw PigeonError(
        code: "audioUnavailable", message: "No microphone input is available.", details: nil)
    }
    let now = ProcessInfo.processInfo.systemUptime
    for session in sessions.values {
      try attach(session, format: format, baseMicros: Int64((now - session.startUptime) * 1_000_000))
    }
    let analysis = self.analysis
    input.installTap(onBus: 0, bufferSize: Self.tapBufferSize, format: format) { buffer, _ in
      analysis.analyze(buffer)
    }
    tapInstalled = true
    engine.prepare()
    do {
      try engine.start()
    } catch {
      stopEngine()
      throw error
    }
    running = true
  }

  private func stopEngine() {
    running = false
    engine.stop()
    if tapInstalled {
      engine.inputNode.removeTap(onBus: 0)
      tapInstalled = false
    }
    analysis.removeAll()
  }

  /// Gives `session` a new analyzer for `format`.
  private func attach(_ session: Session, format: AVAudioFormat, baseMicros: Int64) throws {
    let request = try SNClassifySoundRequest(classifierIdentifier: .version1)
    let analyzer = SNAudioStreamAnalyzer(format: format)
    let generation = self.generation
    let observer = ResultsObserver(
      minConfidence: session.minConfidence, baseMicros: baseMicros,
      onResult: { [weak self] timestampMicros, classifications in
        guard let self, self.generation == generation, self.sessions[session.id] != nil else {
          return
        }
        self.onEvent(
          ClassifierEventMessage(
            sessionId: session.id, timestampMicros: timestampMicros,
            classifications: classifications))
      },
      onFailure: { [weak self] message in
        guard let self, self.generation == generation, self.sessions[session.id] != nil else {
          return
        }
        self.fail(id: session.id, code: "unknown", message: message)
      })
    try analyzer.add(request, withObserver: observer)
    analysis.set(id: session.id, analyzer: analyzer, observer: observer)
  }

  private func fail(id: Int64, code: String, message: String) {
    onEvent(
      ClassifierEventMessage(
        sessionId: id, timestampMicros: 0, classifications: [], errorCode: code,
        errorMessage: message))
    stop(id: id)
  }

  // MARK: - Interruptions

  /// Stops the engine and restarts it unless the system still holds the
  /// microphone.
  private func interrupt(restart: Bool) {
    guard !sessions.isEmpty else { return }
    generation += 1
    stopEngine()
    if restart { self.restart() }
  }

  private func restart() {
    guard !sessions.isEmpty, !running else { return }
    do {
      #if os(iOS)
        try AVAudioSession.sharedInstance().setActive(true)
      #endif
      stopEngine()
      try startEngine()
      retries = 0
    } catch {
      stopEngine()
      retries += 1
      if retries > Self.maxRetries {
        let message =
          "The microphone was interrupted and could not be reopened: \(error.localizedDescription)"
        for id in sessions.keys { fail(id: id, code: "audioUnavailable", message: message) }
        return
      }
      let retryGeneration = generation
      DispatchQueue.main.asyncAfter(deadline: .now() + Self.retryDelay) { [weak self] in
        guard let self, self.generation == retryGeneration else { return }
        self.restart()
      }
    }
  }

  private func addObservers() {
    let center = NotificationCenter.default
    #if os(iOS)
      let audioSession = AVAudioSession.sharedInstance()
      observers.append(
        center.addObserver(
          forName: AVAudioSession.interruptionNotification, object: audioSession, queue: .main
        ) { [weak self] note in
          guard let raw = note.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
            let type = AVAudioSession.InterruptionType(rawValue: raw)
          else { return }
          switch type {
          case .began:
            // The system holds the microphone until the interruption ends.
            self?.interrupt(restart: false)
          case .ended:
            // shouldResume is advice for playback; a recorder always tries.
            self?.restart()
          @unknown default:
            break
          }
        })
      observers.append(
        center.addObserver(
          forName: AVAudioSession.mediaServicesWereResetNotification, object: audioSession,
          queue: .main
        ) { [weak self] _ in
          guard let self, !self.sessions.isEmpty else { return }
          // Every audio object is invalid after a reset: rebuild the engine.
          self.generation += 1
          self.replaceEngine()
          try? audioSession.setCategory(.record, mode: .measurement, options: [])
          self.restart()
        })
      observers.append(
        center.addObserver(
          forName: AVAudioSession.routeChangeNotification, object: audioSession, queue: .main
        ) { [weak self] _ in
          // Usually followed by a configuration change; this covers routes
          // that stop the engine without one.
          guard let self, self.running, !self.engine.isRunning else { return }
          self.interrupt(restart: true)
        })
      observers.append(
        center.addObserver(
          forName: UIApplication.didBecomeActiveNotification, object: nil, queue: .main
        ) { [weak self] _ in
          // Some interruptions (Siri, a declined call) end without an
          // .ended notification.
          self?.restart()
        })
    #endif
    observeEngineConfiguration()
  }

  private func observeEngineConfiguration() {
    if let engineObserver { NotificationCenter.default.removeObserver(engineObserver) }
    engineObserver = NotificationCenter.default.addObserver(
      forName: .AVAudioEngineConfigurationChange, object: engine, queue: .main
    ) { [weak self] _ in
      // The engine stopped and the input format may have changed (a new
      // device, sample rate or channel count): rebuild the tap and analyzers.
      self?.interrupt(restart: true)
    }
  }

  private func replaceEngine() {
    stopEngine()
    engine = AVAudioEngine()
    observeEngineConfiguration()
  }

  private func removeObservers() {
    observers.forEach(NotificationCenter.default.removeObserver)
    observers.removeAll()
    if let engineObserver { NotificationCenter.default.removeObserver(engineObserver) }
    engineObserver = nil
  }

  private static func pigeonError(_ error: Error, opening: Bool) -> PigeonError {
    if let error = error as? PigeonError { return error }
    return PigeonError(
      code: opening ? "audioUnavailable" : "unknown",
      message: "SoundAnalysis could not start: \(error.localizedDescription)", details: nil)
  }
}

/// A classification session started by Dart.
private struct Session {
  let id: Int64
  let minConfidence: Double
  let startUptime: TimeInterval
}

/// Owns the analyzers and feeds them the tap's buffers, on a serial queue.
private final class AnalysisQueue {
  private let queue = DispatchQueue(label: "earshot_classifier_darwin.analysis")
  /// Only touched on `queue`.
  private var targets: [Int64: Target] = [:]

  private final class Target {
    let analyzer: SNAudioStreamAnalyzer
    /// Kept alive here, whether or not the analyzer retains it.
    let observer: ResultsObserver
    var framePosition: AVAudioFramePosition = 0

    init(analyzer: SNAudioStreamAnalyzer, observer: ResultsObserver) {
      self.analyzer = analyzer
      self.observer = observer
    }
  }

  func set(id: Int64, analyzer: SNAudioStreamAnalyzer, observer: ResultsObserver) {
    queue.async { self.targets[id] = Target(analyzer: analyzer, observer: observer) }
  }

  func remove(id: Int64) {
    queue.async { self.targets.removeValue(forKey: id)?.analyzer.removeAllRequests() }
  }

  func removeAll() {
    queue.async {
      self.targets.values.forEach { $0.analyzer.removeAllRequests() }
      self.targets.removeAll()
    }
  }

  /// Called on the audio thread.
  func analyze(_ buffer: AVAudioPCMBuffer) {
    queue.async {
      for target in self.targets.values {
        target.analyzer.analyze(buffer, atAudioFramePosition: target.framePosition)
        target.framePosition += AVAudioFramePosition(buffer.frameLength)
      }
    }
  }
}

/// Receives SoundAnalysis results on the analysis queue and forwards the
/// classifications at or above `minConfidence` to the main thread.
private final class ResultsObserver: NSObject, SNResultsObserving {
  private let minConfidence: Double
  private let baseMicros: Int64
  private let onResult: (Int64, [ClassificationMessage]) -> Void
  private let onFailure: (String) -> Void

  init(
    minConfidence: Double, baseMicros: Int64,
    onResult: @escaping (Int64, [ClassificationMessage]) -> Void,
    onFailure: @escaping (String) -> Void
  ) {
    self.minConfidence = minConfidence
    self.baseMicros = baseMicros
    self.onResult = onResult
    self.onFailure = onFailure
  }

  func request(_ request: SNRequest, didProduce result: SNResult) {
    guard let result = result as? SNClassificationResult else { return }
    let classifications = result.classifications
      .filter { $0.confidence >= minConfidence }
      .map { ClassificationMessage(identifier: $0.identifier, confidence: $0.confidence) }
    guard !classifications.isEmpty else { return }
    let start = result.timeRange.start.seconds
    let timestampMicros = baseMicros + Int64((start.isFinite ? start : 0) * 1_000_000)
    DispatchQueue.main.async { self.onResult(timestampMicros, classifications) }
  }

  func request(_ request: SNRequest, didFailWithError error: Error) {
    let message = "SoundAnalysis failed: \(error.localizedDescription)"
    DispatchQueue.main.async { self.onFailure(message) }
  }
}
