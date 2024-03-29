# kkp

一个 lua 热修复框架，通过 lua 代码动态下发、动态修复已存在的类和创建类

## 1. 功能列表 

|功能特性|备注限制|
|------|-------|
|**替换指定`ObjectC`方法实现**          | 实例/静态方法均可替换实现|
|**动态创建新类和新方法供Native/lua调用**          | 需传入定义协议|
|**支持添加属性**                     |为已存在的`class`添加关联属性|
|**支持访问私有变量**                      | `lua` 可以读取和修改私有变量 |
|**支持基础数据类型**                   |对象类型和非对象类型都支持|
|**支持`block`**                      |支持在 `lua` 中创建 block 和 调用 block|
|**支持结构体**                     |支持在 `lua` 注册和创建结构体|
|**常用c函数调用**                   |支持如 `dispatch_after`，`dispatch_async` 等函数调用|
|**调试**                   |支持 lua 脚本调试|


## 2. 安装

### CocoaPods

1. 在 Podfile 中添加  `pod 'kkp'`。
2. 执行 `pod install` 或 `pod update`。
3. 导入 `<kkp/kkp.h>`


## 3.文档介绍

[基础用法](https://github.com/karosLi/kkp/wiki/%E5%9F%BA%E7%A1%80%E7%94%A8%E6%B3%95)
