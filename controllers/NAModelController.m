//
//  NAModelController.m
//  SK3
//
//  Created by nashibao on 2012/09/28.
//  Copyright (c) 2012年 s-cubism. All rights reserved.
//

#import "NAModelController.h"

NSString * const NAModelControllerDestroyedNotification = @"NAModelControllerDestroyedNotification";
NSString * const NAModelControllerInitializedNotification = @"NAModelControllerInitializedNotification";

@implementation NAModelController

- (id)init{
    self = [super init];
    if(self){
        self.managedObjectClasses = [[NSMutableSet alloc] init];
        self.bundle = [NSBundle mainBundle];
        if([self name]){
            [self setup];
        }
    }
    return self;
}

- (id)initWithoutSetup{
    self = [super init];
    if(self){
        self.bundle = [NSBundle mainBundle];
    }
    return self;
}


- (NSString *)directoryPath{
    return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
}

- (NSString *)storeFileName{
    NSString *directory_path = [self directoryPath];
    NSString *location = [NSString stringWithFormat:@"%@.sqlite", [self name]];
    NSString *store_path = [directory_path stringByAppendingPathComponent:location];
    return store_path;
}

- (void)setup{
    
    NSString *model_path = [[self bundle] pathForResource:[self name] ofType:@"momd"];
    
    NSURL *model_url = [NSURL fileURLWithPath:model_path];
    
    self.model = [[NSManagedObjectModel alloc] initWithContentsOfURL:model_url];
    NSString *store_file_name = [self storeFileName];
    
    if(![[NSFileManager defaultManager] fileExistsAtPath:store_file_name]){
        NSString *bundleStorePath = [[NSBundle mainBundle] pathForResource:[self name] ofType:@"sqlite"];
        if(bundleStorePath){
            [[NSFileManager defaultManager] copyItemAtPath:bundleStorePath toPath:store_file_name error:NULL];
        }
    }
    
    NSURL *storeURL = [NSURL fileURLWithPath:store_file_name];
    NSError *error = nil;
    self.coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:self.model];
    if (![self.coordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
        //gNSLog(@"persistent coodinator creation error %@, %@", error, [error userInfo]);
        abort();
    }
    
    self.mainContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    [self.mainContext setPersistentStoreCoordinator:self.coordinator];
    [[NSNotificationCenter defaultCenter] postNotificationName:NAModelControllerInitializedNotification object:self];
}

- (void)destroyAndSetup{
    NSString *store_file_name = [self storeFileName];
    if([[NSFileManager defaultManager] fileExistsAtPath:store_file_name]){
        [[NSFileManager defaultManager] removeItemAtPath:store_file_name error:nil];
        [[NSNotificationCenter defaultCenter] postNotificationName:NAModelControllerDestroyedNotification object:self];
        [self setup];
    }
}

+ (void)destroy{
    NAModelController *controller = [[[self class] alloc] initWithoutSetup];
    NSString *store_file_name = [controller storeFileName];
    if([[NSFileManager defaultManager] fileExistsAtPath:store_file_name]){
        [[NSFileManager defaultManager] removeItemAtPath:store_file_name error:nil];
        [[NSNotificationCenter defaultCenter] postNotificationName:NAModelControllerDestroyedNotification object:self];
    }
}

static NSMutableDictionary *__namodel_controllers__ = nil;
static NSMutableDictionary *__class_reference__ = nil;

+ (void)load{
    [super load];
    
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
        __namodel_controllers__ = [@{} mutableCopy];
        __class_reference__ = [@{} mutableCopy];
	});
}

+ (NAModelController *)_createControllerByName:(NSString *)name bundle:(NSBundle *)bundle{
    NAModelController *controller = [[[self class] alloc] init];
    controller.name = name;
    controller.bundle = bundle;
    [controller setup];
    return controller;
}

+ (NAModelController *)controllerByName:(NSString *)name bundle:(NSBundle *)bundle{
    NAModelController *controller = [self getControllerByName:name];
    if(!controller)
        controller = [self _createControllerByName:name bundle:bundle];
    __namodel_controllers__[name] = controller;
    return controller;
}

+ (NAModelController *)getControllerByName:(NSString *)name{
    return __namodel_controllers__[name];
}

+ (NAModelController *)getControllerByClass:(Class)kls{
    return __class_reference__[NSStringFromClass(kls)];
}

- (void)addManagedObjectClasses:(NSArray *)klss{
    [[self managedObjectClasses] addObjectsFromArray:klss];
    for (Class kls in klss) {
        __class_reference__[NSStringFromClass(kls)] = self;
    }
}

@end
