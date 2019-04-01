# Uncomment the next line to define a global platform for your project
platform :ios, '11.0'

target 'XRViewer' do
  # Uncomment the next line if you're using Swift or would like to use dynamic frameworks
    use_frameworks!

  # Pods for ArDemo
  # https://github.com/CocoaLumberjack/CocoaLumberjack/issues/882
    pod 'CocoaLumberjack'
    pod 'CocoaLumberjack/Swift'
    pod 'PopupDialog'
    pod 'pop'
    # Temporarily pointing to Swift 4 & Xcode 10.2 compatible fork of https://github.com/mozilla-mobile/telemetry-ios
    pod 'MozillaTelemetry', :git => 'https://github.com/robomex/telemetry-ios.git', :branch => 'swift4'
    pod 'FontAwesomeKit'
    pod "GCDWebServer", "~> 3.0"
end


# Enable DEBUG flag in Swift for SwiftTweaks
post_install do |installer|
    installer.pods_project.targets.each do |target|
        if target.name == 'MozillaTelemetry'
            target.build_configurations.each do |config|
                config.build_settings['SWIFT_VERSION'] = '4.0'
            end
        end
    end
end
