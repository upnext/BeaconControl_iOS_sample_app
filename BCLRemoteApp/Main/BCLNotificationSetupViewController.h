//
//  BCLNotificationSetupViewController.h
//  BCLRemoteApp
//
// Copyright (c) 2015, Upnext Technologies Sp. z o.o.
// All rights reserved.
//
// This source code is licensed under the BSD 3-Clause License found in the
// LICENSE.txt file in the root directory of this source tree.
//

#import <UIKit/UIKit.h>
#import <BeaconCtrl/BCLTypes.h>

@class BCLNotificationSetupViewController;

@protocol BCLNotificationSetupViewControllerDelegate <NSObject>
@optional
- (void) notificationSetupViewController:(BCLNotificationSetupViewController *)controller didSetupNotificationMessage:(NSString *)message trigger:(BCLEventType)trigger;
@end

@interface BCLNotificationSetupViewController : UIViewController
@property (nonatomic, strong) NSString *notificationMessage;
@property (nonatomic) BCLEventType chosenTrigger;
@property (nonatomic, weak) id <BCLNotificationSetupViewControllerDelegate> delegate;
@end
