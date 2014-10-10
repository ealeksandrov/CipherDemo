//  Copyright (c) 2014 Evgeny Aleksandrov. License: MIT.

#import "TasksViewController.h"
#import "AppDelegate.h"

@interface TasksViewController () {
    NSArray *tasksIdArray;
}

@end

@implementation TasksViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self loadData];
    [self.tableView reloadData];
}

#pragma mark - DB actions

- (void)loadData {
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    [appDelegate.dbQueue inDatabase:^(FMDatabase *db) {
        NSMutableArray *_tasksIdArray = @[].mutableCopy;
        FMResultSet *tasksSet = [db executeQuery:@"select objectId from tasks WHERE projectId = ?",self.projectId];
        while ([tasksSet next]) {
            [_tasksIdArray addObject:@([tasksSet intForColumn:@"objectId"])];
        }
        tasksIdArray = [_tasksIdArray copy];
    }];
}

#pragma mark - UITableView datasource & delegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [tasksIdArray count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"TaskCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    NSMutableDictionary *taskDict = @{}.mutableCopy;
    [appDelegate.dbQueue inDatabase:^(FMDatabase *db) {
        FMResultSet *tasksSet = [db executeQuery:@"select * from tasks where objectId = ?",tasksIdArray[indexPath.row]];
        if ([tasksSet next]) {
            [taskDict setObject:@([tasksSet intForColumn:@"objectId"]) forKey:@"objectId"];
            [taskDict setObject:[tasksSet stringForColumn:@"title"] forKey:@"title"];
            [taskDict setObject:[tasksSet stringForColumn:@"text"] forKey:@"text"];
        }
        [tasksSet close];
    }];
    
    [cell.textLabel setText:[NSString stringWithFormat:@"%@ - %@",taskDict[@"objectId"],taskDict[@"title"]]];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
