//
//  kkp_class.h
//  LearnLua
//
//  Created by karos li on 2022/1/25.
//

#import <Foundation/Foundation.h>
#import "lua.h"

#define KKP_CLASS "kkp.class" // lua class module
#define KKP_CLASS_META_TABLE "kkpClassMetaTable" // lua class module meta table
#define KKP_CLASS_USER_DATA_META_TABLE "kkpClassUserDataMetaTable" // class user data meta table
#define KKP_CLASS_USER_DATA_LIST_TABLE "kkpClassUserDataListTable" // for save all class user data

extern void kkp_class_cleanClass(NSString *className);
extern int kkp_class_create_userdata(lua_State *L, Class klass);

LUAMOD_API int luaopen_kkp_class(lua_State *L);
