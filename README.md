# `na_ios_coredata`

`na_ios_coredata`は、扱うのに経験が必要なcoredataを、簡単に扱えるようにするモジュールです．

データの正しさとパフォーマンスの良さを両立するため、多くのAPIの内部ではスレッドを使い、なおかつ、それを隠蔽しています．

例えば、`TestObject`という`NSManagedObject`のクラスがあった場合、

```objective-c
[TestObject filter:@{@"name": @"test"} complete:^(NSArray *mos) {
    // 色々処理
}];
```

このように非同期メソッドの`complete`ハンドラに結果が渡されます．また`complete`ハンドラはmain threadで返ってくるため、ハンドラ内でUIの処理をしても、問題が無いようになっています．
非同期メソッドには`filter`の他に、`create`、`get`、`get_or_create`、`bulk_create`、`bulk_get_or_create`などのAPIがあります．

```objective-c
[TestObject create:@{@"name": @"test2"} complete:^(id mo) {
  // hogehoge
}];

[TestObject get_or_create:@{@"name": @"test"} complete:^(id mo) {
  // hogehoge
}];

// スキーマレス、サブドキュメントマッピングの例
NSDictionary *json = @{
	@"name": @"test",
	@"hoge": @"hogehoge",
	@"subdoc": @{
		@"fuga": @"fugafuga"
	}
};
[TestObject get_or_create:json eqKeys:@[@"name"] complete:^(id obj) {
	obj.name //->@"test"
	obj.hoge //->@"hogehoge"
	obj.data[@"hoge"] //->@"hogehoge"
	obj.subdoc__fuga //->@"fugafuga"
}];

```

`create`や`get_or_create`、`bulk_get_or_create`はcontextに変更を加える可能性がありますが、その場合は、`TestObject`に登録した`mainContext`(main thread上のcontext)に変更がマージされてから`complete`ハンドラは呼ばれます．そのため、`complete`ハンドラ内でUIを更新すると、変更分も表示されることになります．

`get_or_create`や`bulk_get_or_create`は`eqKeys`プロパティを持つ事が出来ます．これはマッチングに`eqKeys`で指定したデータを使い、残りは単純にアップデートに使います．

また、同じようにして、ハンドラを渡さない同期メソッドもあります．

```objective-c
TestObject *obj = [TestObject create:@{@"name": @"test"}];
NSArray *objs = [TestObject filter:@{@"name": @"test"}];
TestObject *obj2 = [TestObject get_or_create:@{@"name": @"test"}];
Bool bl = (obj == obj2); => YES
```

最後に、独自にcoredata上でスレッドを作成したい上級者向けには、次のようなメソッドがあります．

```objective-c
[mainContext performBlockOutOfOwnThread:^(NSManagedObjectContext *context){
    // !!!!!!ここでいろいろと変更を加える!!!!!!
    [context save:nil];
} afterSaveOnMainThread:^(NSNotification *note) {
    // !!!!!!終了処理!!!!!!
}];
```

`performBlockOutOfOwnThread:^(NSManagedObjectContext *context)block afterSaveOnMainThread:^(NSNotification *note)save`は、main thread上のcontextからしか呼び出すことを考慮していない事に注意して下さい．
また`block`ハンドラはmain threadじゃなく、`save`ハンドラはmainThreadであることにも注意して下さい．
`save`ハンドラは`mainContext`に変更がマージされた後に呼び出されるため、`save`ハンドラ内で（`mainContext`につなげてある）UIを更新することで、変更分も表示することができます．

これは次の処理のラッパーになっています．


```objective-c
NSManagedObjectContext *mainContext = [ModelController sharedController].mainContext;
NSPersistentStoreCoordinator *coordinator = mainContext.persistentStoreCoordinator;
NSManagedObjectContext *context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
[context setPersistentStoreCoordinator:coordinator];
[[NSNotificationCenter defaultCenter] addObserverForName:NSManagedObjectContextDidSaveNotification object:context queue:nil usingBlock:^(NSNotification *note) {
    [mainContext performSelectorOnMainThread:@selector(mergeChangesFromContextDidSaveNotification:)
                                  withObject:note
                               waitUntilDone:YES];
    dispatch_async(dispatch_get_main_queue(), ^{
        // !!!!!!終了処理!!!!!!
    });
}];

[context performBlock:^{
    // !!!!!!ここでいろいろと変更を加える!!!!!!
    [context save:nil];
}];
```

# 設定方法

まず、pchファイルなどで`na_ios_async.h`をimportして下さい．

`hoge.modeld`の中に`TestObject`と`TestObject2`が入っている場合、AppDelegateなどで、次のように書いて下さい．

```objective-c
NAModelController *controller = [NAModelController controllerByName:@"hoge"];
[controller addManagedObjectClasses:@[[TestObject class], [TestObject2 class]]];
```

これで晴れて`na_ios_coredata`の全ての機能を使う事が出来ます．

# スキーマレス・コアデータのススメ

`na_ios_coredata`では、次の理由から、スキーマレスな`NSManagedObject`を標準で採用しています．

 1. スキーマ変更によるアップデート時のmigration
 2. サーバサイドのスキーマ変更への追従
 3. json形式でのサーバとの同期

1,2は非常にめんどうな問題です．サーバ側にしろクライアント側にしろスキーマ変更によるマイグレーションはユーザ、開発者にとって非常に手間のかかる、バグの混入しやすい作業です．一般的なwebアプリケーションとは異なり、ネイティブアプリケーションの場合、アップデート時にしかスキーマを変更出来ません．また、今までの経験上、スキーマに定義されるフィールドの多くは、わざわざカラムに持つ必要の無いものです．
そこで、`NSManagedObject`のデータは一つの`NSDictionary`(JSON)として持ち、INDEXの用途にのみattributeを定義する方法を紹介します．

```objective-c
#import "NSManagedObject+json.h"
```

をimportするとNSManagedObjectにupdateByJSONというAPIを生やしてくれます．

```objective-c
SchemalessModel *obj = [SchemalessModel create:@{}];
NSDictionary *json = @{
  @"prop1": @"hoge", 
  @"subdoc": @{
    @"prop2": @"fuga"
  }
};
[obj updateByJSON:json];
```

こうすることで、`SchemalessModel`が`prop1`や`subdoc__prop2`というattributeを持っていた場合、そこに`@"hoge"`と`@"fuga"`をマッピングしてくれます．ただし、次に述べるように、マッピングはしなくても利用することが出来ます．attributeにする場合は、その値で検索やソートをしたい場合に限って下さい．
また`data`(デフォルト．変更化)というattributeに`updateByJSON`に渡した`json`そのものを格納しておいてくれます．

これを利用するのは次のようなイメージです．

```objective-c
SchemalessModel *obj = [SchemalessModel get:@{}];
[cell.textLabel setText:obj.data[@"prop1"]]
or
[cell.textLabel setText:obj.prop1]
```

このようにすることで、マイグレーションのコストを押さえるのに加えて、数多くのフィールドを削減して、コードをクリーンに保つことが出来るでしょう．

# `magicalpanda/MagicalRecord`との比較

同じような目的のモジュールに、[magicalpanda/MagicalRecord](https://github.com/magicalpanda/MagicalRecord)があります．`magicalpanda/MagicalRecord`の“Performing Core Data operations on Threads“の章も合わせて参照して下さい．

`magicalpanda/MagicalRecord`では、filteringやsortingにメリットがあります．`na_ios_coredata`に含まれていないような複雑なフェッチを行うことができます．
これに対して、`na_ios_coredata`では複雑なfilteringやsortingを介するフェッチには`NSFetchedResultsController`経由で行い、`NSArray`を介さない方法を推奨しています．これは、`UITableViewController`などと併用する場合、パフォーマンスとメモリの観点において都合が良いからです．

`NSFetchedResultsController`と`UITableViewController`を`na_ios_coredata`で使うには`na_ios_coredata_ui`を参照して下さい．

`na_ios_coredata`ではフェッチに自由度がない代わりに、フェッチやインサートに非同期のメソッドを持っています．これらを使う事でUIのブロックを防ぐことを念頭におきつつ、複雑なスレッドプログラミングを隠蔽することを目的にしています．

`magicalpanda/MagicalRecord`も分かりやすいAPIを持ったすばらしいモジュールです．上記の比較事項を念頭に入れて、プログラマはどちらのライブラリを選ぶかを選択することができます．


# 依存関係

依存元：**なし**  
依存先: **na_coredata_table**, **na_coredata_sync**
