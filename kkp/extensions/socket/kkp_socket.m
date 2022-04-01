//
//  kkp_socket.m
//  kkp
//
//  Created by karos li on 2022/4/1.
//

#import "kkp_socket.h"
#import "lauxlib.h"
#import "luasocket.h"
#import "kkp.h"
#import "kkp_define.h"
#import "kkp_helper.h"
#import "kkp_converter.h"
#include "kkp_socket_code.h"

/// https://github.com/lunarmodules/luasocket

static int luaopen_lua_ltn12(lua_State *L)
{
    return kkp_safeInLuaStack(L, ^int{
        const char *code = kkp_socket_code_ltn12();
        luaL_loadstring(L, code);
        return 1;
    });
}

static int luaopen_lua_mime(lua_State *L)
{
    return kkp_safeInLuaStack(L, ^int{
        const char *code = kkp_socket_code_mime();
        luaL_loadstring(L, code);
        return 1;
    });
}

static int luaopen_lua_socket_ftp(lua_State *L)
{
    return kkp_safeInLuaStack(L, ^int{
        const char *code = kkp_socket_code_ftp();
        luaL_loadstring(L, code);
        return 1;
    });
}

static int luaopen_lua_socket_headers(lua_State *L)
{
    return kkp_safeInLuaStack(L, ^int{
        const char *code = kkp_socket_code_headers();
        luaL_loadstring(L, code);
        return 1;
    });
}

static int luaopen_lua_socket_http(lua_State *L)
{
    return kkp_safeInLuaStack(L, ^int{
        const char *code = kkp_socket_code_http();
        luaL_loadstring(L, code);
        return 1;
    });
}

static int luaopen_lua_socket_mbox(lua_State *L)
{
    return kkp_safeInLuaStack(L, ^int{
        const char *code = kkp_socket_code_mbox();
        luaL_loadstring(L, code);
        return 1;
    });
}

static int luaopen_lua_socket_smtp(lua_State *L)
{
    return kkp_safeInLuaStack(L, ^int{
        const char *code = kkp_socket_code_smtp();
        luaL_loadstring(L, code);
        return 1;
    });
}

static int luaopen_lua_socket_tp(lua_State *L)
{
    return kkp_safeInLuaStack(L, ^int{
        const char *code = kkp_socket_code_tp();
        luaL_loadstring(L, code);
        return 1;
    });
}

static int luaopen_lua_socket_url(lua_State *L)
{
    return kkp_safeInLuaStack(L, ^int{
        const char *code = kkp_socket_code_url();
        luaL_loadstring(L, code);
        return 1;
    });
}

static int luaopen_lua_socket_core(lua_State *L)
{
    return kkp_safeInLuaStack(L, ^int{
        lua_pushcfunction(L, luaopen_socket_core);
        return 1;
    });
}

static int luaopen_lua_socket_socket(lua_State *L)
{
    return kkp_safeInLuaStack(L, ^int{
        const char *code = kkp_socket_code_socket();
        luaL_loadstring(L, code);
        return 1;
    });
}

static struct luaL_Reg libs[] = {
    {"ltn12", luaopen_lua_ltn12},
    {"mime", luaopen_lua_mime},
    {"socket.ftp", luaopen_lua_socket_ftp},
    {"socket.headers", luaopen_lua_socket_headers},
    {"socket.http", luaopen_lua_socket_http},
    {"socket.mbox", luaopen_lua_socket_mbox},
    {"socket.smtp", luaopen_lua_socket_smtp},
    {"socket.tp", luaopen_lua_socket_tp},
    {"socket.url", luaopen_lua_socket_url},
    {"socket.core", luaopen_lua_socket_core},
    {"socket", luaopen_lua_socket_socket},
    {NULL, NULL}
};

void luaopen_kkp_socket(lua_State *L)
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
