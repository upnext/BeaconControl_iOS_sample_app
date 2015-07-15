//
//  BCLBeaconDetailsViewController.h
//  BCLRemoteApp
//
// Copyright (c) 2015, Upnext Technologies Sp. z o.o.
// All rights reserved.
//
// This source code is licensed under the BSD 3-Clause License found in the
// LICENSE.txt file in the root directory of this source tree.
//

#import <UIKit/UIKit.h>
#import "BLCZonesViewController.h"
#import "BCLNotificationSetupViewController.h"

typedef NS_ENUM(NSInteger, BCLBeaconDetailsMode)
{
    kBCLBeaconModeNew = 0,
    kBCLBeaconModeEdit,
    kBCLBeaconModeDetails,
    kBCLBeaconModeHidden
};

@class BCLBeaconDetailsViewController;
@class BCLBeacon;
@class BCLUUIDTextFieldFormatter;

@protocol BCLBeaconDetailsViewControllerDelegate <NSObject>
@optional
- (void)beaconDetailsViewController:(BCLBeaconDetailsViewController *)viewController didSaveNewBeacon:(BCLBeacon *)beacon;
- (void)beaconDetailsViewController:(BCLBeaconDetailsViewController *)viewController didEditBeacon:(BCLBeacon *)beacon;
- (void)beaconDetailsViewController:(BCLBeaconDetailsViewController *)controller didDeleteBeacon:(BCLBeacon *)beacon;
@end

@interface BCLBeaconDetailsViewController : UIViewController <BCLZonesViewControllerDelegate, BCLNotificationSetupViewControllerDelegate>
@property (nonatomic, strong) BCLBeacon *beacon;
@property (nonatomic, weak) id <BCLBeaconDetailsViewControllerDelegate> delegate;
@property (nonatomic) BCLBeaconDetailsMode beaconMode;
@property (nonatomic, strong) BCLZone *selectedZone;

- (void)updateView;
@end
