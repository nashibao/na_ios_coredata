//
//  NSManagedObject+na.h
//  SK3
//
//  Created by nashibao on 2013/01/07.
//  Copyright (c) 2013年 s-cubism. All rights reserved.
//

#import <CoreData/CoreData.h>

/*
 coredataをスキーマレスに使うためのカテゴリ．
 */
@interface NSManagedObject (json)

/*
 jsonを自動でマッピングする
 valueForKeyPathでアクセスするが、coredataのfield名にdotが使えないため
 @"__" -> @"."の変換を行う．
 例えば、
 @{
    @"prop1": @{
        @"prop2": hoge
    }
 }
 の場合、field名を@"prop1__prop2"とすれば良い．
 */
+ (BOOL)enableAutoMapping;

// マッピングAPI
- (void)updateByJSON:(id)json;

// jsonをまるまる突っ込む
+ (NSString *)data_for_key;

@end
