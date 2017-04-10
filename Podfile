# Uncomment the next line to define a global platform for your project
# platform :ios, '9.0'

inhibit_all_warnings!

target 'Leap' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!

  # Pods for Leap
  pod 'Lock', '~> 2.0'
  pod 'Auth0', '~> 1.2'
  pod 'SwiftyJSON'
  pod 'RealmSwift'
  
  pod 'Fabric'
  pod 'Crashlytics'

  target 'LeapTests' do
    inherit! :search_paths
    # Pods for testing
  end

  target 'LeapUITests' do
    inherit! :search_paths
    # Pods for testing
  end

end

post_install do |installer|
    installer.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
            config.build_settings['SWIFT_VERSION'] = '3.0'
        end
    end
end
