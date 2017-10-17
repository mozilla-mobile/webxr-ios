# Uncomment the next line to define a global platform for your project
platform :ios, '11.0'

target 'XRViewer' do
  # Uncomment the next line if you're using Swift or would like to use dynamic frameworks
    use_frameworks!

  # Pods for XRViewer
  # https://github.com/CocoaLumberjack/CocoaLumberjack/issues/882
    pod 'CocoaLumberjack', :git => 'https://github.com/CocoaLumberjack/CocoaLumberjack.git', :branch => 'master'
    pod 'PopupDialog', '~> 0.5'
    pod 'pop', '~> 1.0'
end

post_install do |installer|
    installer.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
            config.build_settings['SWIFT_VERSION'] = '3.2'
        end
    end
end
