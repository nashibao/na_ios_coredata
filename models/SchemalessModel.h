//
//  SchemalessModel.h
//  SK3
//
//  Created by nashibao on 2013/01/07.
//  Copyright (c) 2013年 s-cubism. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface SchemalessModel : NSManagedObject

@property (nonatomic, retain) id data;
@property (nonatomic, retain) id edited_data;

@end
