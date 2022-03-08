//
//  kkp_capi.h
//  LearnLua
//
//  Created by karos li on 2022/2/25.
//

/// 默认是没有开启 c 函数绑定，需要 lua 脚本设置是否开启 c 函数绑定

#import <Foundation/Foundation.h>
#import "lua.h"

extern id kkp_objectFromLuaState(lua_State *L, int index);

/// 用于绑定 c 函数，绑定后，lua 就可以使用这些 c 函数
extern void kkp_openBindOCFunction(lua_State *L);
