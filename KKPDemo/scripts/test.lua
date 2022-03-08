-- require("CustomTableViewController")

-- 替换 swift 类
-- 添加新类，一个文件里也可以定义多个类
kkp_class({"KKPDemo.ViewController1"},
function(_ENV)
    function viewDidLoad()
        kkp.print("【LUA】KKPDemo.ViewController1 viewDidLoad")
        
        self:setTitle_("NEW VC")
        kkp.print("【LUA】KKPDemo.ViewController1 viewDidLoad title", self:title())
        
        kkp.print("【LUA】KKPDemo.ViewController1 viewDidLoad 修改之前 a", self:a())
        kkp.print("【LUA】KKPDemo.ViewController1 viewDidLoad 修改之前 pa", self:pa())
        
        self:setA_("new_a")
        self:setPa_("new_a")
        
        kkp.print("【LUA】KKPDemo.ViewController1 viewDidLoad 修改之后 a", self:a())
        kkp.print("【LUA】KKPDemo.ViewController1 viewDidLoad 修改之后 pa", self:pa())
        
        self.origin:viewDidLoad()
    end
    
    function doManyThing_(thingName)
        -- 打印原生入参
        kkp.print("【LUA】KKPDemo.ViewController1 打印原生入参 thingName", thingName)
    end
    
    function dealloc()
        kkp.print("【LUA】KKPDemo.ViewController1 dalloc")
    end
end)

-- 添加新类，一个文件里也可以定义多个类
kkp_class({"Custom1TableViewController", "UIViewController"},
function(_ENV)

    function init()
        self.super.init()
        kkp.print("【LUA】Custom1TableViewController init", self)
        self.trends = {}
        self.aa = 2222
        
        return self
    end

    function viewDidLoad()
        kkp.print("【LUA】Custom1TableViewController viewDidLoad", self.aa)
        self:view():setBackgroundColor_(UIColor:greenColor())
    end
    
    function dealloc()
        kkp.print("【LUA】Custom1TableViewController dalloc")
    end
end)

-- 准备 hook 的类名
kkp_class({"ViewController"},
function(_ENV)
    function viewDidLoad()
        self.origin:viewDidLoad()
    end

    -- hook 实例方法
    function doSomeThing_(thingName)
        -- 打印枚举
        kkp.print("【LUA】ViewController 打印枚举 UIImagePickerControllerCameraFlashModeOn", UIImagePickerControllerCameraFlashModeOn)
        -- 打印原生入参
        kkp.print("【LUA】ViewController 打印原生入参 thingName", thingName)
        -- 设置/获取 lua 属性
        self.aa = "hh"
        kkp.print("【LUA】ViewController 获取 lua 属性 aa", self.aa)
        -- 设置/获取 原生 属性
        self:setAge_(18)
        kkp.print("【LUA】ViewController 获取 原生 属性 age", self:age())
        -- 动态添加 设置/获取 原生 属性
        self:setSex_("男")
        kkp.print("【LUA】ViewController 获取 动态 原生 属性 sex", self:sex())
        -- 设置/获取 原生 私有 变量
        self:setIvar_withInteger_("_aInteger", 666)
        kkp.print("【LUA】ViewController 获取 原生 私有变量 _aInteger", self:getIvarInteger_("_aInteger"))
        -- 调用实例方法
        kkp.print("【LUA】ViewController 获取原生调用结果 getHello() ", self:getHello())
        kkp.print("【LUA】ViewController 获取原生调用结果 getViewSize()", tostring(self:getViewSize()))
        -- 调用当前类的静态方法
        ViewController:printHello()
        self:view():setBackgroundColor_(UIColor:redColor())
        -- 调用原始方法
        self.origin:doSomeThing_(thingName)
        -- 调用父类方法
        self.super:doSomeThing_(thingName)
        -- 使用工具方法
        kkp.print("【LUA】ViewController 使用工具方法", NSDocumentDirectory)
    end

    -- 添加新类
    function onClickGotoButton()
        -- local controller = CustomTableViewController:alloc():init()
        local controller = Custom1TableViewController:alloc():init()
        -- local controller = kkp_class_index("KKPDemo.ViewController1"):alloc():init()
        self:navigationController():pushViewController_animated_(controller, true)
    end

    -- hook 带有 oc block 参数的实例方法
    function blockOneArg_(block)
        -- 调用原生 block
        self:setIndex_(block(12))
    end

    -- hook 返回值是 oc block 的实例方法，block 带参数和返回值
    function blockReturnBoolWithString()
        -- 把 lua 函数包装成一个 oc block，原生在实际调用 oc block 时，会触发包裹的 lua 函数代码
        return kkp_block(function(string) kkp.print("【LUA】ViewController 原生调用 lua 提供的 oc block 参数是", string, "性别", self:sex()) return "哈哈" end, "NSString *,NSString *")
    end
    
    -- hook 返回值是 结构体 实例方法
    function getViewSize()
        return CGSize({width=55,height=66})
    end
    
    -- hook 返回值是 结构体 实例方法
    function argInRect_(vRect)
        vRect.x = 10
        self:setVRect_(vRect)
        return vRect
    end

end,
function(_ENV)

    -- hook 静态方法
    function printHello()
        ViewController:testStatic()
    end

end)

