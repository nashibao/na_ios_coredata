//
//  NSManagedObjectContext+na.h
//  SK3
//
//  Created by nashibao on 2012/10/01.
//  Copyright (c) 2012年 s-cubism. All rights reserved.
//

#import <CoreData/CoreData.h>

@interface NSManagedObjectContextGetOrCreateDictionary : NSObject

@property (strong, nonatomic) NSManagedObject *object;
@property (nonatomic) BOOL is_created;

@end

/*
 moの取得用にcontextそのものにAPIを生やした．
 */
@interface NSManagedObjectContext (na)

- (NSArray *)filterObjects:(NSString *)entityName props:(NSDictionary *)props;
- (NSManagedObject *)getObject:(NSString *)entityName props:(NSDictionary *)props;
- (NSManagedObject *)createObject:(NSString *)entityName props:(NSDictionary *)props;

/*
 getOrCreate操作
 update: 取ってきたものに対してマッピング
 eqKeys: セレクトに使うフィールド名
 upKeys: アップデートに使うフィールド名
 */
- (NSManagedObjectContextGetOrCreateDictionary *)getOrCreateObject:(NSString *)entityName props:(NSDictionary *)props;
//- (NSManagedObjectContextGetOrCreateDictionary *)getOrCreateObject:(NSString *)entityName props:(NSDictionary *)props update:(NSDictionary *)update;
- (NSManagedObjectContextGetOrCreateDictionary *)getOrCreateObject:(NSString *)entityName allProps:(NSDictionary *)allProps eqKeys:(NSArray *)eqKeys isUpdate:(BOOL)isUpdate;

/*
 bulk操作
 */
- (NSArray *)bulkCreateObjects:(NSString *)entityName props:(NSArray *)propss;
//- (NSArray *)bulkGetOrCreateObjects:(NSString *)entityName props:(NSArray *)propss;
- (NSArray *)bulkGetOrCreateObjects:(NSString *)entityName props:(NSArray *)propss updates:(NSArray *)updates;
- (NSArray *)bulkGetOrCreateObjects:(NSString *)entityName allProps:(NSArray *)allProps eqKeys:(NSArray *)eqKeys isUpdate:(BOOL)isUpdate;

/** 別のcontextを作るのがそもそもめんどくさい人のため．
 caution!!!! mainthreadにあるmainContextからのみ呼び出せる！！
 */
- (void)performBlockOutOfOwnThread:(void(^)(NSManagedObjectContext *context))block afterSave:(void(^)(NSNotification *note))afterSave;
- (void)performBlockOutOfOwnThread:(void(^)(NSManagedObjectContext *context))block afterSaveOnMainThread:(void(^)(NSNotification *note))afterSaveOnMainThread;

#pragma mark delete

- (void)deleteObjectWithCheck:(NSManagedObject *)obj;
- (void)deleteAllObjects:(NSString *)entityName;
- (void)deleteObjectByPath:(NSFetchedResultsController *)fetchedResultController :(NSIndexPath *)indexPath;

@end
