//
//  GlobalConfig.m
//  SignIn
//
//  Created by KevinJack on 18/10/17.
//  Copyright (c) 2018年 QCStudio. All rights reserved.
//

#import "GlobalConfig.h"
#import "FMDB.h"
#import "GCFMDBHelper.h"
#import "GlobalConfig+FQ.h"


@interface GlobalConfig ()
{
    NSMutableDictionary *_mapping;
}

// 无dynamic标识的属性，动态添加了getter/setter也不会调用其新增的动态方法;这里放心使用。
// 这里对于默认值的实现的细节比较精妙，值得注意。针对具体情况分别采用了两种不同的方式：
// Object对象fmdb查询会返回nil,这种情况再从dic读取;其他类型fmdb会返回默认值，所以通过sql的default column实现。
// 而对于对象(blob)的处理，尝试也使用default column没有成功，所以才使用另外一种方式搞定。
@property (strong, nonatomic) NSDictionary *configDefaults;

@property (nonatomic, strong) FMDatabase *db;
@property (nonatomic, strong) FMDatabaseQueue *dbQueue;
@property (nonatomic, strong) NSMutableDictionary *configDic;

@end

@implementation GlobalConfig

enum TypeEncodings {
    Bool                = 'B',
    Double              = 'd',
    Object              = '@',
    Short               = 's',
    Int                 = 'i',
    Long                = 'l',
    LongLong            = 'q',
    UnsignedInt         = 'I',
    UnsignedLong        = 'L',
    UnsignedLongLong    = 'Q',
    
    String              = 'r',   // 这里的r是后加的，为了编码一致性。是一种特别的情况
};

static BOOL boolGetter(GlobalConfig *self, SEL _cmd)
{
    NSString *key = [self defaultsKeyForSelector:_cmd];
    return [self boolFromKey:key];
}

static void boolSetter(GlobalConfig *self, SEL _cmd, BOOL value)
{
    NSString *key = [self defaultsKeyForSelector:_cmd];
    [self configWithKey:key value:[NSNumber numberWithBool:value]];
}

static double doubleGetter(GlobalConfig *self, SEL _cmd)
{
    NSString *key = [self defaultsKeyForSelector:_cmd];
    return [self doubleFromKey:key];
}

static void doubleSetter(GlobalConfig *self, SEL _cmd, double value)
{
    NSString *key = [self defaultsKeyForSelector:_cmd];
    [self configWithKey:key value:[NSNumber numberWithDouble:value]];
}

static long long longLongGetter(GlobalConfig *self, SEL _cmd)
{
    NSString *key = [self defaultsKeyForSelector:_cmd];
    return [self longlongFromKey:key];
}

static void longLongSetter(GlobalConfig *self, SEL _cmd, long long value)
{
    NSString *key = [self defaultsKeyForSelector:_cmd];
    [self configWithKey:key value:[NSNumber numberWithLongLong:value]];
}

static NSString * stringGetter(GlobalConfig *self, SEL _cmd)
{
    NSString *key = [self defaultsKeyForSelector:_cmd];
    return [self stringFromKey:key];
}

static void stringSetter(GlobalConfig *self, SEL _cmd, NSString *value)
{
    NSString *key = [self defaultsKeyForSelector:_cmd];
    [self configWithKey:key value:value];
}

static id objectGetter(GlobalConfig *self, SEL _cmd)
{
    NSString *key = [self defaultsKeyForSelector:_cmd];
    id objValue = [self objectFromKey:key];
    
    if (objValue == nil)
    {
        return self.configDefaults[key];
    }
    else
    {
        return objValue;
    }
}

static void objectSetter(GlobalConfig *self, SEL _cmd, id object)
{
    NSString *key = [self defaultsKeyForSelector:_cmd];
    
    if (object != nil)
    {
        NSData *data = [NSKeyedArchiver archivedDataWithRootObject:object];
        [self configWithKey:key value:data];
    }
    else
    {
        [self configWithKey:key value:nil]; // nothing happened; just to log error info.
    }
}

#pragma - mark Singlton Method

+ (instancetype)sharedInstance
{
    static id globalConfig = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        globalConfig = [[self alloc] init];
    });
    
    return globalConfig;
}

#pragma - mark System methods

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        [self loadDefaults];
        
        _configDic = [NSMutableDictionary dictionary];
        
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        NSString *path = [documentsDirectory stringByAppendingPathComponent:@"config.db"];
        
        // 1.创建数据库文件config.db（若不存在）。
        self.db = [FMDatabase databaseWithPath:path];
        [self.db open];
        
        BOOL isExist = [self.db tableExists:@"config"];
        if (!isExist)
        {
            // 2.创建config表。(若不存在)
            NSString *createTableSQL = @"create table config (id integer primary key autoincrement);";
            [self.db executeUpdate:createTableSQL];
        }
        
        /// 注意：这里的db只有一条记录；也可以改造成多条记录；
        /// 每条记录代表一个config, 数据库的字段是固定的，包括key/value及其他有必要添加的信息等。(YapDB是这么干的)
        /// TODO: 可以对这两种方法做性能测试（BenchMark），择其性能优者用之。
        
        // 3.插入唯一的一条记录。(若不存在)
        NSString *sqlQuery = @"select *from config where id = ?";
        FMResultSet *rs = [self.db executeQuery:sqlQuery, @(1)];
        BOOL isRecordExist = NO;
        while ([rs next])
        {
            isRecordExist = YES;
        }
        [rs close];
        
        if (!isRecordExist)
        {
            NSString *sql = @"insert into config (id) values(?) ";
            [self.db executeUpdate:sql, @(1)];
        }
        
        // 4.升级数据库（若必要,存在需要新添加的列，使用transaction批量操作）
        //PS:SQLite的alter不支持添加多列,因此不能在一个sql语句中实现，需要批量操作
        // get configs
        NSMutableArray *configs = [GCFMDBHelper propertyConfigsFromClass:[GlobalConfig class]];
        for (GCConfigInfo *config in configs)
        {
            if (!([config.key isEqualToString:@"configDefaults"] || [config.key isEqualToString:@"dbQueue"]
                || [config.key isEqualToString:@"db"] || [config.key isEqualToString:@"configDic"]))
            {
                _configDic[config.key] = config;
            }
        }
        
        // 用来增加差异的db列
        NSMutableArray *configsToAdd = [[_configDic allValues] mutableCopy];
        FMResultSet *schema = [self.db getTableSchema:@"config"];
        while ([schema next])
        {
            NSString *columnName = [schema stringForColumn:@"name"];
            GCConfigInfo *config = _configDic[columnName];
            if (config != nil)
            {
                [configsToAdd removeObject:config];
            }
        }
        [schema close];
        
        [self.db beginTransaction];
        for (GCConfigInfo *config in configsToAdd)
        {
            id defaultObjValue = _configDefaults[config.key];
            NSString *sql;
            if (defaultObjValue != nil && (![config.type isEqualToString:@"BLOB"]))
            {
                sql = [NSString stringWithFormat:@"ALTER TABLE %@ ADD COLUMN %@ %@ DEFAULT %@", @"config", config.key, config.type, defaultObjValue];
            }
            else
            {
                sql = [NSString stringWithFormat:@"ALTER TABLE %@ ADD COLUMN %@ %@", @"config", config.key, config.type];
            }
            [self.db executeUpdate:sql];
        }
        [self.db commit];
        [self.db close];
        
        // 5. prepare queue & accessors
        _dbQueue = [FMDatabaseQueue databaseQueueWithPath:path];
        [self generateAccessorMethods];
    }
    
    return self;
}

#pragma - mark outer Methods
//delete the record, then create a new one.
- (void)clearAllConfigs
{
    [self.dbQueue inDatabase:^(FMDatabase * _Nonnull db) {
        
        NSString *sqlDel = @"delete from config";
        [db executeUpdate:sqlDel];
        
        NSString *sql = @"insert into config (id) values(?) ";
        [db executeUpdate:sql, @(1)];
    }];
}

#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wundeclared-selector"
#pragma GCC diagnostic ignored "-Warc-performSelector-leaks"   // 屏蔽下面代码引起的告警

#pragma - mark Inner Methods

// 赋值初始化功能
- (void)loadDefaults
{
    SEL setupDefaultSEL = NSSelectorFromString(@"setupDefaults");
    
    if ([self respondsToSelector:setupDefaultSEL])
    {
        self.configDefaults = [self performSelector:setupDefaultSEL];
    }
}

- (NSString *)defaultsKeyForSelector:(SEL)selector
{
    return [_mapping objectForKey:NSStringFromSelector(selector)];
}

#pragma -- mark generate runtime property methods

- (void)generateAccessorMethods
{
    unsigned int count = 0;
    objc_property_t *properties = class_copyPropertyList([self class], &count);
    
    _mapping = [NSMutableDictionary dictionary];
    
    for (int i = 0; i < count; ++i)
    {
        objc_property_t property = properties[i];
        const char *name = property_getName(property);
        const char *attributes = property_getAttributes(property);
        
        char *getter = strdup(name);
        SEL getterSel = sel_registerName(getter);
        free(getter);
        
        char *setter;
        asprintf(&setter, "set%c%s:", toupper(name[0]), name + 1);
        SEL setterSel = sel_registerName(setter);
        free(setter);
        
        NSString *key = [NSString stringWithFormat:@"%s", name];
        [_mapping setValue:key forKey:NSStringFromSelector(getterSel)];
        [_mapping setValue:key forKey:NSStringFromSelector(setterSel)];
        
        IMP getterImp = (IMP)objectGetter;
        IMP setterImp = (IMP)objectSetter;
        
        char type = attributes[1];
        NSString *totalStr = [NSString stringWithUTF8String:attributes];
        if ([totalStr containsString:@"NSString"])
        {
            type = String;
        }
        
        // 注意：这里使用longlong统一处理整型相关的问题，不考虑溢出（简单化处理）。
        switch (type) {
            case Int:
            case Short:
            case Long:
            case LongLong:
            case UnsignedInt:
            case UnsignedLong:
            case UnsignedLongLong:
                getterImp = (IMP)longLongGetter;
                setterImp = (IMP)longLongSetter;
                break;
            case Bool:
                getterImp = (IMP)boolGetter;
                setterImp = (IMP)boolSetter;
                break;
            case Double:
                getterImp = (IMP)doubleGetter;
                setterImp = (IMP)doubleSetter;
                break;
            case String:
                getterImp = (IMP)stringGetter;
                setterImp = (IMP)stringSetter;
                break;
            case Object:
                getterImp = (IMP)objectGetter;
                setterImp = (IMP)objectSetter;
                break;
        }
        
        char types[5];
        
        snprintf(types, 4, "@@:");
        class_addMethod([self class], getterSel, getterImp, types);
        
        snprintf(types, 5, "v@:@");
        class_addMethod([self class], setterSel, setterImp, types);
    }
    
    free(properties);
}

#pragma mark - actions for different types of keys

- (void)configWithKey:(NSString *)key value:(id)value
{
    if ([key length] == 0 || value == nil)
    {
        NSLog(@"configWithKey: input invalid");
        // input invalid.
        return;
    }
    
    // 测试结果表明：update某个config的值不会影响其他的。 注意：这里的问号只能用来表达值，而不能是key。
    NSString *sql = [NSString stringWithFormat:@"UPDATE config SET %@ = ? where id = ?", key];
    
    __block BOOL result;
    [self.dbQueue inDatabase:^(FMDatabase * _Nonnull db) {
        result = [db executeUpdate:sql, value, @(1)];
    }];
    
    if (!result)
    {
        NSLog(@"configWithKey,error happens! key:%@,value:%@", key, value);
    }
}

- (BOOL)boolFromKey:(NSString *)key
{
    // 获取保存配置的该条记录。先读取default,然后再覆盖。
    __block BOOL boolValue = NO;
    if (_configDefaults[key])
    {
        boolValue = [_configDefaults[key] boolValue];
    }
    
    [self.dbQueue inDatabase:^(FMDatabase * _Nonnull db) {
        FMResultSet *result = [db executeQuery:@"select * from config where id = 1"];
        while ([result next])
        {
            boolValue = [result boolForColumn:key];
        }
        [result close];
    }];
    
    return boolValue;
}

- (double)doubleFromKey:(NSString *)key
{
    // 获取保存配置的该条记录。
    __block double doubleValue = 0.0;
    [self.dbQueue inDatabase:^(FMDatabase * _Nonnull db) {
        FMResultSet *result = [db executeQuery:@"select * from config where id = 1"];
        while ([result next])
        {
            doubleValue = [result doubleForColumn:key];
        }
        [result close];
    }];
    
    return doubleValue;
}

- (NSString *)stringFromKey:(NSString *)key
{
    // 获取保存配置的该条记录。
    __block NSString * strValue = @"";
    [self.dbQueue inDatabase:^(FMDatabase * _Nonnull db) {
        FMResultSet *result = [db executeQuery:@"select * from config where id = 1"];
        while ([result next])
        {
            strValue = [result stringForColumn:key];
        }
        [result close];
    }];
    
    return strValue;
}

- (long long int)longlongFromKey:(NSString *)key
{
    // 获取保存配置的该条记录。
    __block long long int llValue = 0;
    [self.dbQueue inDatabase:^(FMDatabase * _Nonnull db) {
        FMResultSet *result = [db executeQuery:@"select * from config where id = 1"];
        while ([result next])
        {
            llValue = [result longLongIntForColumn:key];
        }
        [result close];
    }];
    
    return llValue;
}

- (id)objectFromKey:(NSString *)key
{
    // 获取保存配置的该条记录。
    __block NSData *objData = nil;
    [self.dbQueue inDatabase:^(FMDatabase * _Nonnull db) {
        FMResultSet *result = [db executeQuery:@"select * from config where id = 1"];
        while ([result next])
        {
            objData = [result dataForColumn:key];
        }
        [result close];
    }];
    
    return [NSKeyedUnarchiver unarchiveObjectWithData:objData];
}

@end


@implementation GCConfigInfo

- (instancetype)initWithProperty:(objc_property_t)property
{
    if ((self = [super init]))
    {
        if (!property) return nil;
        
        const char *name = property_getName(property);
        if (name)
        {
            self.key = [NSString stringWithUTF8String:name];
        }
        
        const char *attributes = property_getAttributes(property);
        NSString *totalStr = [NSString stringWithUTF8String:attributes];
        if ([totalStr containsString:@"NSString"])
        {
            self.type = @"TEXT";
            return self;
        }
        
        char type = attributes[1];
        // 注意：这里使用longlong统一处理整型相关的问题，不考虑溢出（简单化处理）。
        switch (type)
        {
            case Int:
            case Short:
            case Long:
            case LongLong:
            case UnsignedInt:
            case UnsignedLong:
            case UnsignedLongLong:
                self.type = @"INTEGER";
                break;
            case Bool:
                self.type = @"INTEGER";
                break;
            case Double:
                self.type = @"REAL";
                break;
            case Object:
                self.type = @"BLOB";
                break;
        }
    }
    
    return self;
}

@end
