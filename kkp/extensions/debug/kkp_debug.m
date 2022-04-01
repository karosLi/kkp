//
//  kkp_debug.m
//  kkp
//
//  Created by karos li on 2022/4/1.
//

#import "kkp_debug.h"
#import "lauxlib.h"
#import "kkp.h"
#import "kkp_define.h"
#import "kkp_helper.h"
#import "kkp_converter.h"
#include "kkp_debug_code.h"

/// https://github.com/pkulchenko/MobDebug
///
/// 加载 mobdebug
static int luaopen_lua_mobdebug(lua_State *L)
{
    return kkp_safeInLuaStack(L, ^int{
        const char *code = kkp_debug_code();
        luaL_loadstring(L, code);
        return 1;
    });
}

static struct luaL_Reg libs[] = {
    {"mobdebug", luaopen_lua_mobdebug},
    {NULL, NULL}
};

void luaopen_kkp_debug(lua_State *L)
{
    luaL_Reg* lib = libs;
    lua_getglobal(L, "package");
    lua_getfield(L, -1, "preload");
    for (; lib->func; lib++)
    {
        lib->func(L);
        lua_setfield(L, -2, lib->name);
    }
    lua_pop(L, 2);
}
