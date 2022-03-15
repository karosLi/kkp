kkp_class({"ViewController"},
function(_ENV)

    function setMyView()
        -- 设置/获取 原生 私有 变量
        self:setIvar_withInteger_("_aInteger", 666)
        kkp.print("【LUA】ViewController 获取 原生 私有变量 _aInteger", self:getIvarInteger_("_aInteger"))
    
        local view = UIView:alloc():init()
        self:view():addSubview_(view)
        view:setBackgroundColor_(UIColor:greenColor())
        view:mas__makeConstraints_(kkp_block(
            function(make)
                make:center():equalTo()(self:view())
                make:width():offset()(50)
                make:height():offset()(50)
            end,
            "void,MASConstraintMaker *"
        ))
    end

    function requestAPI_(completion)
        local url = "https://github.com/karosLi/kkp/blob/main/kkp/stdlib/init.lua"
        local req = NSURLRequest:requestWithURL_(NSURL:URLWithString_(url))
        local dataTask = NSURLSession:sharedSession():dataTaskWithRequest_completionHandler_(req, kkp_block(
            function(data, response, error)
                if completion then
                    completion(NSString:alloc():initWithData_encoding_(data, NSUTF8StringEncoding))
                end
            end,
            "void,id,id,id"
        ))
        dataTask:resume()
    end
end)

