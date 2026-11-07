#
# CocoaPods fallback for apps that have SwiftPM turned off.
# Keep sources and minimum OS versions in sync with earshot_classifier_darwin/Package.swift.
#
Pod::Spec.new do |s|
  s.name             = 'earshot_classifier_darwin'
  s.version          = '0.1.0'
  s.summary          = 'iOS and macOS implementation of earshot_classifier.'
  s.description      = <<-DESC
iOS and macOS implementation of earshot_classifier: on-device sound classification with SoundAnalysis.
                       DESC
  s.homepage         = 'https://github.com/4rthurmonteiro/earshot_plugin'
  s.license          = { :type => 'MIT', :file => '../LICENSE' }
  s.author           = { 'Arthur Monteiro' => 'https://github.com/4rthurmonteiro' }
  s.source           = { :path => '.' }
  s.source_files     = 'earshot_classifier_darwin/Sources/earshot_classifier_darwin/**/*.swift'
  s.resource_bundles = { 'earshot_classifier_darwin_privacy' => ['earshot_classifier_darwin/Sources/earshot_classifier_darwin/PrivacyInfo.xcprivacy'] }

  s.ios.deployment_target = '15.0'
  s.osx.deployment_target = '12.0'

  s.ios.dependency 'Flutter'
  s.osx.dependency 'FlutterMacOS'

  # Flutter.framework does not contain an i386 slice.
  s.ios.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.osx.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }

  s.swift_version = '5.9'
end
