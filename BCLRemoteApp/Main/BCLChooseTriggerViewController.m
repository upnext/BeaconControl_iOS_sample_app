//
//  BOSChooseTriggerViewController.m
//  BCLRemoteApp
//
//  Created by Artur Wdowiarski on 05.07.2015.
//  Copyright (c) 2015 UpNext. All rights reserved.
//

#import "BCLChooseTriggerViewController.h"
#import "BCLTriggerTableViewCell.h"

@interface BCLChooseTriggerViewController () <UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;


@end

@implementation BCLChooseTriggerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.scrollEnabled = NO;
    self.tableView.tableFooterView = [UIView new];
}

#pragma mark - UITableViewDataSource & UITableViewDelegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 5;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    BCLTriggerTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"triggerCell" forIndexPath:indexPath];
    UIImageView *checkmark = cell.checkmark;
    checkmark.hidden = YES;
    
    NSString *text;
    
    switch (indexPath.row) {
        case 0:
        {
            text = @"On Hello";
            if (self.chosenTrigger == BCLEventTypeEnter) {
                checkmark.hidden = NO;
            }
            break;
        }
        case 1:
        {
            text = @"On Leave";
            if (self.chosenTrigger == BCLEventTypeLeave) {
                checkmark.hidden = NO;
            }
            break;
        }
        case 2:
        {
            text = @"Almost Touching";
            if (self.chosenTrigger == BCLEventTypeRangeImmediate) {
                checkmark.hidden = NO;
            }
            break;
        }
        case 3:
        {
            text = @"Nearby";
            if (self.chosenTrigger == BCLEventTypeRangeNear) {
                checkmark.hidden = NO;
            }
            break;
        }
        case 4:
        {
            text = @"In Sight";
            if (self.chosenTrigger == BCLEventTypeRangeFar) {
                checkmark.hidden = NO;
            }
            break;
        }
        default:
            break;
    }
    
    cell.label.text = text;
    
    return cell;
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Remove seperator inset
    if ([cell respondsToSelector:@selector(setSeparatorInset:)]) {
        [cell setSeparatorInset:UIEdgeInsetsZero];
    }
    
    // Prevent the cell from inheriting the Table View's margin settings
    if ([cell respondsToSelector:@selector(setPreservesSuperviewLayoutMargins:)]) {
        [cell setPreservesSuperviewLayoutMargins:NO];
    }
    
    // Explictly set your cell's layout margins
    if ([cell respondsToSelector:@selector(setLayoutMargins:)]) {
        [cell setLayoutMargins:UIEdgeInsetsZero];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    BCLEventType trigger;
    
    BCLTriggerTableViewCell *cell = (BCLTriggerTableViewCell *) [self.tableView cellForRowAtIndexPath:indexPath];
    cell.checkmark.hidden = NO;
    
    switch (indexPath.row) {
        case 0:
            trigger = BCLEventTypeEnter;
            break;
        case 1:
            trigger = BCLEventTypeLeave;
            break;
        case 2:
            trigger = BCLEventTypeRangeImmediate;
            break;
        case 3:
            trigger = BCLEventTypeRangeNear;
            break;
        case 4:
            trigger = BCLEventTypeRangeFar;
            break;
        default:
            break;
    }
    
    self.chosenTrigger = trigger;
    [self.tableView reloadData];
    [self.delegate chooseTriggerViewController:self didChooseTrigger:trigger];
}

@end
