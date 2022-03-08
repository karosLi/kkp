//
//  kkp_config.m
//  LearnLua
//
//  Created by karos li on 2022/2/25.
//

#import "kkp_global_config.h"
#import "kkp_converter.h"
#import "kkp_capi.h"

static NSDictionary *configDict;

int kkp_global_setConfig(lua_State *L)
{
    if (lua_isnil(L, -1)){
        return 0;
    } else {
        void *value = kkp_toOCObject(L, "@", -1);
        __unsafe_unretained id instance = (__bridge  id)(*(void **)value);
        free(value);
        
        if ([instance isKindOfClass:[NSDictionary class]]){
            if ([instance objectForKey:@"openBindOCFunction"]){
                kkp_openBindOCFunction(L);
            }
        }
    }
    return 0;
}

NSDictionary *kkp_global_getConfig(void)
{
    return configDict;
}
