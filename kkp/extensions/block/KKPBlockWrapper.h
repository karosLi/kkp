//
//  KKPBlockHelper.h
//  Example
//
//  Created by tianyubing on 2020/8/4.
//  Copyright © 2020 TianyuBing. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "lua.h"

typedef enum {
    // Set to true on blocks that have captures (and thus are not true
    // global blocks) but are known not to escape for various other
    // reasons. For backward compatiblity with old runtimes, whenever
    // BLOCK_IS_NOESCAPE is set, BLOCK_IS_GLOBAL is set too. Copying a
    // non-escaping block returns the original block and releasing such a
    // block is a no-op, which is exactly how global blocks are handled.
    KKPKit_BLOCK_IS_NOESCAPE = (1 << 23),
    KKPKit_BLOCK_HAS_COPY_DISPOSE = (1 << 25),
    KKPKit_BLOCK_HAS_CTOR = (1 << 26),  // helpers have C++ code
    KKPKit_BLOCK_IS_GLOBAL = (1 << 28),
    KKPKit_BLOCK_HAS_STRET = (1 << 29),  // IFF BLOCK_HAS_SIGNATURE
    KKPKit_BLOCK_HAS_SIGNATURE = (1 << 30),
} KKPKit_BLOCK_FLAGS;

/// block 结构 https://blog.csdn.net/hengsf123456/article/details/116990585
struct KKPKitBlock {
    void *isa; // initialized to &_NSConcreteStackBlock or &_NSConcreteGlobalBlock
    int flags;
    int reserved;
    void (*invoke)(void *, ...);
    struct KKPKitBlockDescriptor *descriptor;
    // imported variables
    void *wrapper;
};

struct KKPKitBlockDescriptor {
    struct {
        unsigned long int reserved;
        unsigned long int size;
    };
    struct {
        // requires BLOCK_HAS_COPY_DISPOSE
        void (*copy)(void *dst, const void *src);
        void (*dispose)(const void *);
    };
    struct {
        // requires BLOCK_HAS_SIGNATURE
        const char *signature;
    };
};

/// 用于包括 lua 函数
@interface KKPBlockWrapper : NSObject
- (id)initWithTypeEncoding:(NSString *)typeEncoding state:(lua_State *)state funcIndex:(int)funcIndex;

/// hook oc block invoke 函数，并返回一个 block 指针
- (void *)blockPtr;

@end

