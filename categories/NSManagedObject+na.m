//
//  NSManagedObject+na.m
//  SK3
//
//  Created by nashibao on 2012/10/11.
//  Copyright (c) 2012年 s-cubism. All rights reserved.
//

#import "NSManagedObject+na.h"

#import "NSManagedObjectContext+na.h"

#import "NSPredicate+na.h"

#import <objc/runtime.h>

#import "NAModelController.h"

//#import "NSManagedObject+json.h"

@implementation NSManagedObject (na)

+ (NSPersistentStoreCoordinator *)coordinator{
    if ([self mainContext])
        return [[self mainContext] persistentStoreCoordinator];
    return nil;
}

static NSManagedObjectContext * __main_context__ = nil;

+ (NSManagedObjectContext *)mainContext{
    if(__main_context__)
        return __main_context__;
    NAModelController *controller = [NAModelController getControllerByClass:self];
    if(controller)
        return controller.mainContext;
    return nil;
}

+ (void)setMainContext:(NSManagedObjectContext *)context{
    __main_context__ = context;
}

+ (NSManagedObjectContext *)createPrivateContext{
    NSManagedObjectContext *context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    [context setPersistentStoreCoordinator:[self coordinator]];
    return context;
}

+ (NSArray *)filter:(NSDictionary *)props{
    return [[self mainContext] filterObjects:NSStringFromClass(self) props:props];
}

+ (id)get:(NSDictionary *)props{
    return [[self mainContext] getObject:NSStringFromClass(self) props:props];
}

+ (id)create:(NSDictionary *)props{
    return [[self mainContext] createObject:NSStringFromClass(self) props:props];
}

+ (id)get_or_create:(NSDictionary *)props{
    return [self _get_or_create:props eqKeys:nil isUpdate:NO];
}

+ (id)get_or_create:(NSDictionary *)json eqKeys:(NSArray *)eqKeys{
    return [self _get_or_create:json eqKeys:eqKeys isUpdate:YES];
}

+ (id)_get_or_create:(NSDictionary *)json eqKeys:(NSArray *)eqKeys isUpdate:(BOOL)isUpdate{
    NSManagedObjectContextGetOrCreateDictionary *dic = [[self mainContext] getOrCreateObject:NSStringFromClass(self) allProps:json eqKeys:eqKeys isUpdate:isUpdate];
    NSManagedObject *obj = dic.object;
    return obj;
}

+ (NSArray *)bulk_create:(NSArray *)json{
    return [[self mainContext] bulkCreateObjects:NSStringFromClass(self) props:json];
}

+ (NSArray *)bulk_get_or_create:(NSArray *)json eqKeys:(NSArray *)eqKeys{
    return [[self mainContext] bulkGetOrCreateObjects:NSStringFromClass(self) allProps:json eqKeys:eqKeys isUpdate:YES];
}

+ (id)objectWithID:(NSManagedObjectID *)objectID{
    return [[self mainContext] objectWithID:objectID];
}

#pragma mark 非同期API
#warning 現状NSManagedObject自体を別スレッドに投げて、別スレッドではobjectIDにアクセスして、mainContextから新しく引っ張ってきている．
// これは多分本当はダメ？？NSNotificationから引っ張ってくるとNSSetになって順番が失われてしまう．．
// https://developer.apple.com/library/ios/#documentation/Cocoa/Reference/CoreDataFramework/Classes/NSManagedObjectContext_Class/NSManagedObjectContext.html

//Posted whenever a managed object context completes a save operation.
//The notification object is the managed object context. The userInfo dictionary contains the following keys: NSInsertedObjectsKey, NSUpdatedObjectsKey, and NSDeletedObjectsKey.
//
//You can only use the managed objects in this notification on the same thread on which it was posted.
//
//You can pass the notification object to mergeChangesFromContextDidSaveNotification: on another thread, however you must not use the managed object in the user info dictionary directly on another thread. For more details, see “Concurrency with Core Data”.
//この感じだと、userInfo dictionaryに入っているのは別contextのmoで、そこからobjectIDを取り出せ、と

+ (void)filter:(NSDictionary *)props complete:(void(^)(NSArray *moids))complete{
    [[self mainContext] performBlockOutOfOwnThread:^(NSManagedObjectContext *context) {
        NSArray *mos = [context filterObjects:NSStringFromClass(self) props:props];
        NSArray *moids = [mos map:^id(NSManagedObject * mo) {
            return mo.objectID;
        }];
        if(complete)
            dispatch_async(dispatch_get_main_queue(), ^{
                complete(moids);
            });
    } afterSave:nil];
}

+ (void)get:(NSDictionary *)props complete:(void(^)(id mo))complete{
    [[self mainContext] performBlockOutOfOwnThread:^(NSManagedObjectContext *context) {
        NSManagedObject * mo = [context getObject:NSStringFromClass(self) props:props];
        NSManagedObjectID *moid = mo.objectID;
        if(complete)
            dispatch_async(dispatch_get_main_queue(), ^{
                id mainmo = [[self mainContext] objectWithID:moid];
                complete(mainmo);
            });
    } afterSave:nil];
}

+ (void)create:(NSDictionary *)props complete:(void(^)(id mo))complete{
    __block NSManagedObject *mo = nil;
    [[self mainContext] performBlockOutOfOwnThread:^(NSManagedObjectContext *context) {
        mo = [context createObject:NSStringFromClass(self) props:props];
        [context save:nil];
    } afterSave:^(NSNotification *note) {
        if(complete){
            NSManagedObjectID *moid = mo.objectID;
            dispatch_async(dispatch_get_main_queue(), ^{
                id mainmo = [[self mainContext] objectWithID:moid];
                complete(mainmo);
            });
        }
    }];
}

+ (void)get_or_create:(NSDictionary *)props complete:(void(^)(id mo))complete{
    [self _get_or_create:props eqKeys:nil isUpdate:NO complete:complete];
}
+ (void)get_or_create:(NSDictionary *)json eqKeys:(NSArray *)eqKeys complete:(void (^)(id))complete{
    [self _get_or_create:json eqKeys:eqKeys isUpdate:YES complete:complete];
}

+ (void)_get_or_create:(NSDictionary *)json eqKeys:(NSArray *)eqKeys isUpdate:(BOOL)isUpdate complete:(void (^)(id))complete{
    __block NSManagedObject *mo = nil;
    [[self mainContext] performBlockOutOfOwnThread:^(NSManagedObjectContext *context) {
        NSManagedObjectContextGetOrCreateDictionary *dic = [context getOrCreateObject:NSStringFromClass(self) allProps:json eqKeys:eqKeys isUpdate:isUpdate];
        mo = dic.object;
//        if(dic.is_created || isUpdate ){
            [context save:nil];
//        }else{
//            if(complete)
//                dispatch_async(dispatch_get_main_queue(), ^{
//                    id mainmo = [[self mainContext] objectWithID:mo.objectID];
//                    complete(mainmo);
//                });
//        }
    } afterSave:^(NSNotification *note) {
        if(complete){
            NSManagedObjectID *moid = mo.objectID;
            dispatch_async(dispatch_get_main_queue(), ^{
                id mainmo = [[self mainContext] objectWithID:moid];
                complete(mainmo);
            });
        }
    }];
}

+ (void)bulk_create:(NSArray *)json complete:(void (^)(NSArray * mos))complete{
    __block NSArray *mos = nil;
    [[self mainContext] performBlockOutOfOwnThread:^(NSManagedObjectContext *context) {
        mos = [context bulkCreateObjects:NSStringFromClass(self) props:json];
        [context save:nil];
    } afterSave:^(NSNotification *note) {
        if(complete){
            NSArray *moids = [mos map:^id(NSManagedObject *mo) {
                return mo.objectID;
            }];
            dispatch_async(dispatch_get_main_queue(), ^{
                complete(moids);
            });
        }
    }];
}
+ (void)bulk_get_or_create:(NSArray *)json eqKeys:(NSArray *)eqKeys complete:(void (^)(NSArray *))complete{
    [self _bulk_get_or_create:json eqKeys:eqKeys isUpdate:YES complete:complete];
}

+ (void)_bulk_get_or_create:(NSArray *)json eqKeys:(NSArray *)eqKeys isUpdate:(BOOL)isUpdate complete:(void (^)(NSArray *))complete{
    __block NSArray *mos = nil;
    [[self mainContext] performBlockOutOfOwnThread:^(NSManagedObjectContext *context) {
        mos = [context bulkGetOrCreateObjects:NSStringFromClass(self) allProps:json eqKeys:eqKeys isUpdate:isUpdate];
        [context save:nil];
    } afterSave:^(NSNotification *note) {
        if(complete){
            NSArray *moids = [mos map:^id(NSManagedObject *mo) {
                return mo.objectID;
            }];
            dispatch_async(dispatch_get_main_queue(), ^{
                complete(moids);
            });
        }
    }];
}

+ (void)delete_all{
    [[self mainContext] deleteAllObjects:NSStringFromClass(self)];
}

+ (NSError *)save{
    NSError *err = nil;
    [[self mainContext] save:&err];
    return err;
}

+ (NSFetchedResultsController *)controllerWithEqualProps:(NSDictionary *)equalProps sorts:(NSArray *)sorts section:(NSString *)section context:(NSManagedObjectContext *)context{
    NSFetchRequest *req = [self requestWithEqualProps:equalProps sorts:sorts section:section];
    NSFetchedResultsController *frc = [self controllerWithRequest:req context:context section:section];
    [frc performFetch:nil];
    return frc;
}

+ (NSFetchRequest *)requestWithEqualProps:(NSDictionary *)equalProps sorts:(NSArray *)sorts section:(NSString *)section{
    NSPredicate *pred = nil;
    if(equalProps && [equalProps count] > 0)
        pred = [NSPredicate predicateForEqualProps:equalProps];
    return [self requestWithPredicate:pred sorts:sorts];
}

+ (NSFetchedResultsController *)controllerWithProps:(NSArray *)props sorts:(NSArray *)sorts section:(NSString *)section context:(NSManagedObjectContext *)context{
    NSFetchRequest *req = [self requestWithProps:props sorts:sorts section:section];
    return [self controllerWithRequest:req context:context section:section];
}


+ (NSFetchRequest *)requestWithProps:(NSArray *)props sorts:(NSArray *)sorts section:(NSString *)section{
    NSPredicate *pred = nil;
    if(props && [props count] > 0)
        pred = [NSPredicate predicateForProps:props];
    return [self requestWithPredicate:pred sorts:sorts];
}

+ (NSFetchedResultsController *)controllerWithPredicate:(NSPredicate *)predicate sorts:(NSArray *)sorts section:(NSString *)section context:(NSManagedObjectContext *)context{
    NSFetchRequest *req = [self requestWithPredicate:predicate sorts:sorts];
    return [self controllerWithRequest:req context:context section:section];
}

+ (NSFetchRequest *)requestWithPredicate:(NSPredicate *)predicate sorts:(NSArray *)sorts{
    NSString *class_name = [NSString stringWithCString:class_getName(self) encoding:NSUTF8StringEncoding];
    NSFetchRequest *req = [NSFetchRequest fetchRequestWithEntityName:class_name];
    NSMutableArray *_sorts = [@[] mutableCopy];
    for(NSString *sort in sorts){
        BOOL asc = YES;
        NSRange range = [sort rangeOfString:@"-"];
        NSString *temp = sort;
        if(range.location==0 && range.length>0){
            temp = [sort stringByReplacingOccurrencesOfString:@"-" withString:@""];
            asc = NO;
        }
        NSSortDescriptor *sd = [[NSSortDescriptor alloc] initWithKey:temp ascending:asc];
        [_sorts addObject:sd];
    }
    [req setSortDescriptors:_sorts];
    [req setSortDescriptors:_sorts];
    if(predicate)
        [req setPredicate:predicate];
    return req;
}

+ (NSFetchedResultsController *)controllerWithRequest:(NSFetchRequest *)request context:(NSManagedObjectContext *)context section:(NSString *)section{
    if(!context)
        context = [self mainContext];
    NSFetchedResultsController *frc = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:context sectionNameKeyPath:section cacheName:nil];
    return frc;
}

@end
