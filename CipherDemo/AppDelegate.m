//  Copyright (c) 2014 Evgeny Aleksandrov. License: MIT.

#import "AppDelegate.h"

//CocoaLumberjack
#import "DDASLLogger.h"
#import "DDTTYLogger.h"
#import "LogFormatter.h"
#import <MBFaker/MBFaker.h>

static NSString * const kEncryptionKey = @"PassKey";
static BOOL kEncryptionStatus = YES;

@interface AppDelegate () {
    FMDatabaseQueue *sharedQueue;
}

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // configure CocoaLumberjack
    [DDLog addLogger:[DDASLLogger sharedInstance]];
    [DDLog addLogger:[DDTTYLogger sharedInstance]];
    LogFormatter *formatter = [[LogFormatter alloc] init];
    [[DDASLLogger sharedInstance] setLogFormatter:formatter];
    [[DDTTYLogger sharedInstance] setLogFormatter:formatter];
    [[DDTTYLogger sharedInstance] setColorsEnabled:YES];
    [[DDTTYLogger sharedInstance] setForegroundColor:[UIColor colorWithWhite:0.3 alpha:1.0] backgroundColor:nil forFlag:LOG_FLAG_VERBOSE];
    [[DDTTYLogger sharedInstance] setForegroundColor:[UIColor blueColor] backgroundColor:nil forFlag:LOG_FLAG_INFO];
    
    NSString *bundleId = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleIdentifier"];
    NSString *bundleShortVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    NSString *bundleVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
    DDLogInfo(@"Starting %@ v%@ (%@)", bundleId, bundleShortVersion, bundleVersion);
    
    NSArray *documentPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentDir = [documentPaths objectAtIndex:0];
    self.databasePath = [documentDir stringByAppendingPathComponent:@"encrypted.sqlite"];
    
    BOOL dbExists = [[NSFileManager defaultManager] fileExistsAtPath:self.databasePath];
    if(!dbExists) {
        [self createAllTables];
        [self generateTestData];
    }
    
    return YES;
}

#pragma mark - DB actions

- (void)createAllTables {
    [self.dbQueue inDatabase:^(FMDatabase *db) {
        BOOL projectsCreated = [db executeUpdate:@"CREATE TABLE 'projects' ( 'objectId' integer NOT NULL PRIMARY KEY AUTOINCREMENT, 'date_timestamp' integer, 'rating' integer, 'text' text )"];
        if(projectsCreated) {
            DDLogVerbose(@"Table created: PROJECTS");
        }
        
        BOOL tasksCreated = [db executeUpdate:@"CREATE TABLE 'tasks' ( 'objectId' integer NOT NULL PRIMARY KEY, 'projectId' integer, 'title' text, 'text' text, 'status' integer DEFAULT 1, 'attach_timestamp' integer, 'completion_timestamp' integer )"];
        if(tasksCreated) {
            DDLogVerbose(@"Table created: TASKS");
        }
        
        if(projectsCreated && tasksCreated) {
            DDLogInfo(@"All tables created");
        }
    }];
}

- (void)generateTestData {
    [self.dbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        NSDate *now = [NSDate date];
        NSCalendar *currentCalendar = [NSCalendar currentCalendar];
        NSDate *startOfTheWeek;
        NSTimeInterval interval;
        [currentCalendar rangeOfUnit:NSWeekCalendarUnit startDate:&startOfTheWeek interval:&interval forDate:now];
        
        NSDate *dateToSave = startOfTheWeek;
        NSDateComponents *dayComponent = [[NSDateComponents alloc] init];
        dayComponent.day = 1;
        
        [MBFaker setLanguage:@"en"];
        
        for (int idx = 0; idx < 5; idx++) {
            long timestampToSave = [dateToSave timeIntervalSince1970];
            NSUInteger ratingToSave = arc4random_uniform(6);
            NSString *projectDesc = [MBFakerLorem words:20];
            
            [db executeUpdate:@"INSERT INTO projects (date_timestamp, rating, text) values (?, ?, ?)",@(timestampToSave),@(ratingToSave),projectDesc];
            dateToSave = [currentCalendar dateByAddingComponents:dayComponent toDate:dateToSave options:0];
        }
        DDLogVerbose(@"Test data created: PROJECTS");
    }];
    
    NSMutableArray *projectsIdArray = @[].mutableCopy;
    [self.dbQueue inDatabase:^(FMDatabase *db) {
        FMResultSet *projectsSet = [db executeQuery:@"select objectId from projects"];
        while ([projectsSet next]) {
            [projectsIdArray addObject:@([projectsSet intForColumn:@"objectId"])];
        }
    }];
    
    [self.dbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        for (NSNumber *projectId in projectsIdArray) {
            for (int idx = 0; idx < 500; idx++) {
                NSString *taskTitle = [MBFakerLorem words:2];
                NSString *taskDesc = [MBFakerLorem sentence];
                
                [db executeUpdate:@"INSERT INTO tasks (projectId, title, text) values (?, ?, ?)",projectId,taskTitle,taskDesc];
            }
        }
        DDLogVerbose(@"Test data created: TASKS");
    }];
    
    DDLogInfo(@"All test data created");
}

#pragma mark - FMDB routines

- (FMDatabase *)database {
    FMDatabase* database = [FMDatabase databaseWithPath:self.databasePath];
    [database open];
    if(kEncryptionStatus) {
        [database setKey:kEncryptionKey];
    }
    
    [database setShouldCacheStatements:YES];
    
    return database;
}

- (FMDatabaseQueue *)dbQueue {
    if (!sharedQueue) {
        sharedQueue = [FMDatabaseQueue databaseQueueWithPath:self.databasePath];
        [sharedQueue inDatabase:^(FMDatabase *db) {
            if(kEncryptionStatus) {
                [db setKey:kEncryptionKey];
            }
            [db setShouldCacheStatements:YES];
        }];
    }
    
    return sharedQueue;
}

@end
