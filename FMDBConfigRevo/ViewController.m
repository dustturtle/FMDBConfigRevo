//
//  ViewController.m
//  FMDBConfigRevo
//
//  Created by Zhenwei Guan on 2018/10/13.
//  Copyright © 2018 Zhenwei Guan. All rights reserved.
//

#import "ViewController.h"
#import "GlobalConfig+FQ.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    id abb = [NSKeyedArchiver archivedDataWithRootObject:nil];
    
    // test codes below.
    GFQConfig.userName = nil;
    
    
    
    NSDictionary *dic = GFQConfig.infoDic;
    BOOL flag = GFQConfig.isLogin;
    NSString *name = GFQConfig.userName;
    
    GFQConfig.userName = @"chencheng";
    
    NSInteger a = GFQConfig.bbbt;
    
    NSLog(@"int        : %s", @encode(BOOL));
    
    GFQConfig.infoDic = @{@"ttt":@"qinanshanisAcutegirlwererererererererererererererererererererererererererererer"};
    
    //[GlobalConfig sharedInstance];
    
    //[GFQConfig clearAllConfigs];
}


@end
