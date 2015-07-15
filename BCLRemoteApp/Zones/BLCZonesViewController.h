//
//  BCLZonesViewController.h
//  BCLRemoteApp
//
// Copyright (c) 2015, Upnext Technologies Sp. z o.o.
// All rights reserved.
//
// This source code is licensed under the BSD 3-Clause License found in the
// LICENSE.txt file in the root directory of this source tree.
//

#import <UIKit/UIKit.h>
#import "BCLZone.h"

typedef NS_ENUM(NSInteger, BCLZonesViewControllerMode)
{
    kBCLZonesViewControllerSelect = 0,
    kBCLZonesViewControllerEdit
};

@class BLCZonesViewController;

@protocol BCLZonesViewControllerDelegate <NSObject>

- (void) zonesViewController:(BLCZonesViewController*)viewController didSelectedZone:(BCLZone*)zone;
- (void) zonesViewController:(BLCZonesViewController*)viewController didSelectedFloor:(NSNumber *)floorNumber;

@end

@interface BLCZonesViewController : UIViewController

@property (nonatomic, weak) id<BCLZonesViewControllerDelegate> delegate;

+ (instancetype)newZonesViewController;

- (void) setMode:(BCLZonesViewControllerMode)mode initialZoneSelection:(BCLZone*)initialSelection floorSelection:(NSNumber *)floorSelection;

@end
