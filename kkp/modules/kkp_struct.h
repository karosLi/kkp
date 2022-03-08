//
//  kkp_struct.h
//  LearnLua
//
//  Created by karos li on 2022/2/23.
//

#import <Foundation/Foundation.h>
#import "lua.h"

#define KKP_STRUCT "kkp.struct" // lua struct module
#define KKP_STRUCT_META_TABLE "kkpStructMetaTable" // lua struct module meta table
#define KKP_STRUCT_USER_DATA_META_TABLE "kkpStructUserDataMetaTable" // struct user data meta table

/// 用于获取所有注册的结果信息
extern NSMutableDictionary * kkp_struct_registeredStructs(void);
/// 用于创建结构体 user data
extern int kkp_struct_create_userdata(lua_State *L, const char *name, const char *typeDescription, void *structData);

LUAMOD_API int luaopen_kkp_struct(lua_State *L);
