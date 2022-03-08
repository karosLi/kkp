#!/usr/bin/env lua
print("start complie lua")
-- usage: lua luac.lua module-name output.file base_dir starting-file.lua [-L [other-files.lua]*]
--
-- base_dir: The root for all the lua files. So folder modules can be used
--
-- creates a precompiled chunk that preloads all modules listed after
-- -L and then runs all programs listed before -L.
--
-- assumptions:
--    file xxx.lua contains module xxx
--    '/' is the directory separator (could have used package.config)
--    int and size_t take 4 bytes (could have read sizes from header)
--    does not honor package.path
--
-- Luiz Henrique de Figueiredo <lhf@tecgraf.puc-rio.br>
-- Tue Aug  5 22:57:33 BRT 2008
-- This code is hereby placed in the public domain.

local MARK = "////////"
local NAME = "luac"

-- 模块名
local MODULE_NAME = table.remove(arg, 1)
-- 输出文件名
local OUTPUT = table.remove(arg, 1)
-- 输出目录
local BASE_DIR = table.remove(arg, 1)
NAME = "=("..NAME..")"

-- 上面已经移除了三个参数了，arg 长度和数量也会发生变化

local argCount = #arg
local executableIndex
local b

-- 获取第一个 lua 文件的参数位置，比如 标准库目录下有 2 个 lua 脚本，那么这里 argCount 等于 4，这里 executableIndex = 1
-- 1 ..//stdlib/init.lua
-- 2 -L
-- 3 ..//stdlib/class.lua
-- 4 ..//stdlib/init.lua

for i = 1, argCount do
 if arg[i] == "-L" then executableIndex = i - 1 break end
end

if executableIndex + 2 <= argCount then 
	b = "local t=package.preload\n" 
else 
	b = "local t\n" 
end

for i = executableIndex + 2, argCount do
 -- 获取模块名字，比如 class.lua 对应的 模块名是 kkp.class
 local requireString = string.gsub(arg[i], "^" .. string.gsub(BASE_DIR, "(%W)", "%%%1"), "")
 requireString = string.gsub(requireString,"^[%./]*(.-)%.lua$", "%1")
 requireString = string.gsub(requireString, "/", ".")
 requireString = string.gsub(requireString, ".init$", "") -- if it is an init file within a directory... ignore it!
 if MODULE_NAME and #MODULE_NAME > 0 then requireString = MODULE_NAME .. "." .. requireString end

 b = b.."t['"..requireString.."']=function() \n"
 b = b..io.open(arg[i]):read'*a'
 b = b.."end\n"

end

-- 初始化 init.lua
b = b.."require('".. MODULE_NAME .. ".init') \n"

print("b", b)
-- b 就是如下代码
-- local t=package.preload
-- t['kkp.class']=function() ${source_coce} end
-- t['kkp.init']=function() ${source_coce} end

-- 编译字符串，并 dump 出字节码
b = string.dump(assert(load(b, NAME)))
f = assert(io.open(OUTPUT, "wb"))
assert(f:write(b))
print("end complie lua")
assert(f:close())
