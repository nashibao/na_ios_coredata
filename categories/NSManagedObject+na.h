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

+ (NSArray *)filter:(NSDictionary *)props;
+ (id)get:(NSDictionary *)props;
+ (id)create:(NSDictionary *)props;
+ (id)get_or_create:(NSDictionary *)props;
+ (id)get_or_create:(NSDictionary *)json eqKeys:(NSArray *)eqKeys;
+ (NSArray *)bulk_create:(NSArray *)json;
+ (NSArray *)bulk_get_or_create:(NSArray *)json eqKeys:(NSArray *)eqKeys;
+ (id)objectWithID:(NSManagedObjectID *)objectID;


#pragma mark 非同期API
+ (void)filter:(NSDictionary *)props complete:(void(^)(NSArray *moids))complete;
+ (void)get:(NSDictionary *)props complete:(void(^)(id mo))complete;
+ (void)create:(NSDictionary *)props complete:(void(^)(id mo))complete;
+ (void)get_or_create:(NSDictionary *)props complete:(void(^)(id mo))complete;
+ (void)get_or_create:(NSDictionary *)json eqKeys:(NSArray *)eqKeys complete:(void(^)(id mo))complete;
+ (void)bulk_create:(NSArray *)json complete:(void(^)(NSArray * moids))complete;
+ (void)bulk_get_or_create:(NSArray *)json eqKeys:(NSArray *)eqKeys complete:(void(^)(NSArray * moids))complete;

+ (void)delete_all;

+ (NSError *)save;

#pragma mark frc用ショートカット

+ (NSFetchedResultsController *)controllerWithEqualProps:(NSDictionary *)equalProps sorts:(NSArray *)sorts section:(NSString *)section context:(NSManagedObjectContext *)context;
+ (NSFetchRequest *)requestWithEqualProps:(NSDictionary *)equalProps sorts:(NSArray *)sorts section:(NSString *)section;
+ (NSFetchedResultsController *)controllerWithProps:(NSArray *)props sorts:(NSArray *)sorts section:(NSString *)section context:(NSManagedObjectContext *)context;
+ (NSFetchRequest *)requestWithProps:(NSArray *)props sorts:(NSArray *)sorts section:(NSString *)section;
+ (NSFetchedResultsController *)controllerWithPredicate:(NSPredicate *)predicate sorts:(NSArray *)sorts section:(NSString *)section context:(NSManagedObjectContext *)context;
+ (NSFetchRequest *)requestWithPredicate:(NSPredicate *)predicate sorts:(NSArray *)sorts;

@end
