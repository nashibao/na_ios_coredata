//
//  TestParent.h
//  na_ios_coredata_test
//
//  Created by nashibao on 2013/01/08.
//  Copyright (c) 2013年 nashibao. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class TestChild;

@interface TestParent : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * hoge;
@property (nonatomic, retain) NSString * subdoc__fuga;
@property (nonatomic, retain) id data;
@property (nonatomic, retain) NSSet *childs;
@end

@interface TestParent (CoreDataGeneratedAccessors)

- (void)addChildsObject:(TestChild *)value;
- (void)removeChildsObject:(TestChild *)value;
- (void)addChilds:(NSSet *)values;
- (void)removeChilds:(NSSet *)values;

@end
