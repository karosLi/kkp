//
//  kkp_define.h
//  LearnLua
//
//  Created by karos li on 2022/1/25.
//

#ifndef kkp_define_h
#define kkp_define_h

/// 自定义用户数据，类 和 实例对象都会用到
typedef struct _KKPInstanceUserdata {
    __weak id instance;// 如果是类用户数据，代表的是 class；如果是实例用户数据，代表的是 实例
    bool isClass;
    bool isCallSuper;// 是否调用父类方法
    bool isCallOrigin;// 是否调用原始方法
    bool isBlock;
} KKPInstanceUserdata;

/// 自定义用户数据，结构体会用到
typedef struct _KKPStructUserdata {
    void *data;// 实际数据，里面存储的数据根据 typeDescription 来决定
    size_t size;// 数据总大小
    char *name;// lua定义的结构体名字，比如 "CGSize"
    char *types;// lua定义的结构体签名，比如 "dd"
} KKPStructUserdata;

#define KKP_ENV_SCOPE @"_SCOPE" // 用于保存 lua 中的 _ENV 当前环境
#define KKP_ENV_SCOPE_SELF @"self"// 用于在 lua 函数中，使用 self 关键字
#define KKP_SUPER_KEYWORD @"super"// 用于在 lua 函数中，使用 self.super 关键字，比如：self.super:doSomething()
#define KKP_ORIGIN_KEYWORD @"origin" // 用于在 lua 函数中，使用 self.origin 关键字，比如：self.origin:doSomething()

#define KKP_ORIGIN_PREFIX @"KKPORIG" // 用于方法替换时，给原方法添加前缀
#define KKP_SUPER_PREFIX @"KKPSUPER"
#define KKP_STATIC_PREFIX @"KKPSTATIC"
#define KKP_ORIGIN_FORWARD_INVOCATION_SELECTOR_NAME @"__kkp_origin_forwardInvocation:"


#endif /* kkp_define_h */
