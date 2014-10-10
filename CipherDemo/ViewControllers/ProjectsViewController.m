//  Copyright (c) 2014 Evgeny Aleksandrov. License: MIT.

#import "ProjectsViewController.h"
#import "AppDelegate.h"

#import "TasksViewController.h"

@interface ProjectsViewController () {
    NSArray *projectsIdArray;
}

@end

@implementation ProjectsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self loadData];
    [self.tableView reloadData];
}

#pragma mark - DB actions

- (void)loadData {
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    [appDelegate.dbQueue inDatabase:^(FMDatabase *db) {
        NSMutableArray *_projectsIdArray = @[].mutableCopy;
        FMResultSet *projectsSet = [db executeQuery:@"select objectId from projects"];
        while ([projectsSet next]) {
            [_projectsIdArray addObject:@([projectsSet intForColumn:@"objectId"])];
        }
        projectsIdArray = [_projectsIdArray copy];
    }];
}

#pragma mark - UITableView datasource & delegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [projectsIdArray count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"ProjectCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    NSMutableDictionary *projectDict = @{}.mutableCopy;
    [appDelegate.dbQueue inDatabase:^(FMDatabase *db) {
        FMResultSet *projectsSet = [db executeQuery:@"select * from projects where objectId = ?",projectsIdArray[indexPath.row]];
        if ([projectsSet next]) {
            [projectDict setObject:@([projectsSet intForColumn:@"objectId"]) forKey:@"objectId"];
            [projectDict setObject:[NSDate dateWithTimeIntervalSince1970:[projectsSet doubleForColumn:@"date_timestamp"]]  forKey:@"date"];
            [projectDict setObject:@([projectsSet intForColumn:@"rating"]) forKey:@"rating"];
            [projectDict setObject:[projectsSet stringForColumn:@"text"] forKey:@"text"];
        }
        [projectsSet close];
    }];
    
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setDateStyle:NSDateFormatterShortStyle];
    [df setTimeStyle:NSDateFormatterNoStyle];
    
    [cell.textLabel setText:[NSString stringWithFormat:@"Project %@ - %@ - rating %@",projectDict[@"objectId"],[df stringFromDate:projectDict[@"date"]],projectDict[@"rating"]]];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    TasksViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"tasksViewController"];
    vc.projectId = projectsIdArray[indexPath.row];
    [self.navigationController pushViewController:vc animated:YES];
}

@end
