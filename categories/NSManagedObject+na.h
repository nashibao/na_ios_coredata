//
//  NSManagedObject+na.h
//  SK3
//
//  Created by nashibao on 2012/10/11.
//  Copyright (c) 2012年 s-cubism. All rights reserved.
//

#import <CoreData/CoreData.h>

@interface NSManagedObject (na)

+ (NSPersistentStoreCoordinator *)coordinator;
+ (NSManagedObjectContext *)mainContext;
+ (void)setMainContext:(NSManagedObjectContext *)context;

+ (NSArray *)filter:(NSDictionary *)props options:(NSDictionary *)options;
+ (id)get:(NSDictionary *)props options:(NSDictionary *)options;
+ (id)create:(NSDictionary *)props options:(NSDictionary *)options;
+ (id)get_or_create:(NSDictionary *)props options:(NSDictionary *)options;
+ (id)get_or_create:(NSDictionary *)props update:(NSDictionary *)update options:(NSDictionary *)options;
+ (NSArray *)bulk_create:(NSArray *)json options:(NSDictionary *)options;
+ (NSArray *)bulk_get_or_create:(NSArray *)json eqKeys:(NSArray *)eqKeys upKeys:(NSArray *)upKeys options:(NSDictionary *)options;
+ (id)objectWithID:(NSManagedObjectID *)objectID;

#warning !! completeハンドラで返す値はmain threadで扱えない．NSManagedObjectIDの列に修正すべき！
+ (void)filter:(NSDictionary *)props options:(NSDictionary *)options complete:(void(^)(NSArray *mos))complete;
+ (void)get:(NSDictionary *)props options:(NSDictionary *)options complete:(void(^)(id mo))complete;
+ (void)create:(NSDictionary *)props options:(NSDictionary *)options complete:(void(^)(id mo))complete;
+ (void)get_or_create:(NSDictionary *)props options:(NSDictionary *)options complete:(void(^)(id mo))complete;
+ (void)get_or_create:(NSDictionary *)props update:(NSDictionary *)update options:(NSDictionary *)options complete:(void(^)(id mo))complete;
+ (void)bulk_create:(NSArray *)json options:(NSDictionary *)options complete:(void(^)(NSArray * mos))complete;
+ (void)bulk_get_or_create:(NSArray *)json eqKeys:(NSArray *)eqKeys upKeys:(NSArray *)upKeys options:(NSDictionary *)options complete:(void(^)(NSArray * mos))complete;

+ (void)delete_all;

+ (NSError *)save;

#pragma mark frc用ショートカット

+ (NSFetchedResultsController *)controllerWithEqualProps:(NSDictionary *)equalProps sorts:(NSArray *)sorts context:(NSManagedObjectContext *)context options:(NSDictionary *)options;
+ (NSFetchRequest *)requestWithEqualProps:(NSDictionary *)equalProps sorts:(NSArray *)sorts options:(NSDictionary *)options;
+ (NSFetchedResultsController *)controllerWithProps:(NSArray *)props sorts:(NSArray *)sorts context:(NSManagedObjectContext *)context options:(NSDictionary *)options;
+ (NSFetchRequest *)requestWithProps:(NSArray *)props sorts:(NSArray *)sorts options:(NSDictionary *)options;
+ (NSFetchedResultsController *)controllerWithPredicate:(NSPredicate *)predicate sorts:(NSArray *)sorts context:(NSManagedObjectContext *)context options:(NSDictionary *)options;
+ (NSFetchRequest *)requestWithPredicate:(NSPredicate *)predicate sorts:(NSArray *)sorts options:(NSDictionary *)options;

@end
