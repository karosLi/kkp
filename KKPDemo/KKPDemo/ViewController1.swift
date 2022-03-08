//
//  BaseViewController.swift
//  kkp
//
//  Created by karos li on 2022/3/7.
//

import UIKit

/**
 使用 kkp_class() 覆盖 Swift 类时，类名应为 项目名.原类名，例如项目 demo 里用 Swift 定义了 ViewController 类，在 lua 覆盖这个类方法时要这样写：
 kkp_class({"demo.ViewController"})
 
 对于调用已在 swift 定义好的类，也是一样：
 kkp_class_index("demo.ViewController")
 
 需要注意几点：
 1、只支持调用继承自 NSObject 的 Swift 类，其继承自父类的属性和方法可以在 lua 调用
 2、其他自定义属性需要加 @objc 关键字才行
 3、其他自定义方法需要加 @objc 和 dynamic 关键字才行
 
 若方法的参数/属性类型为 Swift 特有(如 Character / Tuple)，则此方法和属性无法通过 lua 调用。
 
 https://mp.weixin.qq.com/s?__biz=MzUxMzcxMzE5Ng==&mid=2247488491&idx=1&sn=a5364eacd752f455837179681f4a774c&source=41#wechat_redirect
 */

class ViewController1: BaseViewController {
    @objc var a = "a"
    @objc private var pa = "pa"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .yellow
        
        print("【原生】KKPDemo.ViewController1 当前 title:\(self.title!)")
        print("【原生】KKPDemo.ViewController1 当前 a:\(a)")
        print("【原生】KKPDemo.ViewController1 当前 pa:\(pa)")
        
        doManyThing("写代码")
    }
    
    @objc dynamic func doManyThing(_ thingName: String) {
        print("【原生】KKPDemo.ViewController1 thingName: \(thingName)")
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}
