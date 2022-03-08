//
//  kkp_capi.m
//  LearnLua
//
//  Created by karos li on 2022/2/25.
//

#import "kkp_capi.h"
#import "tolua++.h"
#import "kkp_converter.h"

extern id kkp_objectFromLuaState(lua_State *L, int index)
{
    if (lua_isnil(L, index)){
        return nil;
    } else{
        void *value = kkp_toOCObject(L, "@", index);
        __unsafe_unretained id instance = (__bridge  id)(*(void **)value);
        free(value);
        return instance;
    }
}

/// 用于绑定 c 函数，绑定后，lua 就可以使用这些 c 函数
extern void kkp_openBindOCFunction(lua_State *L)
{
    TOLUA_API int  luaopen_dispatch_lua (lua_State* tolua_S);
    luaopen_dispatch_lua (L);
}
