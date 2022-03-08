//
//  kkp_config.h
//  LearnLua
//
//  Created by karos li on 2022/2/25.
//

#import <Foundation/Foundation.h>
#import "lua.h"

/**
    openBindOCFunction: then you can use C function list in extension/capi/bind/pkg
    mobdebug: then you can use lua debug tool like ZeroBraneStudio
 *  kkp config. like kkp.setConfig({openBindOCFunction="true", mobdebug="true"})
 */
extern int kkp_global_setConfig(lua_State *L);
extern NSDictionary *kkp_global_getConfig(void);
