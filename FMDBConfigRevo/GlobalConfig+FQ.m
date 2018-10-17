//
//  GlobalConfig+FQ.m
//  SignIn
//
//  Created by KevinJack on 15/9/17.
//  Copyright (c) 2015年 QCStudio. All rights reserved.
//

#import "GlobalConfig+FQ.h"
#import <objc/runtime.h>


@implementation GlobalConfig (FQ)

@dynamic userName;
@dynamic bbbt;
//@dynamic screenAlwaysOn;
//@dynamic strictModeOn;
//@dynamic silenceMode;
//@dynamic timeInterval;

@dynamic isLogin;

@dynamic infoDic;

// Category need to implement this method to setup default values.
- (NSDictionary *)setupDefaults
{
    //
    return @{@"isLogin":@(YES),@"userName":@"gzw",@"bbbt":@(999),@"infoDic":@{@"desc":@"qinanshanAgoodStud"}};
    
//    return @{
//             @"silenceMode":@"0",
//             @"screenAlwaysOn":@"0",
//             @"strictModeOn":@"0",
//             @"timeInterval":@"25"
//             };
}

@end
