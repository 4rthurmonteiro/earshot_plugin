#if os(iOS)
  import AVFoundation

  /// Shares the app's single `AVAudioSession` between the earshot plugins.
  ///
  /// Deactivating the session stops every engine in the app, so it is
  /// deactivated only when the last earshot user releases it (ADR 0017).
  /// Since ADR 0018, `earshot_capture_darwin` is the only user in current
  /// releases. The count stays so that it keeps working next to
  /// `earshot_classifier_darwin` 0.1.0, which ran its own engine.
  ///
  /// The user count lives in the main thread's dictionary under a fixed
  /// key, where every earshot module can see it.
  enum EarshotAudioSession {
    private static let usersKey = "dev.earshot.audioSession.users"

    /// Configures and activates the session for measurement, and counts one
    /// user. Throws, without counting, if the session cannot be activated.
    static func acquire() throws {
      let session = AVAudioSession.sharedInstance()
      objc_sync_enter(session)
      defer { objc_sync_exit(session) }
      // .measurement turns off the voice processing and automatic gain.
      try session.setCategory(.record, mode: .measurement, options: [])
      try session.setActive(true)
      users += 1
    }

    /// Releases one user, and deactivates the session when none is left.
    static func release() {
      let session = AVAudioSession.sharedInstance()
      objc_sync_enter(session)
      defer { objc_sync_exit(session) }
      guard users > 0 else { return }
      users -= 1
      if users == 0 {
        try? session.setActive(false, options: .notifyOthersOnDeactivation)
      }
    }

    private static var users: Int {
      get { Thread.main.threadDictionary[usersKey] as? Int ?? 0 }
      set { Thread.main.threadDictionary[usersKey] = newValue }
    }
  }
#endif
