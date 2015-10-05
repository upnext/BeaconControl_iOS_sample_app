//
//  BCLVendorChoiceViewController.h
//  BCLRemoteApp
//
// Copyright (c) 2015, Upnext Technologies Sp. z o.o.
// All rights reserved.
//
// This source code is licensed under the BSD 3-Clause License found in the
// LICENSE.txt file in the root directory of this source tree.
//

#import <UIKit/UIKit.h>

@class BCLVendorChoiceViewController;

@protocol BCLVendorChoiceViewControllerDelegate <NSObject>

@optional

- (void)vendorChoiceViewControllerDidCancel:(BCLVendorChoiceViewController *)viewController;
- (void)vendorChoiceViewController:(BCLVendorChoiceViewController *)viewController didChooseVendor:(NSString *)vendror;

@end

@interface BCLVendorChoiceViewController : UIViewController

@property (nonatomic, copy) NSString *selectedVendor;
@property (nonatomic, weak) id <BCLVendorChoiceViewControllerDelegate> delegate;

@end
