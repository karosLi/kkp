//
//  kkp_runtime_helper.m
//  LearnLua
//
//  Created by karos li on 2022/1/28.
//

#import "kkp_runtime_helper.h"
#import "kkp_define.h"
#import "kkp_helper.h"

void kkp_runtime_swizzleForwardInvocation(Class klass, IMP newforwardInvocationIMP)
{
    NSCParameterAssert(klass);
    if (class_getMethodImplementation(klass, @selector(forwardInvocation:)) != newforwardInvocationIMP) {// 防止重复替换
        // get origin forwardInvocation impl, include superClass impl，not NSObject impl, and class method to kClass
        SEL originForwardSelector = NSSelectorFromString(KKP_ORIGIN_FORWARD_INVOCATION_SELECTOR_NAME);
        if (![klass instancesRespondToSelector:originForwardSelector]) {
            Method originalMethod = class_getInstanceMethod(klass, @selector(forwardInvocation:));
            IMP originalImplementation = method_getImplementation(originalMethod);
            class_addMethod(klass, NSSelectorFromString(KKP_ORIGIN_FORWARD_INVOCATION_SELECTOR_NAME), originalImplementation, "v@:@");
            
        }
        // If there is no method, replace will act like class_addMethod.
        class_replaceMethod(klass, @selector(forwardInvocation:), newforwardInvocationIMP, "v@:@");
    }
}

BOOL kkp_runtime_isMsgForwardIMP(IMP impl)
{
    return impl == _objc_msgForward
#if !defined(__arm64__)
    || impl == (IMP)_objc_msgForward_stret
#endif
    ;
}

IMP kkp_runtime_getMsgForwardIMP(Class kClass, const char *typeDescription)
{
    IMP msgForwardIMP = _objc_msgForward;
#if !defined(__arm64__)
    // As an ugly internal runtime implementation detail in the 32bit runtime, we need to determine of the method we hook returns a struct or anything larger than id.
    // https://developer.apple.com/library/mac/documentation/DeveloperTools/Conceptual/LowLevelABI/000-Introduction/introduction.html
    // https://github.com/ReactiveCocoa/ReactiveCocoa/issues/783
    // http://infocenter.arm.com/help/topic/com.arm.doc.ihi0042e/IHI0042E_aapcs.pdf (Section 5.4)
    if (typeDescription[0] == '{') {
        //In some cases that returns struct, we should use the '_stret' API:
        //http://sealiesoftware.com/blog/archive/2008/10/30/objc_explain_objc_msgSend_stret.html
        //NSMethodSignature knows the detail but has no API to return, we can only get the info from debugDescription.
        NSMethodSignature *methodSignature = [NSMethodSignature signatureWithObjCTypes:typeDescription];
        if ([methodSignature.debugDescription rangeOfString:@"is special struct return? YES"].location != NSNotFound) {
            msgForwardIMP = (IMP)_objc_msgForward_stret;
        }
    }
#endif
    return msgForwardIMP;
}

SEL kkp_runtime_originForSelector(SEL sel)
{
    NSCParameterAssert(sel);
    return NSSelectorFromString([KKP_ORIGIN_PREFIX stringByAppendingFormat:@"%@", NSStringFromSelector(sel)]);
}

NSString *kkp_runtime_methodTypesInProtocol(Protocol *protocol, NSString *selectorName, BOOL isInstanceMethod, BOOL isRequired)
{
    unsigned int selCount = 0;
    struct objc_method_description *methods = protocol_copyMethodDescriptionList(protocol, isRequired, isInstanceMethod, &selCount);
    for (int i = 0; i < selCount; i ++) {
        NSString *methodSelectorName = NSStringFromSelector(methods[i].name);
        if ([selectorName isEqualToString:methodSelectorName]) {
            NSString *types = [NSString stringWithUTF8String:methods[i].types];
            free(methods);
            return types;
        }
    }
    free(methods);
    return nil;
}
