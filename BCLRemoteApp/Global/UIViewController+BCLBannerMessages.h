//
//  UIViewController+BCLValidationErrors.h
//  BCLRemoteApp
//
// Copyright (c) 2015, Upnext Technologies Sp. z o.o.
// All rights reserved.
//
// This source code is licensed under the BSD 3-Clause License found in the
// LICENSE.txt file in the root directory of this source tree.
//

#import <UIKit/UIKit.h>

extern NSString *const BCLBannerViewWillHideNotification;

@interface UIViewController (BCLBannerMessages)

- (void)presentValidationError:(NSString *)errorMessage completion:(void(^)(BOOL))completion;

- (void)presentMessage:(NSString *)message animated:(BOOL)animated warning:(BOOL)isWarning completion:(void(^)(BOOL))completion;

- (void)hideBannerView:(BOOL)animated;

- (UIView *)bannerView;

@end
