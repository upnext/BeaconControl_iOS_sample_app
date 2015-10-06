//
//  BCLZonesViewController.m
//  BCLRemoteApp
//
// Copyright (c) 2015, Upnext Technologies Sp. z o.o.
// All rights reserved.
//
// This source code is licensed under the BSD 3-Clause License found in the
// LICENSE.txt file in the root directory of this source tree.
//

#import "BLCZonesViewController.h"
#import "BCLZonesTableViewCell.h"
#import "BeaconCtrlManager.h"
#import "UIColor+Hex.h"
#import "UIViewController+BCLActivityIndicator.h"
#import "AlertControllerManager.h"
#import "UIColor+BCLAppColors.h"
#import <AKPickerView/AKPickerView.h>

static NSString *kBCLStoryboardName = @"Zones";

@interface BLCZonesViewController () <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, AKPickerViewDataSource, AKPickerViewDelegate>

@property (nonatomic, strong) IBOutlet UITableView * tableView;
@property (nonatomic, strong) IBOutlet UILabel * titleLabel;
@property (nonatomic, strong) IBOutlet UILabel * emptyLabel;
@property (weak, nonatomic) IBOutlet UILabel *floorsTitleLabel;

@property (nonatomic, strong) IBOutlet UIButton * addZoneButton;
@property (nonatomic, strong) IBOutlet UIButton * deleteZonesButton;

@property (weak, nonatomic) IBOutlet UIView *floorSelectorContainer;
@property (nonatomic, strong) AKPickerView *floorSelector;

@property (nonatomic, weak) IBOutlet NSLayoutConstraint * titleLabelHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *zonesHeaderTopCostraint;

@property (nonatomic, strong) NSMutableArray * dataZones;
@property (nonatomic, strong) BCLZone * selectedZone;
@property (nonatomic) NSNumber *selectedFloor;

@property (nonatomic) BCLZonesViewControllerMode mode;
@property (nonatomic, strong) NSMutableArray * selectedZoneToDelete;

@property (nonatomic) BOOL editRowsEnabled;

@end

@implementation BLCZonesViewController

+ (instancetype)newZonesViewController
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:kBCLStoryboardName bundle:nil];
    BLCZonesViewController * vc = (BLCZonesViewController*)[storyboard instantiateInitialViewController];
    return vc;
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    self.dataZones = [[[BeaconCtrlManager sharedManager].beaconCtrl.configuration.zones allObjects] mutableCopy];

    [self updateEmptyLabelVisbility];
    switch (self.mode) {
        case kBCLZonesViewControllerSelect:
            self.deleteZonesButton.hidden = YES;
            [self.addZoneButton setTitle:@"Select zone" forState:UIControlStateNormal];
            self.titleLabel.text = @"Assign to a zone:";
            self.floorsTitleLabel.text = @"Select floor:";
            break;
        case kBCLZonesViewControllerEdit:
            self.deleteZonesButton.hidden = YES;
            //self.titleLabelHeightConstraint.constant = 0;
            self.zonesHeaderTopCostraint.constant = 20;
            self.floorSelectorContainer.hidden = YES;
            self.floorsTitleLabel.hidden = YES;
            self.navigationItem.title = @"Zones";
            self.titleLabel.text = @"Zones:";
            self.floorsTitleLabel.text = @"Select the number of floors:";
            self.deleteZonesButton.enabled = NO;
            break;
    }
    
    self.tableView.tableFooterView = [UIView new];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self loadNavigationBar];
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
        
        switch (self.mode) {
            case kBCLZonesViewControllerSelect:
            {
                if (!self.selectedFloor) {
                    [self.floorSelector selectItem:0 animated:NO];
                } else if (self.selectedFloor.integerValue != NSNotFound) {
                    [self.floorSelector selectItem:self.selectedFloor.integerValue animated:NO];
                }
                
                break;
            }
            case kBCLZonesViewControllerEdit:
            {
                NSUInteger currentFloorNoSetting = [[NSUserDefaults standardUserDefaults] integerForKey:@"BCLRemoteAppMaxFloorNumber"];
                [self.floorSelector selectItem:currentFloorNoSetting ? currentFloorNoSetting - 1 : 0 animated:NO];
                break;
            }
        }
    }
}

- (void) updateEmptyLabelVisbility
{
    self.emptyLabel.hidden = self.dataZones.count > 0;
}

- (void) setMode:(BCLZonesViewControllerMode)mode initialZoneSelection:(BCLZone *)initialSelection floorSelection:(NSNumber *)floorSelection
{
    self.selectedZone = initialSelection;
    self.selectedFloor = floorSelection;
    self.mode = mode;
}


- (void) reloadDataFromConfiguration
{
    BCLConfiguration * configuration = [BeaconCtrlManager sharedManager].beaconCtrl.configuration;
    if ( configuration != nil ) {
        self.dataZones = [NSMutableArray arrayWithArray:[configuration.zones allObjects]];
    } else {
        self.dataZones = [NSMutableArray array];
    }
    [self.tableView reloadData];
}

- (void) loadNavigationBar
{
    if ( self.mode == kBCLZonesViewControllerEdit ) {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle: @"Edit" style:UIBarButtonItemStyleDone target:self action:@selector(editNavigationBarPressed:)];
    }
}

#pragma mark - UITableViewDataSource & UITableViewDelegate

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (self.mode) {
        case kBCLZonesViewControllerSelect:
        {
            BCLZone * newSelectedZone = indexPath.row == 0 ? nil : [self.dataZones objectAtIndex:indexPath.row - 1];
            self.selectedZone = newSelectedZone;
            [self.tableView reloadData];
            break;
        }
        case kBCLZonesViewControllerEdit:
        {
            BCLZone * zone = [self.dataZones objectAtIndex:indexPath.row];
            if ( [self.selectedZoneToDelete containsObject:zone] ) {
                [self.selectedZoneToDelete removeObject:zone];
            } else {
                [self.selectedZoneToDelete addObject:zone];
            }
            self.deleteZonesButton.enabled = self.selectedZoneToDelete.count > 0;
            [self.tableView reloadData];
            break;
        }
    }
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (self.mode) {
        case kBCLZonesViewControllerSelect:
        {
            return self.dataZones.count + 1;
            break;
        }
        case kBCLZonesViewControllerEdit:
        {
            return self.dataZones.count;
            break;
        }
    }
    
    return self.dataZones.count;
}

- (UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"zonesCellIIdentifier";
    BCLZonesTableViewCell *cell = (BCLZonesTableViewCell*)[tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    cell.saveButton.hidden = YES;
    [cell.indicatorView stopAnimating];
    
    [cell.colorBar.subviews enumerateObjectsUsingBlock:^(UIView *subview, NSUInteger idx, BOOL *stop) {
        [subview removeFromSuperview];
    }];
    
    switch (self.mode) {
        case kBCLZonesViewControllerSelect:
        {
            if (indexPath.row == 0) {
                cell.nameLabel.text = @"Unassigned";
                cell.colorBar.backgroundColor = [UIColor whiteColor];
                cell.checkIcon.image = nil;
                cell.contentWrap.backgroundColor = [UIColor whiteColor];
                UIImageView *unassignedBeaconImageView = [[UIImageView alloc] initWithFrame:cell.colorBar.bounds];
                unassignedBeaconImageView.image = [UIImage imageNamed:@"beaconWithoutZone"];
                unassignedBeaconImageView.contentMode = UIViewContentModeScaleAspectFit;
                [cell.colorBar addSubview:unassignedBeaconImageView];
                if (!self.selectedZone) {
                    cell.checkIcon.image = [UIImage imageNamed:@"check"];
                    cell.contentWrap.backgroundColor = [UIColor whiteColor];
                }
            } else {
                BCLZone * zone = [self.dataZones objectAtIndex:indexPath.row - 1];
                cell.nameLabel.text = zone.name;
                cell.colorBar.backgroundColor = zone.color;
                cell.nameLabel.tag = indexPath.row - 1;
                cell.saveButton.tag = indexPath.row - 1;
                if ( self.selectedZone != nil && [zone.zoneIdentifier isEqualToString:self.selectedZone.zoneIdentifier] ) {
                    cell.checkIcon.image = [UIImage imageNamed:@"check"];
                    cell.contentWrap.backgroundColor = [UIColor whiteColor];
                } else {
                    cell.checkIcon.image = nil;
                    cell.contentWrap.backgroundColor = [UIColor whiteColor];
                }
            }
            cell.nameLabel.enabled = NO;
            cell.nameLabelWidthConstraint.constant = [cell.nameLabel sizeThatFits:CGSizeMake(MAXFLOAT, MAXFLOAT)].width;
            return cell;
            break;
        }
        case kBCLZonesViewControllerEdit:
        {
            BCLZone * zone = [self.dataZones objectAtIndex:indexPath.row];
            cell.nameLabel.text = zone.name;
            cell.colorBar.backgroundColor = zone.color;
            cell.nameLabel.tag = indexPath.row;
            cell.nameLabelWidthConstraint.constant = [cell.nameLabel sizeThatFits:CGSizeMake(MAXFLOAT, MAXFLOAT)].width;
            cell.saveButton.tag = indexPath.row;
            cell.nameLabel.enabled = self.editRowsEnabled;
            if ( self.editRowsEnabled && [self.selectedZoneToDelete containsObject: zone] ) {
                cell.checkIcon.image = [UIImage imageNamed:@"checkbox"];
                cell.contentWrap.backgroundColor = [UIColor whiteColor];
            } else {
                cell.checkIcon.image = nil;
                cell.contentWrap.backgroundColor = [UIColor whiteColor];
            }
            return cell;
            break;
        }
    }

    return cell;
}

#pragma mark - UITextFieldDelegate

- (void) textFieldDidBeginEditing:(UITextField *)textField
{
    self.selectedZoneToDelete = [NSMutableArray array];
    BCLZonesTableViewCell * cell = (BCLZonesTableViewCell*)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:textField.tag inSection:0]];
    if ( cell ) {
        cell.checkIcon.image = nil;
        cell.saveButton.hidden = NO;
        [cell.saveButton addTarget:self action:@selector(saveButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        cell.contentWrap.backgroundColor = [UIColor colorWithRed:0.953 green:0.953 blue:0.953 alpha:1]; /*#f3f3f3*/
        cell.nameLabelWidthConstraint.constant = cell.checkIcon.frame.origin.x - cell.nameLabel.frame.origin.x;
    }
}

- (void) saveButtonPressed:(id)sender
{
    UIButton * button = (UIButton*)sender;
    BCLZonesTableViewCell * cell = (BCLZonesTableViewCell*)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:button.tag inSection:0]];
    if ( cell ) {
        cell.nameLabel.enabled = NO;
        cell.saveButton.hidden = YES;
        [cell.indicatorView startAnimating];
        BCLZone * zoneToUpdate = [self.dataZones objectAtIndex:button.tag];
        NSString * originName = zoneToUpdate.name;
        zoneToUpdate.name = cell.nameLabel.text;
        [[BeaconCtrlManager sharedManager] updateZone:zoneToUpdate completion:^(BCLZone *updatedZone, NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if ( updatedZone == nil) {
                    zoneToUpdate.name = originName;
                    NSString * message = [NSString stringWithFormat:@"Error occured while updating zone: %@", error.domain];
                    UIAlertView * errorAlertView = [[UIAlertView alloc] initWithTitle:@"Error" message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                    [errorAlertView show];
                }
                [self.tableView reloadData];
            });
        }];
    }
}

#pragma mark - Actions

- (void) editNavigationBarPressed:(id)sender
{
    self.selectedZoneToDelete = [NSMutableArray array];
    self.editRowsEnabled = !self.editRowsEnabled;
    self.deleteZonesButton.enabled = NO;
    if ( self.editRowsEnabled ) {
        self.navigationItem.rightBarButtonItem.title = @"Done";
        self.addZoneButton.hidden = YES;
        self.deleteZonesButton.hidden = NO;
    } else {
        self.addZoneButton.hidden = NO;
        self.deleteZonesButton.hidden = YES;
        self.navigationItem.rightBarButtonItem.title = @"Edit";
    }
    [self.tableView reloadData];
}

- (IBAction) deleteZonePressed:(id)sender
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:@"Are you sure you want to delete the selected zones?" preferredStyle:UIAlertControllerStyleAlert];
    
    __weak typeof(self) weakSelf = self;
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"No" style:UIAlertActionStyleCancel handler:nil];
    UIAlertAction *deleteAction = [UIAlertAction actionWithTitle:@"Yes" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        BCLBeaconCtrlAdmin * admin = [BeaconCtrlManager sharedManager].beaconCtrlAdmin;
        if ( weakSelf.selectedZoneToDelete && weakSelf.selectedZoneToDelete.count > 0 ) {
            [self showActivityIndicatorViewAnimated:YES];
            __block NSMutableArray * localZonesToDeleteCopy = [NSMutableArray arrayWithArray:self.selectedZoneToDelete];
            __block void (^deleteZoneCompletion)(BOOL, NSError*) = ^(BOOL success, NSError *error){
                dispatch_async(dispatch_get_main_queue(), ^{
                    [weakSelf hideActivityIndicatorViewAnimated:YES];
                    if (success) {
                        weakSelf.deleteZonesButton.enabled = NO;
                        BCLZone *zone = localZonesToDeleteCopy.lastObject;
                        if (!success) {
                            NSString *message = [NSString stringWithFormat:@"Error occured while deleting zone: %@", zone.name];
                            UIAlertView *errorAlertView = [[UIAlertView alloc] initWithTitle:@"Error" message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                            [errorAlertView show];
                            [weakSelf.tableView reloadData];
                            return;
                        }
                        [localZonesToDeleteCopy removeObject:zone];
                        [weakSelf.selectedZoneToDelete removeObject:zone];
                        NSIndexPath *indexPathToRemove = [NSIndexPath indexPathForRow:[self.dataZones indexOfObject:zone] inSection:0];
                        [weakSelf.dataZones removeObject:zone];
                        [weakSelf.tableView beginUpdates];
                        [weakSelf.tableView deleteRowsAtIndexPaths:@[indexPathToRemove] withRowAnimation:UITableViewRowAnimationFade];
                        [weakSelf.tableView endUpdates];
                        if (localZonesToDeleteCopy.lastObject != nil) {
                            [admin deleteZone:localZonesToDeleteCopy.lastObject completion:deleteZoneCompletion];
                        } else {
                            [weakSelf updateEmptyLabelVisbility];
                            [[BeaconCtrlManager sharedManager] refetchBeaconCtrlConfiguration:nil];
                        }
                    } else {
                        [[AlertControllerManager sharedManager] presentError:error inViewController:self completion:nil];
                    }
                });
                return;
            };
            [admin deleteZone:localZonesToDeleteCopy.lastObject completion:deleteZoneCompletion];
        }
    }];
    
    [alertController addAction:cancelAction];
    [alertController addAction:deleteAction];
    
    [self presentViewController:alertController animated:YES completion:nil];
}

- (IBAction) addZonePressed:(id)sender
{
    if (self.mode == kBCLZonesViewControllerSelect) {
        if ([self.delegate respondsToSelector:@selector(zonesViewController:didSelectedZone:)]) {
            [self.delegate zonesViewController:self didSelectedZone:self.selectedZone];
        }
    } else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Adding zone" message:@"Please enter a name for new zone:" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Add", nil];
        alert.alertViewStyle = UIAlertViewStylePlainTextInput;
        [alert show];
    }
}

#pragma mark - Actions

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if ( buttonIndex == 1 ) {
        NSString * zoneName = [[alertView textFieldAtIndex:0] text];
        BCLZone * zone = [BCLZone new];
        zone.name = zoneName;
        NSArray *colors = [BeaconCtrlManager sharedManager].beaconCtrlAdmin.zoneColors.copy;
        NSString  *colorString = (NSString *) colors[arc4random() % colors.count];
        zone.color = [UIColor colorFromHexString:colorString];
        BCLBeaconCtrlAdmin * admin = [BeaconCtrlManager sharedManager].beaconCtrlAdmin;
        [self showActivityIndicatorViewAnimated:YES];
        [admin createZone:zone completion:^(BCLZone *newZone, NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self hideActivityIndicatorViewAnimated:YES];
                if (!error) {
                    if (newZone == nil) {
                        NSString *message = [NSString stringWithFormat:@"Error occured while zone creation: %@", error.domain];
                        UIAlertView *errorAlertView = [[UIAlertView alloc] initWithTitle:@"Error" message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                        [errorAlertView show];
                        return;
                    }
                    [self.dataZones insertObject:newZone atIndex:0];
                    [self.tableView beginUpdates];
                    [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
                    [self.tableView endUpdates];
                    [self updateEmptyLabelVisbility];
                    [[BeaconCtrlManager sharedManager] refetchBeaconCtrlConfiguration:nil];
                } else {
                    [[AlertControllerManager sharedManager] presentError:error inViewController:self completion:nil];
                }
            });
        }];
    }
}

#pragma mark - AKPickerViewDataSource & AKPickerViewDelegate

- (NSUInteger)numberOfItemsInPickerView:(AKPickerView *)pickerView
{    
    switch (self.mode) {
        case kBCLZonesViewControllerSelect:
            return [[NSUserDefaults standardUserDefaults] integerForKey:@"BCLRemoteAppMaxFloorNumber"] + 1;
            break;
        case kBCLZonesViewControllerEdit:
            return 100;
            break;
        default:
            break;
    }
}

- (NSString *)pickerView:(AKPickerView *)pickerView titleForItem:(NSInteger)item
{
    switch (self.mode) {
        case kBCLZonesViewControllerSelect:
        {
            if (item == 0) {
                return @"Unassigned";
            }
            
            return [NSString stringWithFormat:@"%lu", item];
            break;
        }
        case kBCLZonesViewControllerEdit:
        {
            return [NSString stringWithFormat:@"%lu", item + 1];
            break;
        }
        default:
            break;
    }
}

- (CGSize)pickerView:(AKPickerView *)pickerView marginForItem:(NSInteger)item
{
    return CGSizeMake(40, 0);
}

- (void)pickerView:(AKPickerView *)pickerView didSelectItem:(NSInteger)item
{
    switch (self.mode) {
        case kBCLZonesViewControllerSelect:
        {
            NSNumber *floorNumber;
            
            if (item > 0) {
                floorNumber = @(item);
            }
            
            if ([self.delegate respondsToSelector:@selector(zonesViewController:didSelectedFloor:)]) {
                [self.delegate zonesViewController:self didSelectedFloor:floorNumber];
            }
            break;
        }
        case kBCLZonesViewControllerEdit:
        {
            NSUserDefaults *stantardUserDefaults = [NSUserDefaults standardUserDefaults];
            
            [stantardUserDefaults setInteger:item + 1 forKey:@"BCLRemoteAppMaxFloorNumber"];
            [stantardUserDefaults synchronize];
            break;
        }
        default:
            break;
    }
}


@end
