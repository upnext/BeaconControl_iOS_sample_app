//
//  BCLBeaconDetailsViewController.m
//  BCLRemoteApp
//
// Copyright (c) 2015, Upnext Technologies Sp. z o.o.
// All rights reserved.
//
// This source code is licensed under the BSD 3-Clause License found in the
// LICENSE.txt file in the root directory of this source tree.
//

#import <BeaconCtrl/BCLBeacon.h>
#import <BeaconCtrl/BCLLocation.h>
#import <BeaconCtrl/BCLZone.h>
#import <BeaconCtrl/BCLTrigger.h>
#import <BeaconCtrl/BCLConditionEvent.h>
#import "BCLBeaconDetailsViewController.h"
#import "TPKeyboardAvoidingScrollView.h"
#import "BeaconCtrlManager.h"
#import "UIColor+BCLAppColors.h"
#import "AlertControllerManager.h"
#import "UIViewController+BCLActivityIndicator.h"
#import "BCLUUIDTextFieldFormatter.h"
#import "UIViewController+BCLBannerMessages.h"

@interface BCLBeaconDetailsViewController () <UIAlertViewDelegate,  UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet UILabel *beaconNameLabel;
@property (weak, nonatomic) IBOutlet UITextField *beaconNameTextField;
@property (weak, nonatomic) IBOutlet UITextField *uuidTextField;
@property (weak, nonatomic) IBOutlet UITextField *minorTextField;
@property (weak, nonatomic) IBOutlet UITextField *majorTextField;
@property (weak, nonatomic) IBOutlet UITextField *latitudeTextField;
@property (weak, nonatomic) IBOutlet UITextField *longitudeTextField;
@property (weak, nonatomic) IBOutlet TPKeyboardAvoidingScrollView *scrollView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *contentViewHeightConstraint;
@property (weak, nonatomic) IBOutlet UIView *zoneColorBadge;
@property (weak, nonatomic) IBOutlet UILabel *zoneNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *floorTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *floorNumberLabel;
@property (weak, nonatomic) IBOutlet UIView *zoneButtonBadge;
@property (weak, nonatomic) IBOutlet UILabel *zoneButtonTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *zoneButtonFloorLabel;
@property (weak, nonatomic) IBOutlet UILabel *notificationMessageLabel;
@property (weak, nonatomic) IBOutlet UIButton *confirmButton;
@property (weak, nonatomic) IBOutlet UIButton *zoneButton;
@property (weak, nonatomic) IBOutlet UIButton *notificationsButton;
@property (weak, nonatomic) IBOutlet UIImageView *zonesDisclosureIndicatorImage;
@property (weak, nonatomic) IBOutlet UIImageView *notificationsDisclosureIndicatorImage;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *barButton;

@property (nonatomic) NSNumber *selectedFloor;
@property (nonatomic) NSString *notificationMessage;
@property (nonatomic) BCLEventType selectedTrigger;

@property (nonatomic) NSArray *editableTextFieldsBackgrounds;

@property(nonatomic, strong) BCLUUIDTextFieldFormatter *uuidFormatter;
@end

static const NSUInteger BCLEditableTextFieldBGTag = 23;

@implementation BCLBeaconDetailsViewController

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - UIViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self updateView];
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
    if ([UIScreen mainScreen].bounds.size.height < 667.0) {
        [self decreaseFontSize];
    }

    //beacon and zone listeners
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(closestBeaconDidChange:) name:BeaconManagerClosestBeaconDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(currentZoneDidChange:) name:BeaconManagerCurrentZoneDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(propertiesUpdateDidStart:) name:BeaconManagerPropertiesUpdateDidStartNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(propertiesUpdateDidEnd:) name:BeaconManagerPropertiesUpdateDidFinishNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(firmwareUpdateDidStart:) name:BeaconManagerFirmwareUpdateDidStartNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(firmwareUpdateDidProgress:) name:BeaconManagerFirmwareUpdateDidProgressNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(firmwareUpdateDidEnd:) name:BeaconManagerFirmwareUpdateDidFinishNotification object:nil];
    
    self.uuidFormatter = [BCLUUIDTextFieldFormatter new];
    self.uuidFormatter.textField = self.uuidTextField;

    [self setEditingEnabled:NO];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (self.beacon) {
        [self showUpdateMessages:NO];
    } else {
        [self hideUpdateMessages:NO];
    }
    
}

- (void)decreaseFontSize
{
    [self decreaseFontSize:self.scrollView];
}

- (void)decreaseFontSize:(UIView *)mainView
{
    for (UIView *view in mainView.subviews) {
        if ([view isKindOfClass:[UITextField class]]) {
            UITextField *textField = (UITextField *)view;
            if (textField != self.beaconNameTextField) {
                textField.font = [textField.font fontWithSize:textField.font.pointSize - 3];
            }
        }

        if ([view isKindOfClass:[UILabel class]]) {
            UILabel *label = (UILabel *)view;
            if (label != self.beaconNameLabel) {
                label.font = [label.font fontWithSize:label.font.pointSize - 3];
            }
        }


        [self decreaseFontSize:view];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self resetFormValidation];
    if ([self.navigationController.viewControllers indexOfObject:self]==NSNotFound) {
        if (self.beaconMode == kBCLBeaconModeNew) {
            [self updateBeaconData];
        } else {
            [self updateView];
        }
        
        [self.scrollView setContentInset:UIEdgeInsetsZero];
        [self.scrollView setContentOffset:CGPointMake(0, 0) animated:YES];
    }
    
    [super viewWillDisappear:animated];
    
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    if ([UIScreen mainScreen].bounds.size.height > 480) {
        self.contentViewHeightConstraint.constant = self.scrollView.frame.size.height;
    } else {
        self.contentViewHeightConstraint.constant = 504.0;
    }

    self.zoneButtonBadge.layer.cornerRadius = self.zoneButtonBadge.layer.frame.size.width/2;
    self.zoneColorBadge.layer.cornerRadius = self.zoneColorBadge.layer.frame.size.width/2;

}

#pragma mark - Private

- (void)currentZoneDidChange:(NSNotification *)notification
{
    if (self.beaconMode == kBCLBeaconModeHidden) {
        self.selectedZone = [BeaconCtrlManager sharedManager].beaconCtrl.currentZone;
    }
}

- (void)propertiesUpdateDidStart:(NSNotification *)notification
{
    if (![[notification.userInfo[@"beacon"] beaconIdentifier] isEqualToString:self.beacon.beaconIdentifier]) {
        return;
    }
    
    [self showUpdateMessage:@"Updating properties..." warning:YES];
}

- (void)propertiesUpdateDidEnd:(NSNotification *)notification
{
    if (![[notification.userInfo[@"beacon"] beaconIdentifier] isEqualToString:self.beacon.beaconIdentifier]) {
        return;
    }
    
    [self showUpdateMessage:@"Properties succesfully updated!" warning:NO];
}

- (void)firmwareUpdateDidStart:(NSNotification *)notification
{
    if (![[notification.userInfo[@"beacon"] beaconIdentifier] isEqualToString:self.beacon.beaconIdentifier]) {
        return;
    }
    
    [self showUpdateMessage:@"Updating firmware..." warning:YES];
}

- (void)firmwareUpdateDidProgress:(NSNotification *)notification
{
    if (![[notification.userInfo[@"beacon"] beaconIdentifier] isEqualToString:self.beacon.beaconIdentifier]) {
        return;
    }
    
    [self showUpdateMessage:[NSString stringWithFormat:@"Firwmare update progress: %@%%", notification.userInfo[@"progress"]] warning:YES];
}

- (void)firmwareUpdateDidEnd:(NSNotification *)notification
{
    if (![[notification.userInfo[@"beacon"] beaconIdentifier] isEqualToString:self.beacon.beaconIdentifier]) {
        return;
    }
    
    [self showUpdateMessage:@"Successfully updated firmware!" warning:NO];
}

- (void)showUpdateMessage:(NSString *)message warning:(BOOL)isWarning
{
    UIViewController *topViewController = self.navigationController.topViewController;
    
    [topViewController presentMessage:message animated:NO warning:isWarning completion:nil];
}

- (void)closestBeaconDidChange:(NSNotification *)notification
{
    if (self.beaconMode == kBCLBeaconModeHidden) {
        BCLBeacon *candidate = [BeaconCtrlManager sharedManager].beaconCtrl.closestBeacon;
        self.floorNumberLabel.text = candidate ? candidate.name : @"No beacon in range";
    }
}

- (IBAction)confirmButtonPressed:(id)sender
{
    __weak BCLBeaconDetailsViewController *weakSelf = self;

    switch (self.beaconMode) {

        case kBCLBeaconModeNew:
        {
            if (![self validateForm]) {
                break;
            }
            [self updateBeaconData];
            [self showActivityIndicatorViewAnimated:YES];
            
            NSString *testActionName;
            NSArray *testActionAttributes;
            
            if (self.notificationMessage) {
                testActionName = @"Test action";
                testActionAttributes = @[@{@"name": @"text", @"value": self.notificationMessage}];
            }
            
            [self.bclManager createBeacon:self.beacon testActionName:testActionName testActionTrigger:self.selectedTrigger testActionAttributes:testActionAttributes completion:^(BCLBeacon *newBeacon, NSError *error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (!error) {
                        weakSelf.beacon = newBeacon;
                        if ([weakSelf.delegate respondsToSelector:@selector(beaconDetailsViewController:didSaveNewBeacon:)]) {
                            [weakSelf.delegate beaconDetailsViewController:self didSaveNewBeacon:newBeacon];
                        }
                    } else {
                        [[AlertControllerManager sharedManager] presentError:error inViewController:self completion:nil];
                    }
                    [weakSelf hideActivityIndicatorViewAnimated:YES];
                });
            }];
        };
            break;

        case kBCLBeaconModeEdit:
        {
            if (![self validateForm]) {
                break;
            }

            BCLBeacon *beaconCopy = [self.beacon copy];
            [self updateBeaconData:beaconCopy];
            [self showActivityIndicatorViewAnimated:YES];
            
            NSString *testActionName;
            NSMutableArray *testActionAttributes;
            
            if (self.notificationMessage) {
                testActionName = @"Test action";
                BCLAction *testAction = [[BeaconCtrlManager sharedManager] testActionForBeacon:self.beacon];
                if (testAction) {
                    testActionAttributes = [@[] mutableCopy];
                    [testAction.customValues enumerateObjectsUsingBlock:^(NSDictionary *valueDict, NSUInteger idx, BOOL *stop) {
                        [testActionAttributes addObject:@{@"name": valueDict[@"name"], @"value": [valueDict[@"name"] isEqualToString:@"text"] ? self.notificationMessage : valueDict[@"value"], @"id": valueDict[@"id"]}];
                    }];
                } else {
                    testActionAttributes = [@[@{@"name": @"text", @"value": self.notificationMessage}] mutableCopy];
                }
            }
            
            [self.bclManager updateBeacon:beaconCopy testActionName:testActionName testActionTrigger:self.selectedTrigger testActionAttributes:testActionAttributes.copy completion:^(BCLBeacon *updatedBeacon, NSError *error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (!error) {
                        weakSelf.beacon = updatedBeacon;
                        if ([weakSelf.delegate respondsToSelector:@selector(beaconDetailsViewController:didEditBeacon:)]) {
                            [weakSelf.delegate beaconDetailsViewController:self didEditBeacon:updatedBeacon];
                        }
                    } else {
                        [[AlertControllerManager sharedManager] presentError:error inViewController:self completion:nil];
                    }
                    [self hideActivityIndicatorViewAnimated:YES];
                });
            }];
        };
            break;

        case kBCLBeaconModeDetails:
        {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil message:@"Are you sure you want to delete this beacon?" delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil];
            [alertView show];
        };
            break;
        default:
            break;
    }
}

- (BOOL)validateForm
{
    [self resetFormValidation];

    NSString *name = [self.beaconNameTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (!name || [name isEqualToString:@""]) {
        [self presentValidationError:@"Name can't be blank!"];
        self.beaconNameTextField.layer.borderColor = [UIColor redAppColor].CGColor;
        self.beaconNameTextField.layer.borderWidth = 1.0;
        return NO;
    }

    NSString *uuid = [self.uuidTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (!uuid || [uuid isEqualToString:@""]) {
        [self presentValidationError:@"UUID can't be blank!"];
        self.uuidTextField.superview.layer.borderColor = [UIColor redAppColor].CGColor;
        self.uuidTextField.superview.layer.borderWidth = 1.0;
        return NO;
    }

    if (![self.uuidFormatter isValid]) {
        [self presentValidationError:@"Invalid UUID"];
        self.uuidTextField.superview.layer.borderColor = [UIColor redAppColor].CGColor;
        self.uuidTextField.superview.layer.borderWidth = 1.0;
        return NO;
    }

    NSString *major = [self.majorTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (!major || [major isEqualToString:@""]) {
        [self presentValidationError:@"Major can't be blank!"];
        self.majorTextField.superview.layer.borderColor = [UIColor redAppColor].CGColor;
        self.majorTextField.superview.layer.borderWidth = 1.0;
        return NO;
    }

    NSString *minor = [self.minorTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (!minor || [minor isEqualToString:@""]) {
        [self presentValidationError:@"Minor can't be blank!"];
        self.minorTextField.superview.layer.borderColor = [UIColor redAppColor].CGColor;
        self.minorTextField.superview.layer.borderWidth = 1.0;
        return NO;
    }


    return YES;
}

- (void)presentValidationError:(NSString *)errorMessage
{
    self.confirmButton.enabled = NO;
    [self presentValidationError:errorMessage completion:^(BOOL finished) {
        self.confirmButton.enabled = YES;
    }];
}

- (void)resetFormValidation
{
    [self hideBannerView:NO];
    self.beaconNameTextField.layer.borderWidth = 0;
    self.uuidTextField.superview.layer.borderWidth = 0;
    self.majorTextField.superview.layer.borderWidth = 0;
    self.minorTextField.superview.layer.borderWidth = 0;
    self.latitudeTextField.superview.layer.borderWidth = 0;
    self.longitudeTextField.superview.layer.borderWidth = 0;
}

- (IBAction)barButtonPressed:(id)sender
{
    switch (self.beaconMode) {
        case kBCLBeaconModeNew:
            break;
        case kBCLBeaconModeEdit:
            //cancel
            [self updateView];
            self.beaconMode = kBCLBeaconModeDetails;
            break;
        case kBCLBeaconModeDetails:
            //edit
            self.beaconMode = kBCLBeaconModeEdit;
            break;
        case kBCLBeaconModeHidden:
            break;
    }
}

- (IBAction)zoneButtonPressed:(id)sender
{

    BLCZonesViewController *zonesViewController = [BLCZonesViewController newZonesViewController];
    [zonesViewController setMode:kBCLZonesViewControllerSelect initialZoneSelection:self.selectedZone floorSelection:self.selectedFloor];
    zonesViewController.delegate = self;

    [self.navigationController pushViewController:zonesViewController animated:YES];
}

- (void)updateBeaconData:(BCLBeacon *)beacon
{
    beacon.name = [self isEmptyString:self.beaconNameTextField.text] ? nil : self.beaconNameTextField.text;
    beacon.proximityUUID = [self isEmptyString:self.uuidTextField.text] ? nil : [[NSUUID alloc] initWithUUIDString:self.uuidTextField.text];
    beacon.minor = [self isEmptyString:self.minorTextField.text] ? nil : @([self.minorTextField.text floatValue]);
    beacon.major = [self isEmptyString:self.majorTextField.text] ? nil : @([self.majorTextField.text floatValue]);
    beacon.location = [[BCLLocation alloc] initWithLocation:[[CLLocation alloc] initWithLatitude:[self.latitudeTextField.text floatValue] longitude:[self.longitudeTextField.text floatValue]] floor:self.selectedFloor];
    [beacon.zone.beacons removeObject:self.beacon];
    beacon.zone = self.selectedZone;
    [beacon.zone.beacons addObject:self.beacon];
}

- (void)updateBeaconData
{
    [self updateBeaconData:self.beacon];
}

- (BOOL)isEmptyString:(NSString *)text
{
    NSString *trimmedText = [text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    return (!text || [trimmedText isEqualToString:@""]);
}

- (void)updateView
{
    [self resetFormValidation];
    self.beaconNameTextField.text = self.beacon.name;
    self.uuidTextField.text = self.beacon.proximityUUID.UUIDString;
    self.minorTextField.text = [self.beacon.minor stringValue];
    self.majorTextField.text = [self.beacon.major stringValue];
    self.latitudeTextField.text = [NSString stringWithFormat:@"%f", self.beacon.location.location.coordinate.latitude];
    self.longitudeTextField.text = [NSString stringWithFormat:@"%f", self.beacon.location.location.coordinate.longitude];
    self.selectedZone = self.beacon.zone;
    self.selectedTrigger = BCLEventTypeEnter;

    NSString *notificationMessage;
    BCLAction *testAction = [[BeaconCtrlManager sharedManager] testActionForBeacon:self.beacon];
    if (testAction) {
        notificationMessage = [testAction.customValues firstObject][@"value"];
        self.selectedTrigger = [self triggerFromName:[((BCLConditionEvent *)testAction.trigger.conditions.firstObject) eventType]];
    }
    self.notificationMessage = notificationMessage;

    self.selectedFloor = self.beacon.location.floor;
}

- (BCLEventType)triggerFromName:(NSString *)triggerName
{
    if ([triggerName isEqualToString:@"enter"]) {
        return BCLEventTypeEnter;
    } else if ([triggerName isEqualToString:@"leave"]) {
        return BCLEventTypeLeave;
    } else if ([triggerName isEqualToString:@"immediate"]) {
        return BCLEventTypeRangeImmediate;
    } else if ([triggerName isEqualToString:@"near"]) {
        return BCLEventTypeRangeNear;
    } else if ([triggerName isEqualToString:@"far"]) {
        return BCLEventTypeRangeFar;
    }
    
    return BCLEventTypeUnknown;
}

- (void)showUpdateMessages:(BOOL)animated
{
    if (self.beacon) {
        UIViewController *topViewController = self.navigationController.topViewController;
        
        if (self.beacon.characteristicsAreBeingUpdated) {
            [topViewController presentMessage:@"Updating beacon's properties..." animated:animated warning:YES completion:nil];
        } else if (self.beacon.needsCharacteristicsUpdate) {
            [topViewController presentMessage:@"This beacon needs to have its properties updated. Move closer to it and wait for a while" animated:animated warning:YES completion:nil];
        } else if (self.beacon.needsFirmwareUpdate) {
            [topViewController presentMessage:@"This beacon needs to have its firmware updated. Move closer to it and wait for a while" animated:animated warning:YES completion:nil];
        } else if (self.beacon.firmwareUpdateProgress > 0 && self.beacon.firmwareUpdateProgress != NSNotFound) {
            [topViewController presentMessage:@"This beacon's firmware is being updated" animated:animated warning:YES completion:nil];
        } else {
            [self hideUpdateMessages:YES];
        }
    }
}

- (void)hideUpdateMessages:(BOOL)animated
{
    UIViewController *topViewController = self.navigationController.topViewController;
    
    [topViewController hideBannerView:animated];
}

#pragma mark - Accessors

- (void)setBeacon:(BCLBeacon *)beacon
{
    _beacon = beacon;
    [self updateView];
    
    if (beacon) {
        [self showUpdateMessages:YES];
    } else {
        [self hideUpdateMessages:YES];
    }
}

- (void)setNotificationMessage:(NSString *)notificationMessage
{
    _notificationMessage = notificationMessage;
    self.notificationMessageLabel.text = notificationMessage;
}

- (void)setSelectedZone:(BCLZone *)zone
{
    _selectedZone = zone;
    NSString *zoneName = zone.name?:@"Unassigned";
    UIColor *zoneColor = zone.color?:[UIColor colorWithRed:0.38 green:0.73 blue:0.91 alpha:1];

    self.zoneColorBadge.backgroundColor = zoneColor;
    self.zoneButtonBadge.backgroundColor = zoneColor;
    self.zoneNameLabel.text = zoneName;
    self.zoneButtonTitleLabel.text = zoneName;
}

- (void)setSelectedFloor:(NSNumber *)selectedFloor
{
    _selectedFloor = selectedFloor;
    self.zoneButtonFloorLabel.text = [NSString stringWithFormat:@"%@", selectedFloor ? : @"None"];
}

- (void)setBeaconMode:(BCLBeaconDetailsMode)beaconMode
{
    _beaconMode = beaconMode;
    switch (beaconMode) {
        case kBCLBeaconModeNew:
            self.floorTitleLabel.text = @"Floor:";
            self.floorNumberLabel.text = [NSString stringWithFormat:@"%@", self.beacon.location.floor ? : @"None"];
            self.navigationItem.rightBarButtonItem = nil;
            [self.confirmButton setTitle:@"Save beacon" forState:UIControlStateNormal];
            self.confirmButton.backgroundColor = [UIColor blueAppColor];
            [self setEditingEnabled:YES];
            break;
        case kBCLBeaconModeEdit:
            self.floorTitleLabel.text = @"Floor:";
            self.floorNumberLabel.text = [NSString stringWithFormat:@"%@", self.beacon.location.floor ? : @"None"];
            self.navigationItem.rightBarButtonItem = self.barButton;
            self.barButton.title = @"Cancel";
            [self.confirmButton setTitle:@"Save beacon" forState:UIControlStateNormal];
            self.confirmButton.backgroundColor = [UIColor blueAppColor];
            [self setEditingEnabled:YES];
            break;
        case kBCLBeaconModeDetails:
            self.floorTitleLabel.text = @"Floor:";
            self.floorNumberLabel.text = [NSString stringWithFormat:@"%@", self.beacon.location.floor ? : @"None"];
            self.navigationItem.rightBarButtonItem = self.barButton;
            self.barButton.title = @"Edit";
            [self.confirmButton setTitle:@"Delete beacon" forState:UIControlStateNormal];
            self.confirmButton.backgroundColor = [UIColor redAppColor];
            [self setEditingEnabled:NO];
            break;
        case kBCLBeaconModeHidden:
            self.floorTitleLabel.text = @"Beacon:";
            self.floorNumberLabel.text = [BeaconCtrlManager sharedManager].beaconCtrl.closestBeacon.name ? : @"No beacon in range";
            self.selectedZone = [BeaconCtrlManager sharedManager].beaconCtrl.currentZone;
            break;
    }
}

- (void)setEditingEnabled:(BOOL)enabled
{
    [self setEditingEnabled:enabled animated:NO];
}

- (void)setEditingEnabled:(BOOL)enabled animated:(BOOL)animated
{
    self.zonesDisclosureIndicatorImage.hidden = !enabled;
    self.notificationsDisclosureIndicatorImage.hidden = !enabled;
    self.minorTextField.enabled = enabled;
    self.beaconNameTextField.enabled = enabled;
    self.latitudeTextField.enabled = enabled;
    self.longitudeTextField.enabled = enabled;
    self.majorTextField.enabled = enabled;
    self.uuidTextField.enabled = enabled;
    self.zoneButton.userInteractionEnabled = enabled;
    self.notificationsButton.userInteractionEnabled = enabled;
    [self setEditableTextFieldBackgroundsVisible:enabled animated:animated];
}

- (void)setEditableTextFieldBackgroundsVisible:(BOOL)visible
{
    [self setEditableTextFieldBackgroundsVisible:visible animated:NO];
}

- (void)setEditableTextFieldBackgroundsVisible:(BOOL)visible animated:(BOOL)animated
{
    for (UIView *view in self.editableTextFieldsBackgrounds) {
        [UIView animateWithDuration:animated ? 0.5 : 0.0 animations:^{
            view.backgroundColor = [view.backgroundColor colorWithAlphaComponent:visible];
        }];
    }
}

- (NSArray *)editableTextFieldsBackgrounds
{
    if (!_editableTextFieldsBackgrounds) {
        NSMutableArray *mutableArray = [NSMutableArray new];
        [self.scrollView.subviews[0].subviews enumerateObjectsUsingBlock:^(UIView * view, NSUInteger idx, BOOL *stop) {
            if (view.tag == BCLEditableTextFieldBGTag) {
                [mutableArray addObject:view];
            }
        }];

        _editableTextFieldsBackgrounds = [mutableArray copy];
    }

    return _editableTextFieldsBackgrounds;
}

- (BeaconCtrlManager *)bclManager
{
    return [BeaconCtrlManager sharedManager];
}

#pragma mark - Zones View Controller Delegate

- (void)zonesViewController:(BLCZonesViewController *)viewController didSelectedZone:(BCLZone *)zone
{
    self.selectedZone = zone;
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)zonesViewController:(BLCZonesViewController *)viewController didSelectedFloor:(NSNumber *)floorNumber
{
    self.selectedFloor = floorNumber;
}

#pragma mark - UITextField delegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField == self.uuidTextField) {
        [self.majorTextField becomeFirstResponder];
    } else if (textField == self.minorTextField) {
        [self.latitudeTextField becomeFirstResponder];
    } else if (textField == self.longitudeTextField) {
        [textField resignFirstResponder];
    }
    return NO;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    if (textField == self.uuidTextField) {
        return [self.uuidFormatter textField:textField shouldChangeCharactersInRange:range replacementString:string];
    }
    return YES;
}

#pragma mark - UIAlertView delegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    __weak BCLBeaconDetailsViewController *weakSelf = self;
    if (buttonIndex == 1) {
        [self showActivityIndicatorViewAnimated:YES];
        [self.bclManager deleteBeacon:self.beacon completion:^(BOOL success, NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (success) {
                    if ([weakSelf.delegate respondsToSelector:@selector(beaconDetailsViewController:didDeleteBeacon:)]) {
                        [weakSelf.delegate beaconDetailsViewController:self didDeleteBeacon:weakSelf.beacon];
                    }
                } else {
                    [[AlertControllerManager sharedManager] presentError:error inViewController:self completion:nil];
                }
                [self hideActivityIndicatorViewAnimated:YES];
            });
        }];
    }
}

#pragma mark - BCLNotificationSetupViewController Delegate

- (void)notificationSetupViewController:(BCLNotificationSetupViewController *)controller didSetupNotificationMessage:(NSString *)message trigger:(BCLEventType)trigger
{
    [self.navigationController popViewControllerAnimated:YES];
    self.notificationMessage = message;
    self.selectedTrigger = trigger;
}


#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.destinationViewController isKindOfClass:[BCLNotificationSetupViewController class]]) {
        BCLNotificationSetupViewController *viewController = (segue.destinationViewController);
        viewController.delegate = self;
        viewController.notificationMessage = self.notificationMessage;
        viewController.chosenTrigger = self.selectedTrigger;
    }
}

@end
