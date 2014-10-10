//  Copyright (c) 2014 Evgeny Aleksandrov. License: MIT.

#import <UIKit/UIKit.h>
#import <FMDB/FMDB.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) NSString *databasePath;

- (FMDatabase *)database;
- (FMDatabaseQueue *)dbQueue;

@end
