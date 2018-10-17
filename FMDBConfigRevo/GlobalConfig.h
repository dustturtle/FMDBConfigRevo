//
//  GlobalConfig.h
//  SignIn
//
//  FMDB based config.
//
//  Created by KevinJack on 15/9/17.
//  Copyright (c) 2015年 QCStudio. All rights reserved.
//
//  !!!!! 注意 !!!!! 使用前必读～
//  为了避免麻烦，尽量使得实现清晰和简洁，我们这里需要遵守的前置约定（合约,使用者必读）：
//  1.配置只增加，不能减少。
//  2.配置的类型不允许变更。
//  3.不能使用id这个字符串作为属性名（db里面的主键已经占用了这个名字）。
//  4.key的default需要在键被加入的时候即被创建。
//  5.非对象类型的default值不允许变更（变更不会生效）。

#import <Foundation/Foundation.h>
#import <objc/runtime.h>

@interface GlobalConfig : NSObject

+ (instancetype)sharedInstance;

//delete the record, then create a new one.
- (void)clearAllConfigs;

@end

@interface GCConfigInfo : NSObject
@property (nonatomic, copy) NSString *key;
@property (nonatomic, copy) NSString *type;

- (instancetype)initWithProperty:(objc_property_t)property;
@end
