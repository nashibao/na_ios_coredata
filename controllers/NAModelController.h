//
//  NAModelController.h
//  SK3
//
//  Created by nashibao on 2012/09/28.
//  Copyright (c) 2012年 s-cubism. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "NSPredicate+na.h"

#import "NSManagedObjectContext+na.h"

#import "NSFetchRequest+na.h"

extern NSString * const NAModelControllerDestroyedNotification;
extern NSString * const NAModelControllerInitializedNotification;

/*
 model controller class.
 which includes "model", "coordinator", "mainContext".
 setup function made them all.
 
 "mainContext" is a context in the main thread. then don't use it for 
 heavy tasks! you can create new context in background thread.
 */
@interface NAModelController : NSObject

@property (strong, nonatomic) NSManagedObjectModel *model;
@property (strong, nonatomic) NSPersistentStoreCoordinator *coordinator;
@property (strong, nonatomic) NSManagedObjectContext *mainContext;

@property (strong, nonatomic) NSString *name;
@property (strong, nonatomic) NSBundle *bundle;

@property (strong, nonatomic) NSMutableSet *managedObjectClasses;

/** setup
 */
- (void)setup;

/** 初期化処理．すでにあるデータベースは削除する
 */
- (void)destroyAndSetup;
+ (void)destroy;

/*
 migrations
 */
//- (void)migrate:(NSString *)newpath newversion:(NSInteger)newversion;

// わざわざ継承しなくても済むようにしたい
+ (NAModelController *)controllerByName:(NSString *)name bundle:(NSBundle *)bundle;
+ (NAModelController *)getControllerByClass:(Class)kls;

- (void)addManagedObjectClasses:(NSArray *)objects;

@end
