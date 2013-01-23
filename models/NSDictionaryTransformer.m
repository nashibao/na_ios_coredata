//
//  NSDictionaryTransformer.m
//  SK3
//
//  Created by nashibao on 2012/10/02.
//  Copyright (c) 2012年 s-cubism. All rights reserved.
//

#import "NSDictionaryTransformer.h"

@implementation NSDictionaryTransformer

+ (Class)transformedValueClass
{
    return [NSData class];
}

+ (BOOL)allowsReverseTransformation
{
    return YES;
}

- (id)transformedValue:(id)value
{
    if (value == nil)
        return nil;
    
    // I pass in raw data when generating the image, save that directly to the database
    if ([value isKindOfClass:[NSData class]])
        return value;
    
    id retrnval = [NSKeyedArchiver archivedDataWithRootObject:value];
    
    return retrnval;
}

- (id)reverseTransformedValue:(id)value
{
    id retrnval = [NSKeyedUnarchiver unarchiveObjectWithData:(NSData *)value];
    
    return retrnval;
}

@end
