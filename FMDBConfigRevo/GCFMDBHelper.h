//
//  GCFMDBHelper.h
//  FMDBConfigRevo
//
//  Created by Zhenwei Guan on 2018/10/16.
//  Copyright © 2018 Zhenwei Guan. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface GCFMDBHelper : NSObject

// 从class获取到属性的config列表
+ (NSMutableArray *)propertyConfigsFromClass:(Class)cls;

// 根据编码获取到fmdb存储用的字符串类型；暂未使用到，后续可改造并用之。
//+ (NSString *)dataBaseTypeWithEncodeName:(NSString *)encode;

@end

