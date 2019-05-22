
Pod::Spec.new do |s|
    s.name             = 'XAudioRecorder'
    s.version          = '0.0.1'
    s.summary          = 'A short description of XAudioRecorder.'
    
    s.description      = <<-DESC
    TODO: Add long description of the pod here.
    DESC
    
    s.homepage         = 'http://git.51wakeup.cn:81/iOS-Team/XAudioRecorder'
    s.license          = { :type => 'MIT', :file => 'LICENSE' }
    s.author           = { '1020166296@qq.com' => '1020166296@qq.com' }
    s.source           = { :git => 'git@git.51wakeup.cn:iOS-Team/XAudioRecorder.git', :branch => 'master' }
    
    s.swift_version = '5.0'
    s.platform     = :ios, "9.0"
    s.frameworks = 'AVFoundation'
    s.module_name = 'XAudioRecorder'
    s.source_files = 'Source/*','Convert/*.{h,m}'
    s.vendored_libraries = 'Convert/*.a'
    
end

