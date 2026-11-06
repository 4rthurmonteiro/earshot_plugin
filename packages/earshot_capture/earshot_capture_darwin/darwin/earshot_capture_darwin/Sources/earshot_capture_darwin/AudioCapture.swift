import AVFoundation

#if os(iOS)
  import UIKit
#endif

/// Captures float32 mono PCM with an `AVAudioEngine` input tap, converted to
/// the requested rate with `AVAudioConverter`.
///
/// Every method must be called on the main thread, and every callback runs on
/// the main thread.
///
/// Interruptions are reported through `onState`, and capture restarts on its
/// own afterwards:
/// - iOS: audio session interruptions (calls, Siri), media services resets,
///   and route changes.
/// - iOS and macOS: engine configuration changes, such as a new input device.
///
/// `onError` is called only if every restart attempt fails.
final class AudioCapture {
  /// Receives little-endian float32 samples and the time of the first one.
  var onChunk: (Data, Int64) -> Void = { _, _ in }
  var onState: (CaptureStateMessage) -> Void = { _ in }
  var onError: (String, String) -> Void = { _, _ in }

  private var engine = AVAudioEngine()
  /// Whether a tap is installed. Tracked so that `inputNode` is only touched
  /// after the permission check.
  private var tapInstalled = false
  private var sampleRate: Double = 0
  private var state: CaptureStateMessage = .idle
  private var startUptime: TimeInterval = 0
  private var retries = 0
  /// Incremented on every (re)start and stop, to drop stale chunks and retries.
  private var generation = 0
  private var observers: [NSObjectProtocol] = []
  private var engineObserver: NSObjectProtocol?

  private static let maxRetries = 10
  private static let retryDelay: TimeInterval = 0.5

  /// Whether this capture counts as a user of the shared audio session.
  private var holdsAudioSession = false

  /// Opens the microphone at `sampleRate` Hz.
  func start(sampleRate: Double, permission: PermissionStatusMessage) throws {
    stop()
    guard permission == .granted else {
      throw PigeonError(
        code: "permissionDenied", message: "Microphone access has not been granted.", details: nil)
    }
    self.sampleRate = sampleRate
    startUptime = ProcessInfo.processInfo.systemUptime
    retries = 0
    do {
      #if os(iOS)
        try EarshotAudioSession.acquire()
        holdsAudioSession = true
      #endif
      try startEngine(baseMicros: 0)
    } catch let error as PigeonError {
      stop()
      throw error
    } catch {
      stop()
      throw PigeonError(
        code: "audioUnavailable",
        message: "The microphone could not be opened: \(error.localizedDescription)", details: nil)
    }
    addObservers()
    setState(.capturing)
  }

  /// Closes the microphone. Safe to call when not running.
  func stop() {
    generation += 1
    removeObservers()
    stopEngine()
    #if os(iOS)
      // Other earshot engines in the app may still use the session.
      if holdsAudioSession {
        holdsAudioSession = false
        EarshotAudioSession.release()
      }
    #endif
    setState(.idle)
  }

  // MARK: - Engine

  private func startEngine(baseMicros: Int64) throws {
    let input = engine.inputNode
    let inputFormat = input.outputFormat(forBus: 0)
    guard inputFormat.sampleRate > 0, inputFormat.channelCount > 0 else {
      throw PigeonError(code: "audioUnavailable", message: "No microphone input is available.", details: nil)
    }
    guard
      let targetFormat = AVAudioFormat(
        commonFormat: .pcmFormatFloat32, sampleRate: sampleRate, channels: 1, interleaved: false),
      let converter = AVAudioConverter(from: inputFormat, to: targetFormat)
    else {
      throw PigeonError(
        code: "audioUnavailable",
        message: "Cannot convert \(inputFormat) to \(sampleRate) Hz mono.", details: nil)
    }
    // Mix every input channel into the mono output instead of taking the first.
    converter.downmix = true

    let tap = TapContext(
      converter: converter, targetFormat: targetFormat, baseMicros: baseMicros,
      generation: generation)
    input.installTap(onBus: 0, bufferSize: 4096, format: inputFormat) { [weak self] buffer, _ in
      self?.process(buffer, tap)
    }
    tapInstalled = true
    engine.prepare()
    do {
      try engine.start()
    } catch {
      stopEngine()
      throw error
    }
  }

  private func stopEngine() {
    engine.stop()
    if tapInstalled {
      engine.inputNode.removeTap(onBus: 0)
      tapInstalled = false
    }
  }

  /// Runs on the audio thread.
  private func process(_ buffer: AVAudioPCMBuffer, _ tap: TapContext) {
    let ratio = tap.targetFormat.sampleRate / buffer.format.sampleRate
    let capacity = AVAudioFrameCount(Double(buffer.frameLength) * ratio) + 64
    guard let output = AVAudioPCMBuffer(pcmFormat: tap.targetFormat, frameCapacity: capacity)
    else { return }

    var consumed = false
    var error: NSError?
    let status = tap.converter.convert(to: output, error: &error) { _, inputStatus in
      if consumed {
        // Not .endOfStream: the converter keeps its filter state between taps.
        inputStatus.pointee = .noDataNow
        return nil
      }
      consumed = true
      inputStatus.pointee = .haveData
      return buffer
    }
    guard status != .error, output.frameLength > 0, let channel = output.floatChannelData else {
      return
    }

    let frames = Int(output.frameLength)
    let data = Data(bytes: channel[0], count: frames * MemoryLayout<Float>.size)
    let timestampMicros =
      tap.baseMicros + tap.frames * 1_000_000 / Int64(tap.targetFormat.sampleRate)
    tap.frames += Int64(frames)
    let generation = tap.generation
    DispatchQueue.main.async { [weak self] in
      guard let self, self.generation == generation, self.state == .capturing else { return }
      self.onChunk(data, timestampMicros)
    }
  }

  // MARK: - Interruptions

  /// Stops the engine, reports an interruption, and restarts unless the
  /// system still holds the microphone.
  private func interrupt(restart: Bool) {
    guard state != .idle else { return }
    generation += 1
    stopEngine()
    setState(.interrupted)
    if restart { self.restart() }
  }

  private func restart() {
    guard state != .idle else { return }
    let elapsed = ProcessInfo.processInfo.systemUptime - startUptime
    do {
      #if os(iOS)
        try AVAudioSession.sharedInstance().setActive(true)
      #endif
      stopEngine()
      generation += 1
      try startEngine(baseMicros: Int64(elapsed * 1_000_000))
      retries = 0
      setState(.capturing)
    } catch {
      retries += 1
      if retries > Self.maxRetries {
        stop()
        onError(
          "audioUnavailable",
          "The microphone was interrupted and could not be reopened: \(error.localizedDescription)")
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
      let session = AVAudioSession.sharedInstance()
      observers.append(
        center.addObserver(
          forName: AVAudioSession.interruptionNotification, object: session, queue: .main
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
          forName: AVAudioSession.mediaServicesWereResetNotification, object: session, queue: .main
        ) { [weak self] _ in
          guard let self, self.state != .idle else { return }
          // Every audio object is invalid after a reset: rebuild the engine.
          self.generation += 1
          self.replaceEngine()
          self.setState(.interrupted)
          do {
            try session.setCategory(.record, mode: .measurement, options: [])
          } catch {
            // restart() retries and reports the failure.
          }
          self.restart()
        })
      observers.append(
        center.addObserver(
          forName: AVAudioSession.routeChangeNotification, object: session, queue: .main
        ) { [weak self] _ in
          // Usually followed by a configuration change; this covers routes
          // that stop the engine without one.
          guard let self, self.state == .capturing, !self.engine.isRunning else { return }
          self.interrupt(restart: true)
        })
      observers.append(
        center.addObserver(
          forName: UIApplication.didBecomeActiveNotification, object: nil, queue: .main
        ) { [weak self] _ in
          // Some interruptions (Siri, a declined call) end without an
          // .ended notification.
          guard let self, self.state == .interrupted else { return }
          self.restart()
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
      // device, sample rate or channel count): reinstall the tap.
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

  private func setState(_ newState: CaptureStateMessage) {
    guard newState != state else { return }
    state = newState
    onState(newState)
  }
}

/// The per-tap state, owned by the audio thread once the tap is installed.
private final class TapContext {
  let converter: AVAudioConverter
  let targetFormat: AVAudioFormat
  let baseMicros: Int64
  let generation: Int
  var frames: Int64 = 0

  init(converter: AVAudioConverter, targetFormat: AVAudioFormat, baseMicros: Int64, generation: Int)
  {
    self.converter = converter
    self.targetFormat = targetFormat
    self.baseMicros = baseMicros
    self.generation = generation
  }
}
