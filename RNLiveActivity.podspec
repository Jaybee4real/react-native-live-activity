require 'json'

package = JSON.parse(File.read(File.join(__dir__, 'package.json')))

Pod::Spec.new do |s|
  s.name         = 'RNLiveActivity'
  s.version      = package['version']
  s.summary      = package['description']
  s.homepage     = package['homepage'] || 'https://github.com/Jaybee4real/react-native-live-activity'
  s.license      = package['license']
  s.author       = package['author'] || 'Novacraft Engineering'
  s.platform     = :ios, '15.0'
  s.source       = { :git => 'https://github.com/Jaybee4real/react-native-live-activity.git', :tag => s.version.to_s }
  s.source_files = 'ios/**/*.{swift,h,m,mm}'
  s.swift_version = '5.0'
  s.requires_arc = true

  s.dependency 'React-Core'
end
