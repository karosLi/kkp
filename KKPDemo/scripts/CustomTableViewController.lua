kkp.setConfig({openBindOCFunction=true})

kkp_protocol("CustomTableViewProtocol", {
    refreshView = "void,void",
},{
    refreshData_ = "void,NSDictionary*"
})

kkp_class({"CustomTableViewController", "UIViewController", protocols={"CustomTableViewProtocol", "UITableViewDataSource"}},
function(_ENV)

    function init()
        self.super.init()
        kkp.print("【LUA】CustomTableViewController init", self)
        self.trends = {}
        self.aa = 1111;
        
        local size = CGSize({width = 22.0, height = 33.0})
        local copySize = size:copy()
        size.width = 45.0
        kkp.print("【LUA】CGSize", size.width)
        size.height = 56.0
        -- 结构体打印，需要使用 tostring 方法
        kkp.print("【LUA】CustomTableViewController CGSize", tostring(size))
        kkp.print("【LUA】CustomTableViewController copy CGSize", tostring(copySize))
        return self
    end

    function viewDidLoad()
        kkp.print("【LUA】CustomTableViewController viewDidLoad", self.aa)
        self:view():setBackgroundColor_(UIColor:blueColor())
        
        CustomTableViewController:refreshData_({key = "value", key1 = "value1"})
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), kkp_block(function()
            kkp.print("【LUA】CustomTableViewController dispatch_after 回调")
        end, "void,void"))
        
        self:refreshView()
    end

    function refreshView()
        kkp.print("【LUA】CustomTableViewController refreshView", self.aa)
        -- 运行时错误，测试运行时错误获取 lua 堆栈
        -- n = n / nil
        
        -- 语法错误，测试语法错误获取 lua 堆栈
        -- ddd
    end

    function dealloc()
        kkp.print("【LUA】CustomTableViewController dalloc")
    end

    -- DataSource
    -------------
    function numberOfSectionsInTableView_(tableView)
      return 1
    end

end,
function(_ENV)

    function refreshData_(data)
        kkp.print("【LUA】CustomTableViewController STATICrefreshData", data)
        for k,v in pairs(data) do
            kkp.print("【LUA】CustomTableViewController STATICrefreshData", k, v)
        end
    end

end)


