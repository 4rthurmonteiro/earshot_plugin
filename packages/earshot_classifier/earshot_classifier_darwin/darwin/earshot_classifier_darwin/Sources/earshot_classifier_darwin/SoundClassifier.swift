import AVFoundation
import SoundAnalysis

/// Classifies PCM with SoundAnalysis for any number of sessions.
///
/// The PCM comes from earshot_capture, through Dart (ADR 0018): this class
/// never opens the microphone, reads its permission or touches the audio
/// session. Each session has its own `SNAudioStreamAnalyzer` and
/// `SNClassifySoundRequest` (version 1), built for the sample rate of its
/// first chunk. The analyzer is rebuilt when the rate changes or the
/// timestamps jump, after an interruption, so that timestamps stay on the
/// capture clock.
///
/// Every method must be called on the main thread, and `onEvent` runs on the
/// main thread. Analyzers run on a serial background queue.
final class SoundClassifier {
  var onEvent: (ClassifierEventMessage) -> Void = { _ in }

  /// The minimum confidence of each running session.
  private var sessions: [Int64: Double] = [:]
  private lazy var analysis = AnalysisQueue(
    onResult: { [weak self] id, timestampMicros, classifications in
      guard let self, self.sessions[id] != nil else { return }
      self.onEvent(
        ClassifierEventMessage(
          sessionId: id, timestampMicros: timestampMicros, classifications: classifications))
    },
    onFailure: { [weak self] id, message in
      guard let self, self.sessions[id] != nil else { return }
      self.onEvent(
        ClassifierEventMessage(
          sessionId: id, timestampMicros: 0, classifications: [], errorCode: "modelUnavailable",
          errorMessage: message))
      self.stop(id: id)
    })

  /// Whether SoundAnalysis can classify on this OS. Never prompts the user.
  static func isAvailable() -> Bool {
    (try? SNClassifySoundRequest(classifierIdentifier: .version1)) != nil
  }

  /// Starts session `id`. It analyzes the PCM passed to `analyze`.
  func start(id: Int64, minConfidence: Double) throws {
    guard Self.isAvailable() else {
      throw PigeonError(
        code: "unsupported", message: "SoundAnalysis cannot classify on this OS.", details: nil)
    }
    stop(id: id)
    sessions[id] = minConfidence
  }

  /// Queues `samples`, little-endian float32 mono at `sampleRate`, for the
  /// analyzer of session `id`. Does nothing if the session is not running.
  func analyze(id: Int64, sampleRate: Int64, timestampMicros: Int64, samples: Data) {
    guard let minConfidence = sessions[id], sampleRate > 0,
      samples.count >= MemoryLayout<Float>.size
    else { return }
    analysis.analyze(
      id: id, minConfidence: minConfidence, sampleRate: Double(sampleRate),
      timestampMicros: timestampMicros, samples: samples)
  }

  /// Stops session `id`. Safe to call when it is not running.
  func stop(id: Int64) {
    guard sessions.removeValue(forKey: id) != nil else { return }
    analysis.remove(id: id)
  }

  /// Stops every session.
  func stopAll() {
    for id in sessions.keys { stop(id: id) }
  }
}

/// Owns the analyzers and feeds them PCM, on a serial queue.
private final class AnalysisQueue {
  /// Timestamps that differ by more than this from the end of the previous
  /// chunk start a new analyzer. Contiguous chunks differ by under 1 µs.
  private static let maxDriftMicros: Double = 1000

  private let queue = DispatchQueue(label: "earshot_classifier_darwin.analysis")
  private let onResult: (Int64, Int64, [ClassificationMessage]) -> Void
  private let onFailure: (Int64, String) -> Void
  /// Only touched on `queue`.
  private var targets: [Int64: Target] = [:]

  private final class Target {
    let analyzer: SNAudioStreamAnalyzer
    let format: AVAudioFormat
    /// Kept alive here, whether or not the analyzer retains it.
    let observer: ResultsObserver
    /// The timestamp of the analyzer's first frame.
    let baseMicros: Int64
    var framePosition: AVAudioFramePosition = 0

    init(
      analyzer: SNAudioStreamAnalyzer, format: AVAudioFormat, observer: ResultsObserver,
      baseMicros: Int64
    ) {
      self.analyzer = analyzer
      self.format = format
      self.observer = observer
      self.baseMicros = baseMicros
    }

    /// The timestamp the next contiguous chunk starts at.
    var nextMicros: Double {
      Double(baseMicros) + Double(framePosition) * 1_000_000 / format.sampleRate
    }
  }

  /// `onResult` and `onFailure` are called on the main thread.
  init(
    onResult: @escaping (Int64, Int64, [ClassificationMessage]) -> Void,
    onFailure: @escaping (Int64, String) -> Void
  ) {
    self.onResult = onResult
    self.onFailure = onFailure
  }

  func analyze(
    id: Int64, minConfidence: Double, sampleRate: Double, timestampMicros: Int64,
    samples: Data
  ) {
    queue.async {
      var existing = self.targets[id]
      if let current = existing,
        current.format.sampleRate != sampleRate
          || abs(Double(timestampMicros) - current.nextMicros) > Self.maxDriftMicros
      {
        // Flush the last partial window before the gap or rate change.
        current.analyzer.completeAnalysis()
        existing = nil
      }
      let target: Target
      if let existing {
        target = existing
      } else {
        do {
          target = try self.makeTarget(
            id: id, minConfidence: minConfidence, sampleRate: sampleRate,
            baseMicros: timestampMicros)
        } catch {
          self.targets[id] = nil
          let message = "SoundAnalysis could not start: \(error.localizedDescription)"
          DispatchQueue.main.async { self.onFailure(id, message) }
          return
        }
        self.targets[id] = target
      }
      guard let buffer = Self.buffer(samples, format: target.format) else { return }
      target.analyzer.analyze(buffer, atAudioFramePosition: target.framePosition)
      target.framePosition += AVAudioFramePosition(buffer.frameLength)
    }
  }

  func remove(id: Int64) {
    queue.async { self.targets.removeValue(forKey: id)?.analyzer.removeAllRequests() }
  }

  private func makeTarget(
    id: Int64, minConfidence: Double, sampleRate: Double, baseMicros: Int64
  ) throws -> Target {
    guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1) else {
      throw PigeonError(
        code: "unsupported", message: "Unsupported sample rate \(sampleRate) Hz.", details: nil)
    }
    let request = try SNClassifySoundRequest(classifierIdentifier: .version1)
    let analyzer = SNAudioStreamAnalyzer(format: format)
    let onResult = self.onResult
    let onFailure = self.onFailure
    let observer = ResultsObserver(
      minConfidence: minConfidence, baseMicros: baseMicros,
      onResult: { timestampMicros, classifications in
        DispatchQueue.main.async { onResult(id, timestampMicros, classifications) }
      },
      onFailure: { message in
        DispatchQueue.main.async { onFailure(id, message) }
      })
    try analyzer.add(request, withObserver: observer)
    return Target(analyzer: analyzer, format: format, observer: observer, baseMicros: baseMicros)
  }

  /// Copies little-endian float32 `samples` into a buffer of `format`. Every
  /// Apple platform is little-endian, so the bytes are copied as they are.
  private static func buffer(_ samples: Data, format: AVAudioFormat) -> AVAudioPCMBuffer? {
    let frames = samples.count / MemoryLayout<Float>.size
    guard frames > 0,
      let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(frames)),
      let channel = buffer.floatChannelData?[0]
    else { return nil }
    buffer.frameLength = AVAudioFrameCount(frames)
    samples.withUnsafeBytes { bytes in
      // The bytes may be unaligned, so copy them rather than rebinding them.
      UnsafeMutableRawPointer(channel).copyMemory(
        from: bytes.baseAddress!, byteCount: frames * MemoryLayout<Float>.size)
    }
    return buffer
  }
}

/// Receives SoundAnalysis results on the analysis queue and forwards the
/// classifications at or above `minConfidence`.
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
    onResult(baseMicros + Int64((start.isFinite ? start : 0) * 1_000_000), classifications)
  }

  func request(_ request: SNRequest, didFailWithError error: Error) {
    onFailure("SoundAnalysis failed: \(error.localizedDescription)")
  }
}
