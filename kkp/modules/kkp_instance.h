//
//  kkp_instance.h
//  LearnLua
//
//  Created by karos li on 2022/1/25.
//

#import <Foundation/Foundation.h>
#import "lua.h"

#define KKP_INSTANCE "kkp.instance" // lua instance module
#define KKP_INSTANCE_META_TABLE "kkpInstanceMetaTable" // lua instance module meta table
#define KKP_INSTANCE_USER_DATA_META_TABLE "kkpInstanceUserDataMetaTable" // instance user data meta table
#define KKP_INSTANCE_USER_DATA_LIST_TABLE "kkpInstanceUserDataListTable" // for save all instance user data

extern void kkp_instance_pushUserdata(lua_State *L, id object);
extern int kkp_instance_create_userdata(lua_State *L, id object);

LUAMOD_API int luaopen_kkp_instance(lua_State *L);
