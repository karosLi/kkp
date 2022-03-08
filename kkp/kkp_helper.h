//
//  kkp_helper.h
//  LearnLua
//
//  Created by karos li on 2022/1/25.
//

#import <Foundation/Foundation.h>
#import "lua.h"

#define KKP_PROTOCOL_TYPE_CONST 'r'
#define KKP_PROTOCOL_TYPE_IN 'n'
#define KKP_PROTOCOL_TYPE_INOUT 'N'
#define KKP_PROTOCOL_TYPE_OUT 'o'
#define KKP_PROTOCOL_TYPE_BYCOPY 'O'
#define KKP_PROTOCOL_TYPE_BYREF 'R'
#define KKP_PROTOCOL_TYPE_ONEWAY 'V'

extern bool kkp_recordLuaError(NSString *error);
#define KKP_ERROR(L, err)                                                                               \
NSString *_errorString = [NSString stringWithFormat:@"[KKP] error %s line %d %s: %@", __FILE__, __LINE__, __FUNCTION__, err];\
if (kkp_recordLuaError(_errorString)) {                                                                          \
} else {                                                                                                \
    luaL_error(L, "%s", _errorString.UTF8String);   \
}

typedef int (^kkp_lua_stack_safe_block_t)(void);
typedef int (^kkp_lua_lock_safe_block_t)(void);

extern int kkp_safeInLuaStack(lua_State *L, kkp_lua_stack_safe_block_t block);

extern int kkp_performLocked(kkp_lua_lock_safe_block_t block);

extern void kkp_stackDump(lua_State *L);

extern int kkp_pcall(lua_State *L, int argumentCount, int returnCount);

extern int kkp_dostring(lua_State *L, const char *script);

extern int kkp_dofile(lua_State *L, const char *fname);

extern int kkp_dobuffer(lua_State *L, NSData *data, const char *name);

extern const char* kkp_removeProtocolEncodings(const char *typeDescription);

extern const char* kkp_toObjcSel(const char *luaFuncName);

extern char* kkp_toObjcPropertySel(const char *prop);

extern const char* kkp_toLuaFuncName(const char *objcSel);

extern NSString *kkp_trim(NSString *string);

extern NSString *kkp_removeAllWhiteSpace(NSString *string);

extern bool kkp_isAllocMethod(const char *methodName);

extern bool kkp_isBlock(id object);

extern int kkp_callLuaFunction(lua_State *L, __unsafe_unretained id assignSlf, SEL selector, NSInvocation *invocation);

extern int kkp_callBlock(lua_State *L);

extern int kkp_alloc_closure(lua_State *L);

extern int kkp_invoke_closure(lua_State *L);
