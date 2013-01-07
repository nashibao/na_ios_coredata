//
//  NSManagedObject+na.m
//  SK3
//
//  Created by nashibao on 2013/01/07.
//  Copyright (c) 2013年 s-cubism. All rights reserved.
//

#import "NSManagedObject+json.h"

@implementation NSManagedObject (json)

+ (BOOL)enableAutoMapping{
    return YES;
}

- (void)updateByJSON:(id)json{
    if([[self class] enableAutoMapping]){
        for(NSString *attribute in [[self entity] attributesByName]){
            NSString *dotattribute = [attribute stringByReplacingOccurrencesOfString:@"__" withString:@"."];
            id value = [json valueForKeyPath:dotattribute];
            if(isnull(value))
                continue;
            [self setValue:value forKeyPath:attribute];
        }
    }
    if([[self class] data_for_key]){
        [self setValue:json forKey:[[self class] data_for_key]];
    }
}

+ (NSString *)data_for_key{
    return @"data";
}

@end
