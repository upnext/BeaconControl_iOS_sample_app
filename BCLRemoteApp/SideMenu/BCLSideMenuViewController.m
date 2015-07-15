//
//  BCLSideMenuViewController.m
//  BCLRemoteApp
//
// Copyright (c) 2015, Upnext Technologies Sp. z o.o.
// All rights reserved.
//
// This source code is licensed under the BSD 3-Clause License found in the
// LICENSE.txt file in the root directory of this source tree.
//

#import "BCLSideMenuViewController.h"
#import "BCLSideMenuTableViewCell.h"
#import "BLCZonesViewController.h"
#import "BCLContainerViewController.h"
#import "BeaconCtrlManager.h"
#import "UIViewController+BCLActivityIndicator.h"
#import "UIColor+BCLAppColors.h"
#import "AlertControllerManager.h"
#import <AKPickerView/AKPickerView.h>


@interface BCLSideMenuViewController () <UITableViewDataSource, UITableViewDelegate, AKPickerViewDataSource, AKPickerViewDelegate>

@property (nonatomic, strong) IBOutlet UITableView * tableView;
@property (nonatomic, strong) IBOutlet UILabel * usernameLabel;

@property (weak, nonatomic) IBOutlet UIView *floorSelectorContainer;
@property (nonatomic, strong) AKPickerView *floorSelector;

@property (nonatomic, strong) NSArray * dataZones;
@property (nonatomic, strong) NSMutableArray * dataSelectedZones;

@end

@implementation BCLSideMenuViewController

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[NSUserDefaults standardUserDefaults] removeObserver:self forKeyPath:@"BCLRemoteAppMaxFloorNumber"];
}

- (void)reload:(BOOL)clearSelection
{
    self.usernameLabel.text = [BeaconCtrlManager sharedManager].beaconCtrl.userId;
    self.dataZones = [[BeaconCtrlManager sharedManager].beaconCtrl.configuration.zones allObjects];
    if (clearSelection) {
        self.dataSelectedZones = [self.dataZones mutableCopy];
        self.showsNoneZone = YES;
    } else {
        NSMutableArray *selectedZones = [NSMutableArray new];
        for (BCLZone *selectedZone in self.dataSelectedZones) {
            [self.dataZones enumerateObjectsUsingBlock:^(BCLZone *zone, NSUInteger idx, BOOL *stop) {
                if ([zone.zoneIdentifier isEqualToString:selectedZone.zoneIdentifier]) {
                    [selectedZones addObject:zone];
                    *stop = YES;
                }
            }];
        }

        self.dataSelectedZones = selectedZones;
    }
    
    [self.floorSelector reloadData];
    [self.tableView reloadData];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(menuStateChanged:) name:MFSideMenuStateNotificationEvent object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(beaconCtrlManagerConfigurationRefreshHandler:) name:BeaconManagerDidFetchBeaconCtrlConfigurationNotification object:nil];
    
    [[NSUserDefaults standardUserDefaults] addObserver:self forKeyPath:@"BCLRemoteAppMaxFloorNumber" options:NSKeyValueObservingOptionNew context:nil];
    
    self.tableView.tableFooterView = [UIView new];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    if (!self.floorSelector) {
        self.floorSelector = [[AKPickerView alloc] initWithFrame:self.floorSelectorContainer.bounds];
        [self.floorSelectorContainer addSubview:self.floorSelector];
        self.floorSelector.highlightedTextColor = [UIColor blueAppColor];
        self.floorSelector.delegate = self;
        self.floorSelector.dataSource = self;
    }
    
    [self reload: YES];
}

- (void)menuStateChanged:(NSNotification *)notification
{
    MFSideMenuStateEvent state = [notification.userInfo[@"eventType"] integerValue];
    switch (state) {

        case MFSideMenuStateEventMenuWillOpen:
            [self reload:NO];
            break;
        case MFSideMenuStateEventMenuDidOpen:break;
        case MFSideMenuStateEventMenuWillClose:break;
        case MFSideMenuStateEventMenuDidClose:break;
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self reload: NO];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([object isEqual:[NSUserDefaults standardUserDefaults]] && [keyPath isEqualToString:@"BCLRemoteAppMaxFloorNumber"]) {
        if (self.floorSelector.selectedItem >= [self numberOfItemsInPickerView:self.floorSelector]) {
            [self.floorSelector selectItem:0 animated:NO];
            if ([self.delegate respondsToSelector:@selector(sideMenuViewController:didSelectFloorNumber:)]) {
                [self.delegate sideMenuViewController:self didSelectFloorNumber:nil];
            }
        }
        [self.floorSelector reloadData];
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.dataZones.count + 1;
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    BCLSideMenuTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"zoneCell" forIndexPath:indexPath];
    
    [cell.selectionSwitch addTarget:self action:@selector(switchValueChanged:) forControlEvents:UIControlEventValueChanged];
        cell.selectionSwitch.transform = CGAffineTransformMakeScale(0.8f, 0.8f);
    
    [cell.colorIndicator.subviews enumerateObjectsUsingBlock:^(UIView *subview, NSUInteger idx, BOOL *stop) {
        [subview removeFromSuperview];
    }];
    
    if (indexPath.row > 0) {
        BCLZone *zone = [self.dataZones objectAtIndex:indexPath.row - 1];
        cell.label.text = zone.name;
        cell.selectionSwitch.on = [self.dataSelectedZones containsObject:zone];
        cell.selectionSwitch.tag = indexPath.row;
        cell.colorIndicator.backgroundColor = zone.color;
    } else {
        cell.label.text = @"Unassigned";
        cell.selectionSwitch.on = self.showsNoneZone;
        cell.selectionSwitch.tag = indexPath.row;
        UIImageView *unassignedBeaconImageView = [[UIImageView alloc] initWithFrame:cell.colorIndicator.bounds];
        unassignedBeaconImageView.image = [UIImage imageNamed:@"beaconWithoutZone"];
        unassignedBeaconImageView.contentMode = UIViewContentModeScaleAspectFit;
        [cell.colorIndicator addSubview:unassignedBeaconImageView];
        cell.colorIndicator.backgroundColor = [UIColor clearColor];
    }
    return cell;
}

- (void)switchValueChanged:(id)sender
{
    UISwitch * switchButton = (UISwitch*)sender;
    if (switchButton.tag > 0) {
        BCLZone *zone = [self.dataZones objectAtIndex:switchButton.tag - 1];
        if (switchButton.on) {
            [self.dataSelectedZones addObject:zone];
        } else {
            [self.dataSelectedZones removeObject:zone];
        }
    } else {
        self.showsNoneZone = switchButton.on;
    }
    if ([self.delegate respondsToSelector:@selector(sideMenuViewController:didChangeSelection:showsNoneZone:)]) {
        [self.delegate sideMenuViewController:self didChangeSelection:[NSArray arrayWithArray:self.dataSelectedZones] showsNoneZone:self.showsNoneZone];
    }
}

- (IBAction)didClickLogoutButton:(id)sender
{
    [[BeaconCtrlManager sharedManager] logout];
}


- (IBAction)didClickRefreshConfigurationButton:(id)sender
{
    ((UIButton *)sender).enabled = NO;
    __weak BCLSideMenuViewController *weakSelf = self;
    [self.parentViewController showActivityIndicatorViewAnimated:YES];
    [[BeaconCtrlManager sharedManager] refetchBeaconCtrlConfiguration:^(NSError *error) {
        // TODO:
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!error) {
                [weakSelf reload:YES];
                if ([self.delegate respondsToSelector:@selector(sideMenuViewController:didChangeSelection:showsNoneZone:)]) {
                    [self.delegate sideMenuViewController:self didChangeSelection:self.dataSelectedZones showsNoneZone:self.showsNoneZone];
                }
            } else {
                [[AlertControllerManager sharedManager] presentError:error inViewController:self.parentViewController completion:nil];
            }
            ((UIButton *)sender).enabled = YES;
            [weakSelf.parentViewController hideActivityIndicatorViewAnimated:YES];
        });
    }];
}

- (void)beaconCtrlManagerConfigurationRefreshHandler:(NSNotification *)notification
{
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^() {
        [weakSelf reload:YES];
    });
}

- (IBAction)didClickZonesAndFloorsButton:(id)sender
{
    BLCZonesViewController * vc = [BLCZonesViewController newZonesViewController];
    [vc setMode:kBCLZonesViewControllerEdit initialZoneSelection:nil floorSelection:nil];
    BCLContainerViewController * parent = (BCLContainerViewController*)self.parentViewController;
    UINavigationController *navigationController = parent.centerViewController;

    //prevent the view to show multiple times
    if ([navigationController viewControllers].count == 1) {
        [parent.centerViewController pushViewController:vc animated:YES];
        [parent toggleLeftSideMenuCompletion:nil];
    }
}

#pragma mark - AKPickerViewDataSource & AKPickerViewDelegate

- (NSUInteger)numberOfItemsInPickerView:(AKPickerView *)pickerView
{
    return [[NSUserDefaults standardUserDefaults] integerForKey:@"BCLRemoteAppMaxFloorNumber"] + 1 + 1;
}

- (NSString *)pickerView:(AKPickerView *)pickerView titleForItem:(NSInteger)item
{
    if (item == 0) {
        return @"All";
    }
    
    if (item == 1) {
        return @"None";
    }
    
    return [NSString stringWithFormat:@"%lu", item - 1];
}

- (CGSize)pickerView:(AKPickerView *)pickerView marginForItem:(NSInteger)item
{
    return CGSizeMake(40, 0);
}

- (void)pickerView:(AKPickerView *)pickerView didSelectItem:(NSInteger)item
{
    NSNumber *floorNumber;
    
    if (item == 0) {
        floorNumber = nil;
    } else if (item == 1){
        floorNumber = @(NSNotFound);
    } else {
        floorNumber = @(item - 1);
    }
    
    [self.delegate sideMenuViewController:self didSelectFloorNumber:floorNumber];
}

@end
