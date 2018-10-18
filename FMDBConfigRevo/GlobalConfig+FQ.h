//
//  GlobalConfig+FQ.h
//  SignIn
//
//  key-value形式的配置项持久化存储和访问类。
//
//
//  Created by KevinJack on 18/10/17.
//  Copyright (c) 2018年 QCStudio. All rights reserved.
//

#import "GlobalConfig.h"
#import <UIKit/UIKit.h>

#define GFQConfig [GlobalConfig sharedInstance]

@interface GlobalConfig (FQ)
//
//@property (nonatomic, copy) NSString *screenAlwaysOn;
//@property (nonatomic, copy) NSString *strictModeOn;
//@property (nonatomic, copy) NSString *silenceMode;
//
//// 保存默认的番茄钟长度，格式：30 (用字符串表示的数字,单位为分钟)
//@property (nonatomic, copy) NSString *timeInterval;
//
//// 每日的目标信息；其中包含了：day／numTotal／finished 这三个 key; 当被覆盖时，之前的信息被存储到全局数据库。
//@property (nonatomic) NSMutableDictionary *dayTargetInfo;

@property (nonatomic, assign) BOOL isLogin;

@property (nonatomic, copy) NSString *userName;

@property (nonatomic, assign) NSInteger bbbt;

@property (nonatomic, strong) NSDictionary *infoDic;

@end
