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

+ (NSArray *)filter:(NSDictionary *)props options:(NSDictionary *)options{
    return [[self mainContext] filterObjects:NSStringFromClass(self) props:props];
}

+ (id)get:(NSDictionary *)props options:(NSDictionary *)options{
    return [[self mainContext] getObject:NSStringFromClass(self) props:props];
}

+ (id)create:(NSDictionary *)props options:(NSDictionary *)options{
    return [[self mainContext] createObject:NSStringFromClass(self) props:props];
}

+ (id)get_or_create:(NSDictionary *)props options:(NSDictionary *)options{
    return [self get_or_create:props update:nil options:options];
}

+ (id)get_or_create:(NSDictionary *)props update:(NSDictionary *)update options:(NSDictionary *)options{
    NSManagedObjectContextGetOrCreateDictionary *dic = [[self mainContext] getOrCreateObject:NSStringFromClass(self) props:props update:update];
    NSManagedObject *obj = dic.object;
    return obj;
}

+ (NSArray *)bulk_create:(NSArray *)json options:(NSDictionary *)options{
    return [[self mainContext] bulkCreateObjects:NSStringFromClass(self) props:json];
}

+ (NSArray *)bulk_get_or_create:(NSArray *)json eqKeys:(NSArray *)eqKeys upKeys:(NSArray *)upKeys options:(NSDictionary *)options{
    return [[self mainContext] bulkGetOrCreateObjects:NSStringFromClass(self) allProps:json eqKeys:eqKeys upKeys:upKeys];
}

+ (id)objectWithID:(NSManagedObjectID *)objectID{
    return [[self mainContext] objectWithID:objectID];
}

+ (void)filter:(NSDictionary *)props options:(NSDictionary *)options complete:(void(^)(NSArray *mos))complete{
    [[self mainContext] performBlockOutOfOwnThread:^(NSManagedObjectContext *context) {
        NSArray *mos = [context filterObjects:NSStringFromClass(self) props:props];
        if(complete)
            dispatch_async(dispatch_get_main_queue(), ^{
                complete(mos);
            });
    } afterSaveOnMainThread:nil];
}

+ (void)get:(NSDictionary *)props options:(NSDictionary *)options complete:(void(^)(id mo))complete{
    [[self mainContext] performBlockOutOfOwnThread:^(NSManagedObjectContext *context) {
        id mo = [context getObject:NSStringFromClass(self) props:props];
        if(complete)
        dispatch_async(dispatch_get_main_queue(), ^{
            complete(mo);
        });
    } afterSaveOnMainThread:nil];
}

+ (void)create:(NSDictionary *)props options:(NSDictionary *)options complete:(void(^)(id mo))complete{
    __block id mo = nil;
    [[self mainContext] performBlockOutOfOwnThread:^(NSManagedObjectContext *context) {
        mo = [context createObject:NSStringFromClass(self) props:props];
        [context save:nil];
    } afterSaveOnMainThread:^(NSNotification *note) {
        if(complete)
            complete(mo);
    }];
}

+ (void)get_or_create:(NSDictionary *)props options:(NSDictionary *)options complete:(void(^)(id mo))complete{
    [self get_or_create:props update:nil options:options complete:complete];
}

+ (void)get_or_create:(NSDictionary *)props update:(NSDictionary *)update options:(NSDictionary *)options complete:(void (^)(id))complete{
    __block id mo = nil;
    [[self mainContext] performBlockOutOfOwnThread:^(NSManagedObjectContext *context) {
        NSManagedObjectContextGetOrCreateDictionary *dic = [context getOrCreateObject:NSStringFromClass(self) props:props update:update];
        mo = dic.object;
        if(dic.is_created || (update && [update count] > 0) ){
            [context save:nil];
        }else{
            if(complete)
                dispatch_async(dispatch_get_main_queue(), ^{
                    complete(mo);
                });
        }
    } afterSaveOnMainThread:^(NSNotification *note) {
        if(complete)
            complete(mo);
    }];
}

+ (void)bulk_create:(NSArray *)json options:(NSDictionary *)options complete:(void (^)(NSArray * mos))complete{
    __block NSArray *mos = nil;
    [[self mainContext] performBlockOutOfOwnThread:^(NSManagedObjectContext *context) {
        mos = [context bulkCreateObjects:NSStringFromClass(self) props:json];
        [context save:nil];
    } afterSaveOnMainThread:^(NSNotification *note) {
        if(complete)
            complete(mos);
    }];
}

+ (void)bulk_get_or_create:(NSArray *)json eqKeys:(NSArray *)eqKeys upKeys:(NSArray *)upKeys options:(NSDictionary *)options complete:(void (^)(NSArray *))complete{
    __block NSArray *mos = nil;
    [[self mainContext] performBlockOutOfOwnThread:^(NSManagedObjectContext *context) {
        mos = [context bulkGetOrCreateObjects:NSStringFromClass(self) allProps:json eqKeys:eqKeys upKeys:upKeys];
        [context save:nil];
    } afterSaveOnMainThread:^(NSNotification *note) {
        if(complete)
            complete(mos);
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

+ (NSFetchedResultsController *)controllerWithEqualProps:(NSDictionary *)equalProps sorts:(NSArray *)sorts context:(NSManagedObjectContext *)context options:(NSDictionary *)options{
    NSFetchRequest *req = [self requestWithEqualProps:equalProps sorts:sorts options:options];
    NSFetchedResultsController *frc = [self controllerWithRequest:req context:context options:options];
    [frc performFetch:nil];
    return frc;
}

+ (NSFetchRequest *)requestWithEqualProps:(NSDictionary *)equalProps sorts:(NSArray *)sorts options:(NSDictionary *)options{
    NSPredicate *pred = nil;
    if(equalProps && [equalProps count] > 0)
        pred = [NSPredicate predicateForEqualProps:equalProps];
    return [self requestWithPredicate:pred sorts:sorts options:options];
}

+ (NSFetchedResultsController *)controllerWithProps:(NSArray *)props sorts:(NSArray *)sorts context:(NSManagedObjectContext *)context options:(NSDictionary *)options{
    NSFetchRequest *req = [self requestWithProps:props sorts:sorts options:options];
    return [self controllerWithRequest:req context:context options:options];
}


+ (NSFetchRequest *)requestWithProps:(NSArray *)props sorts:(NSArray *)sorts options:(NSDictionary *)options{
    NSPredicate *pred = nil;
    if(props && [props count] > 0)
        pred = [NSPredicate predicateForProps:props];
    return [self requestWithPredicate:pred sorts:sorts options:options];
}

+ (NSFetchedResultsController *)controllerWithPredicate:(NSPredicate *)predicate sorts:(NSArray *)sorts context:(NSManagedObjectContext *)context options:(NSDictionary *)options{
    NSFetchRequest *req = [self requestWithPredicate:predicate sorts:sorts options:options];
    return [self controllerWithRequest:req context:context options:options];
}

+ (NSFetchRequest *)requestWithPredicate:(NSPredicate *)predicate sorts:(NSArray *)sorts options:(NSDictionary *)options{
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

+ (NSFetchedResultsController *)controllerWithRequest:(NSFetchRequest *)request context:(NSManagedObjectContext *)context options:(NSDictionary *)options{
    if(!context)
        context = [self mainContext];
    NSFetchedResultsController *frc = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:context sectionNameKeyPath:options[@"sectionNameKeyPath"] cacheName:nil];
    return frc;
}

@end
