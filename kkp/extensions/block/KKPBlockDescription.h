//
//  KKPBlockDescription.h
//  LearnLua
//
//  Created by karos li on 2022/1/25.
//  code from https://github.com/ebf/CTObjectiveCRuntimeAdditions

#import <Foundation/Foundation.h>

@interface KKPBlockDescription : NSObject

@property (nonatomic, readonly) NSMethodSignature *blockSignature;
@property (nonatomic, readonly) unsigned long int size;
@property (nonatomic, readonly) id block;

- (id)initWithBlock:(id)block;

@end
