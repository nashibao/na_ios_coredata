//
//  NSManagedObjectContext+na.m
//  SK3
//
//  Created by nashibao on 2012/10/01.
//  Copyright (c) 2012年 s-cubism. All rights reserved.
//

#import "NSManagedObjectContext+na.h"

#import "NSPredicate+na.h"

#import "NSManagedObject+json.h"

@implementation NSManagedObjectContextGetOrCreateDictionary
@end


@implementation NSManagedObjectContext (na)

- (NSArray *)filterObjects:(NSString *)entityName props:(NSDictionary *)props{
    NSPredicate* pred = [NSPredicate predicateForEqualProps:props];
	
	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:entityName inManagedObjectContext:self];
    if(pred)
        [fetchRequest setPredicate:pred];
	[fetchRequest setEntity:entity];
	
    @try {
        NSError *error;
        NSArray *arr = [self executeFetchRequest:fetchRequest error:&error];
        if(arr && [arr count]>0){
            return arr;
        }
    }
    @catch (NSException *exception) {
        NSLog(@"%s:%@",__FUNCTION__,exception);
    }
    @finally {
    }
	return nil;
}

- (NSManagedObject *)getObject:(NSString *)entityName props:(NSDictionary *)props{
    NSPredicate* pred = [NSPredicate predicateForEqualProps:props];
	
	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:entityName inManagedObjectContext:self];
    if(pred)
        [fetchRequest setPredicate:pred];
	[fetchRequest setEntity:entity];
	
    @try {
        NSError *error;
        NSArray *arr = [self executeFetchRequest:fetchRequest error:&error];
        if(arr && [arr count]>0){
            NSManagedObject *obj = [arr objectAtIndex:0];
            return obj;
        }
    }
    @catch (NSException *exception) {
        NSLog(@"%s:%@",__FUNCTION__,exception);
    }
    @finally {
    }
	return nil;
}

- (NSManagedObject *)createObject:(NSString *)entityName props:(NSDictionary *)props{
    NSEntityDescription *entity = [NSEntityDescription entityForName:entityName inManagedObjectContext:self];
    NSManagedObject *obj = [NSEntityDescription insertNewObjectForEntityForName:[entity name] inManagedObjectContext:self];
    for(NSString *key in props){
        id val = props[key];
        [obj setValue:val forKeyPath:key];
    }
    return obj;
}

//dictionaryからkeyの部分だけ取り出す関数
- (NSDictionary *)_props:(NSDictionary *)json keys:(NSArray *)keys{
    NSMutableDictionary *dic = [@{} mutableCopy];
    for(NSString *attribute in keys){
        NSString *dotattribute = [attribute stringByReplacingOccurrencesOfString:@"__" withString:@"."];
        id value = [json valueForKeyPath:dotattribute];
        if(isnull(value))
            continue;
        dic[attribute] = value;
    }
    return dic;
}

- (NSManagedObjectContextGetOrCreateDictionary *)getOrCreateObject:(NSString *)entityName props:(NSDictionary *)props{
    return [self getOrCreateObject:entityName props:props update:nil];
}

- (NSManagedObjectContextGetOrCreateDictionary *)getOrCreateObject:(NSString *)entityName props:(NSDictionary *)props update:(NSDictionary *)update{
    NSManagedObjectContextGetOrCreateDictionary *dic = [[NSManagedObjectContextGetOrCreateDictionary alloc] init];
    NSManagedObject *obj = [self getObject:entityName props:props];
    if(!obj){
        obj = [self createObject:entityName props:props];
    }
    [obj updateByJSON:update];
    dic.object = obj;
    dic.is_created = NO;
    return dic;
}

- (NSManagedObjectContextGetOrCreateDictionary *)getOrCreateObject:(NSString *)entityName allProps:(NSDictionary *)allProps eqKeys:(NSArray *)eqKeys upKeys:(NSArray *)upKeys{
    NSDictionary *props = [self _props:allProps keys:eqKeys];
    NSDictionary *update = [self _props:allProps keys:upKeys];
    return [self getOrCreateObject:entityName props:props update:update];
}

#pragma mark bulk操作

- (NSArray *)bulkCreateObjects:(NSString *)entityName props:(NSArray *)propss{
    NSMutableArray *result = [@[] mutableCopy];
    for(NSDictionary *props in propss){
        NSManagedObject *obj = [self createObject:entityName props:props];
        [result addObject:obj];
    }
    return result;
}

- (NSArray *)bulkGetOrCreateObjects:(NSString *)entityName props:(NSArray *)propss updates:(NSArray *)updates{
    if(updates && propss)
        if([updates count] != [propss count])
            return nil;
    NSMutableArray *result = [@[] mutableCopy];
    int cnt = 0;
    for(NSDictionary *props in propss){
        NSDictionary *update = nil;
        if(updates)
            update = updates[cnt];
        NSManagedObjectContextGetOrCreateDictionary *dic = [self getOrCreateObject:entityName props:props update:update];
        NSManagedObject *obj = dic.object;
        [result addObject:obj];
        cnt += 1;
    }
    return result;
}

- (NSArray *)bulkGetOrCreateObjects:(NSString *)entityName allProps:(NSArray *)allPropss eqKeys:(NSArray *)eqKeys upKeys:(NSArray *)upKeys{
    NSMutableArray *result = [@[] mutableCopy];
    for(NSDictionary *allProps in allPropss){
        NSDictionary *props = [self _props:allProps keys:eqKeys];
        NSDictionary *update = [self _props:allProps keys:upKeys];
        NSManagedObjectContextGetOrCreateDictionary *dic = [self getOrCreateObject:entityName props:props update:update];
        NSManagedObject *obj = dic.object;
        [result addObject:obj];
    }
    return result;
}

#pragma mark delete

- (void)deleteObjectWithCheck:(NSManagedObject *)obj{
    if(!obj)
        return;
    @try {
        [self deleteObject:obj];
    }@catch (NSException *exception) {
        NSLog(@"%s:%@",__FUNCTION__,@"already deleted");
    }@finally {
    }
}

- (void)deleteAllObjects:(NSString *)entityName{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:entityName inManagedObjectContext:self];
    [fetchRequest setEntity:entity];
	
    NSError *error;
    NSArray *items = [self executeFetchRequest:fetchRequest error:&error];
    for (NSManagedObject *managedObject in items) {
        [self deleteObjectWithCheck:managedObject];
    }
}

- (void)deleteObjectByPath:(NSFetchedResultsController *)fetchedResultController :(NSIndexPath *)indexPath{
    NSManagedObject *mo = [fetchedResultController objectAtIndexPath:indexPath];
    [self deleteObjectWithCheck:mo];
}

- (void)performBlockOutOfOwnThread:(void(^)(NSManagedObjectContext *context))block afterSaveOnMainThread:(void(^)(NSNotification *note))afterSaveOnMainThread{
    NSPersistentStoreCoordinator *coordinator = self.persistentStoreCoordinator;
    NSManagedObjectContext *context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    [context setPersistentStoreCoordinator:coordinator];
    context.mergePolicy = NSOverwriteMergePolicy;
    if(afterSaveOnMainThread){
        [[NSNotificationCenter defaultCenter] addObserverForName:NSManagedObjectContextDidSaveNotification object:context queue:nil usingBlock:^(NSNotification *note) {
            [self performSelectorOnMainThread:@selector(mergeChangesFromContextDidSaveNotification:)
                                          withObject:note
                                       waitUntilDone:YES];
            if(afterSaveOnMainThread){
                dispatch_async(dispatch_get_main_queue(), ^{
                    afterSaveOnMainThread(note);
                });
            }
        }];
    }
    
    [context performBlock:^{
        if(block)
            block(context);
    }];
}

@end
