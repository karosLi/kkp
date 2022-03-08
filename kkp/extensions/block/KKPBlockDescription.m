//
//  KKPBlockDescription.m
//  LearnLua
//
//  Created by karos li on 2022/1/25.
//

#import "KKPBlockDescription.h"
#import "KKPBlockWrapper.h"

@implementation KKPBlockDescription

- (id)initWithBlock:(id)block
{
    if (self = [super init]) {
        _block = block;
        
        struct KKPKitBlock *blockRef = (__bridge struct KKPKitBlock *)block;
        KKPKit_BLOCK_FLAGS flags = blockRef->flags;
        _size = blockRef->descriptor->size;
        
        if (flags & KKPKit_BLOCK_HAS_SIGNATURE) {
            void *signatureLocation = blockRef->descriptor;
            signatureLocation += sizeof(unsigned long int);
            signatureLocation += sizeof(unsigned long int);
            
            if (flags & KKPKit_BLOCK_HAS_COPY_DISPOSE) {
                signatureLocation += sizeof(void(*)(void *dst, void *src));
                signatureLocation += sizeof(void (*)(void *src));
            }
            
            const char *signature = (*(const char **)signatureLocation);
            _blockSignature = [NSMethodSignature signatureWithObjCTypes:signature];
        }
    }
    return self;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@: %@", [super description], _blockSignature.description];
}

@end
