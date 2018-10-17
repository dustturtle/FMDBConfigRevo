//
//  GCFMDBHelper.m
//  FMDBConfigRevo
//
//  Created by Zhenwei Guan on 2018/10/16.
//  Copyright © 2018 Zhenwei Guan. All rights reserved.
//

#import "GCFMDBHelper.h"
#import "GlobalConfig.h"

@implementation GCFMDBHelper

+ (NSMutableArray *)propertyConfigsFromClass:(Class)cls
{
    NSMutableArray *configs = [NSMutableArray array];
    
    unsigned int propertyCount = 0;
    objc_property_t *properties = class_copyPropertyList(cls, &propertyCount);
    
    if (properties)
    {
        for (unsigned int i = 0; i < propertyCount; i++)
        {
            GCConfigInfo *configInfo = [[GCConfigInfo alloc] initWithProperty:properties[i]];
            if (configInfo.key && configInfo.type)
            {
                [configs addObject:configInfo];
            }
        }
        
        free(properties);
    }
    
    return configs;
}

//根据变量类型返回对应的数据库字段类型。 暂时没有用到。
+ (NSString *)dataBaseTypeWithEncodeName:(NSString *)encode
{
    if ([encode isEqualToString:[NSString stringWithUTF8String:@encode(int)]]
        ||[encode isEqualToString:[NSString stringWithUTF8String:@encode(unsigned int)]]
        ||[encode isEqualToString:[NSString stringWithUTF8String:@encode(long)]]
        ||[encode isEqualToString:[NSString stringWithUTF8String:@encode(unsigned long)]]
        ||[encode isEqualToString:[NSString stringWithUTF8String:@encode(BOOL)]]
        ) {
        return @"INTEGER";
    }
    if ([encode isEqualToString:[NSString stringWithUTF8String:@encode(float)]]
        ||[encode isEqualToString:[NSString stringWithUTF8String:@encode(double)]]
        ) {
        return @"REAL";
    }
    if ([encode rangeOfString:@"String"].length) {
        return @"TEXT";
    }
    if ([encode rangeOfString:@"NSNumber"].length) {
        return @"REAL";
    }
    if ([encode rangeOfString:@"NSData"].length) {
        return @"BLOB";
    }
    if ([encode rangeOfString:@"NSDate"].length) {
        return @"TIMESTAMP";
    }
    return nil;
}

@end
