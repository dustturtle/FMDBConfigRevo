//
//  GlobalConfig.h
//  SignIn
//
//  FMDB based config.
//  key-value形式的配置项持久化存储和访问类。
//
//  Created by KevinJack on 18/10/17.
//  Copyright (c) 2018年 QCStudio. All rights reserved.
//
//  !!!!! 注意 !!!!! 使用前必读～
//  为了避免麻烦，尽量使得实现清晰和简洁，我们这里需要遵守的前置约定（合约,使用者必读）：
//  1.配置只增加，不能减少。
//  2.配置的类型不允许变更。
//  3.不能使用id这个字符串作为属性名（db里面的主键已经占用了这个名字）。
//  4.key的default需要在键被加入的时候即被创建;字符串的default不能为@"",如果不设置会返回nil。
//  5.非对象类型的default值不允许变更（变更不会生效）。
//  6.给配置项设置为nil(对象或者string)不会起任何作用，输入被认为是非法的。
//  7.如果要清除某一项的值建议输入一个空对象，比如@""/@[]/@{} 这种。目前不提供方法来清除某个单独的配置（有全部清除的方法）。
//
//  TODO: unit test.

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
