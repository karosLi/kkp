Pod::Spec.new do |s|
  s.name         = "kkp"
  s.version      = "1.0.0"
  s.summary      = "lua 热修复框架"

  s.description  = "lua 热修复框架
功能特性：
实例方法和静态方法替换
添加新类和定义协议
基础数据转换
结构体支持
block 创建
常用c函数调用
  "
  s.platform = :ios, "9.0"
  s.homepage     = "https://github.com/karosLi/kkp"
  s.license      = { :type => 'MIT', :file => 'LICENSE' }
  s.author       = { "Karosli" => "karosli1314@gmail.com" }
  s.source       = { :git => "https://github.com/karosLi/kkp.git", :tag => "#{s.version}" }
  s.public_header_files = "kkp/**/*.h"
  s.source_files = "kkp/**/*.{h,m,c}"
  s.ios.vendored_libraries = "kkp/libffi/libffi.a"
  s.pod_target_xcconfig = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64', 'OTHER_LDFLAGS' => ['-ObjC' , '-all_load'] }
  s.user_target_xcconfig = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64', 'OTHER_LDFLAGS' => ['-ObjC' , '-all_load'] }
  s.requires_arc = true
end

