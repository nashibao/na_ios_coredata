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

- (void)updateByJSON:(NSDictionary *)json{
    if(!json)
        return;
    BOOL has_data_key = NO;
    if([[self class] enableAutoMapping]){
        for(NSString *attribute in [[self entity] attributesByName]){
            if([attribute isEqualToString:[[self class] data_for_key]]){
                has_data_key = YES;
            }
            NSString *dotattribute = [attribute stringByReplacingOccurrencesOfString:@"__" withString:@"."];
            id value = [json valueForKeyPath:dotattribute];
            if(isnull(value)){
                value = [json valueForKeyPath:attribute];
                if(isnull(value))
                    continue;
            }
            [self setValue:value forKeyPath:attribute];
        }
    }
    if(has_data_key){
        [self setValue:json forKey:[[self class] data_for_key]];
    }
}

+ (NSString *)data_for_key{
    return @"data";
}

@end
