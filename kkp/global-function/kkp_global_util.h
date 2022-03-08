//
//  kkp_global_util.h
//  LearnLua
//
//  Created by karos li on 2022/2/25.
//

#import <Foundation/Foundation.h>
#import "lua.h"

extern int kkp_global_isGreaterThanOS(lua_State *L);
extern int kkp_global_isNull(lua_State *L);
extern int kkp_global_print(lua_State *L);
extern int kkp_global_root(lua_State *L);
extern int kkp_global_exitApp(lua_State *L);
