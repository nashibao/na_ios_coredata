//
//  NSManagedObjectContextNaCategoryTest.m
//  na_ios_test
//
//  Created by nashibao on 2012/10/30.
//  Copyright (c) 2012年 nashibao. All rights reserved.
//

#import "NSManagedObjectContextNaCategoryTest.h"

#import "NAModelController.h"

#import "TestParent.h"

#import "TestChild.h"

#import "NSManagedObject+na.h"

@implementation NSManagedObjectContextNaCategoryTest

- (void)setUp
{
    [super setUp];
    
    //    modelcontroller作成
    self.modelController = [[NAModelController alloc] init];
    
    //    (test時だけbundle指定が必要)
    self.modelController.name = @"testmodel";
    self.modelController.bundle = [NSBundle bundleForClass:[TestParent class]];
    [self.modelController setup];
    
    //    modelへの設定
    [TestParent setMainContext:_modelController.mainContext];
    
    //    古いデータの削除
    [TestParent delete_all];
    
    [TestParent save];
}

- (void)tearDown
{
    [TestParent delete_all];
    
    [TestParent save];
    
    [super tearDown];
}

/** カテゴリ同期メソッドテスト
 */
- (void)atestSyncMethods
{
    
    //    mo作成
    TestParent *pa1 = [TestParent create:@{@"name": @"test"}];
    
    STAssertTrue([pa1 isKindOfClass:[TestParent class]], @"返り値はそれ自体");
    
    NSArray *mos = [TestParent filter:nil];
    
    STAssertTrue([mos count] == 1, @"filter test");
    
    STAssertEqualObjects([mos objectAtIndex:0], pa1, @"同じコンテクストだから同じはず？");
    
    TestParent *pa2 = [TestParent get:@{@"name": @"test"}];
    
    STAssertEqualObjects(pa1, pa2, @"get test");
    
    TestParent *pa3 = [TestParent get_or_create:@{@"name": @"test"}];
    
    STAssertEqualObjects(pa3, pa1, @"unique制約");
    
    TestParent *pa4 = [TestParent create:@{@"name": @"test2"}];
    
    STAssertFalse(pa1 == pa4, @"create test");
    
    mos = [TestParent filter:nil];
    
    STAssertTrue([mos count] == 2, @"filter test");
    
    mos = [TestParent filter:@{@"name": @"test"}];
    
    STAssertTrue([mos count] == 1, @"filter test");
    
    [TestParent delete_all];
    
    mos = [TestParent filter:nil];
    
    STAssertTrue([mos count] == 0, @"delete test");
}

/** カテゴリ非同期メソッドテスト
 */
- (void)testAsyncMethods
{
    STAsynchronousTestStart(asynccreate);
    
    [TestParent create:@{@"name": @"test"} complete:^(id mo) {
        TestParent *pa = (TestParent *)mo;
        STAssertTrue([pa isKindOfClass:[TestParent class]], @"async create");
        NSLog(@"%s|%@", __PRETTY_FUNCTION__, [pa name]);
        STAssertTrue([@"test" isEqualToString:[pa name]], nil);
        STAsynchronousTestDone(asynccreate);
    }];
    
    STAsynchronousTestWait(asynccreate, 0.5);
    
    [TestParent create:@{@"name": @"test2"}];
    
    //    saveをしないとcontextがマージされない！！
    [TestParent save];
    
    STAsynchronousTestStart(asyncget);
    
    [TestParent get:@{@"name": @"test"} complete:^(id mo) {
        TestParent *pa = (TestParent *)mo;
        STAssertTrue([@"test" isEqualToString:[pa name]], nil);
        STAsynchronousTestDone(asyncget);
    }];
    
    STAsynchronousTestWait(asyncget, 0.5);
    
    NSArray *mos = [TestParent filter:nil];
    STAssertTrue([mos count] == 2, nil);
    
    STAsynchronousTestStart(asyncfilter);
    
    [TestParent filter:nil complete:^(NSArray *mos) {
        NSLog(@"%s|%d", __PRETTY_FUNCTION__, [mos count]);
        STAssertTrue([mos count] == 2, nil);
        STAsynchronousTestDone(asyncfilter);
    }];
    
    STAsynchronousTestWait(asyncfilter, 0.5);
    
    STAsynchronousTestStart(asyncgetcreate);
    
    [TestParent get_or_create:@{@"name": @"test"} complete:^(id mo) {
        TestParent *pa1 = (TestParent *)mo;
        NSManagedObjectContext *context = pa1.managedObjectContext;
        STAssertTrue(context.concurrencyType == NSMainQueueConcurrencyType, @"ちゃんとmain threadのmo??");
        NSArray *mos = [TestParent filter:nil];
        STAssertTrue([mos count] == 2, nil);
        
        TestParent *pa = [TestParent get:@{@"name": @"test"}];
        TestParent *pa2 = (TestParent *)[[TestParent mainContext] objectWithID:pa1.objectID];
        STAssertTrue(pa == pa2, nil);
        STAsynchronousTestDone(asyncgetcreate);
    }];
    
    STAsynchronousTestWait(asyncgetcreate, 0.5);
    
    STAsynchronousTestStart(asynccreate2);
    
    [TestParent get_or_create:@{@"name": @"test2"} complete:^(id mo) {
        NSArray *mos = [TestParent filter:nil];
        STAssertTrue([mos count] == 2, nil);
        STAsynchronousTestDone(asynccreate2);
    }];
    
    STAsynchronousTestWait(asynccreate2, 0.5);
}

/** getOrCreateのasync
 */
- (void)testGetOrCreateAsyncUpdate
{
    STAsynchronousTestStart(getorcreateasyncupdate);
    
    [TestParent get_or_create:@{@"name": @"test3", @"hoge": @"hoge1", @"subdoc": @{@"fuga": @"fuga1"}} eqKeys:@[@"name"] complete:^(TestParent * mo) {
        //        create
        STAssertTrue([mo.name isEqualToString:@"test3"], nil);
        //        update
        STAssertTrue([mo.hoge isEqualToString:@"hoge1"], nil);
        //        スキーマレス
        STAssertTrue([mo.data[@"hoge"] isEqualToString:@"hoge1"], nil);
        //        dot syntax
        STAssertTrue([mo.subdoc__fuga isEqualToString:@"fuga1"], nil);
        STAsynchronousTestDone(getorcreateasyncupdate);
    }];
    
    STAsynchronousTestWait(getorcreateasyncupdate, 0.5);
}

/** bulk
 */
- (void)testBulk
{
    
    NSArray *mos = [TestParent filter:nil];
    int start = [mos count];
    
    //    bulk_create
    NSArray *json = @[@{@"name": @"test10"}, @{@"name": @"test11"}];
    
    NSArray *objs = [TestParent bulk_create:json];
    STAssertTrue([objs count] == 2, @"2個");
    
    TestParent *pa1 = objs[0];
    
    STAssertTrue([pa1.name isEqualToString:@"test10"], @"名前");
    TestParent *pa2 = objs[1];
    
    STAssertTrue([pa2.name isEqualToString:@"test11"], @"名前");
    
    json = @[@{@"name": @"test10", @"hoge": @"hoge1"}, @{@"name": @"test12"}];
    
    //    bulk_get_or_create
    objs = [TestParent bulk_get_or_create:json eqKeys:@[@"name"]];
    pa1 = objs[0];
    
    STAssertTrue([pa1.hoge isEqualToString:@"hoge1"], @"update");
    pa2 = objs[1];
    
    STAssertTrue([pa2.name isEqualToString:@"test12"], @"名前");
    
    mos = [TestParent filter:nil];
    int end = [mos count];
    STAssertTrue(end-start==3, @"3つしか加わらないはず");
    
}

/** bulk async
 */
- (void)testBulkAsync
{
    NSArray *mos = [TestParent filter:nil];
    int start = [mos count];
    
    //    bulk_create
    STAsynchronousTestStart(getorcreateasyncupdate);
    
    NSArray *json = @[@{@"name": @"test13"}, @{@"name": @"test14"}];
    
    [TestParent bulk_create:json complete:^(NSArray *moids) {
        TestParent *pa1 = [TestParent objectWithID:moids[0]];
        
        STAssertTrue([pa1.name isEqualToString:@"test13"], @"名前");
        TestParent *pa2 = [TestParent objectWithID:moids[1]];
        
        STAssertTrue([pa2.name isEqualToString:@"test14"], @"名前");
        STAsynchronousTestDone(getorcreateasyncupdate);
    }];
    
    STAsynchronousTestWait(getorcreateasyncupdate, 0.5);
    
    //    bulk_get_or_create
    STAsynchronousTestStart(getorcreateasyncupdate2);
    
    json = @[@{@"name": @"test13", @"hoge": @"hoge3", @"subdoc": @{@"fuga": @"fuga3"}}, @{@"name": @"test15"}];
    
    [TestParent bulk_get_or_create:json eqKeys:@[@"name"] complete:^(NSArray *moids) {
        TestParent *mo = [TestParent objectWithID:moids[0]];
        NSManagedObjectContext *context = mo.managedObjectContext;
        STAssertTrue(context.concurrencyType == NSMainQueueConcurrencyType, @"ちゃんとmain threadのmo??");
        //        create
        STAssertTrue([mo.name isEqualToString:@"test13"], nil);
        //        update
        STAssertTrue([mo.hoge isEqualToString:@"hoge3"], nil);
        //        スキーマレス
        STAssertTrue([mo.data[@"hoge"] isEqualToString:@"hoge3"], nil);
        //        dot syntax
        STAssertTrue([mo.subdoc__fuga isEqualToString:@"fuga3"], nil);
        STAsynchronousTestDone(getorcreateasyncupdate2);
    }];
    
    STAsynchronousTestWait(getorcreateasyncupdate2, 0.5);
    
    mos = [TestParent filter:nil];
    int end = [mos count];
    
    STAssertTrue(end-start==3, @"3つしか加わらないはず");
}

@end
