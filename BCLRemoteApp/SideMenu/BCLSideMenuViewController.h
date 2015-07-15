//
//  BCLSideMenuViewController.h
//  BCLRemoteApp
//
// Copyright (c) 2015, Upnext Technologies Sp. z o.o.
// All rights reserved.
//
// This source code is licensed under the BSD 3-Clause License found in the
// LICENSE.txt file in the root directory of this source tree.
//

#import <UIKit/UIKit.h>

@class BCLSideMenuViewController;

@protocol BCLSideMenuViewControllerDelegate <NSObject>
@optional
- (void)sideMenuViewController:(BCLSideMenuViewController *)controller didChangeSelection:(NSArray *)selection showsNoneZone:(BOOL)showsNone;
- (void)sideMenuViewController:(BCLSideMenuViewController *)controller didSelectFloorNumber:(NSNumber *)floorNumber;
- (void) didSelectLogout:(BCLSideMenuViewController*)controller;
@end

@interface BCLSideMenuViewController : UIViewController

@property (nonatomic, weak) id<BCLSideMenuViewControllerDelegate> delegate;

@property(nonatomic) BOOL showsNoneZone;
@end
