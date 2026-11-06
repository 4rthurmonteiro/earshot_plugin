#if os(iOS)
  import AVFoundation

  /// Shares the app's single `AVAudioSession` between the earshot plugins.
  ///
  /// `earshot_capture_darwin` and `earshot_classifier_darwin` each run their
  /// own `AVAudioEngine` on the one audio session of the app. Deactivating
  /// the session stops every engine in the app, so it is deactivated only
  /// when the last earshot user releases it (ADR 0017).
  ///
  /// The two plugins are separate modules, so the user count lives in the
  /// main thread's dictionary under a fixed key, where both can see it.
  /// Keep this file identical in both packages.
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
