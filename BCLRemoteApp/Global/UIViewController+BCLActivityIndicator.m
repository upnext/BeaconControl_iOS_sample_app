//
//  UIViewController+BCLActivityIndicator.m
//  BCLRemoteApp
//
// Copyright (c) 2015, Upnext Technologies Sp. z o.o.
// All rights reserved.
//
// This source code is licensed under the BSD 3-Clause License found in the
// LICENSE.txt file in the root directory of this source tree.
//

#import <objc/runtime.h>
#import "UIViewController+BCLActivityIndicator.h"

static char activityIndicatorViewKey;

@implementation UIViewController (BCLActivityIndicator)

- (UIView *)activityIndicatorView
{
    UIView *activityIndicatorView = objc_getAssociatedObject(self, &activityIndicatorViewKey);
    if (!activityIndicatorView) {
        activityIndicatorView = [[UIView alloc] initWithFrame:self.view.bounds];
        activityIndicatorView.alpha = 0.0;
        activityIndicatorView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
        activityIndicatorView.translatesAutoresizingMaskIntoConstraints = NO;
        NSDictionary *views = NSDictionaryOfVariableBindings(activityIndicatorView);
        [self.view addSubview:activityIndicatorView];
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[activityIndicatorView]|" options:0 metrics:nil views:views]];
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[activityIndicatorView]|" options:0 metrics:nil views:views]];

        UIActivityIndicatorView *activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        activityView.translatesAutoresizingMaskIntoConstraints = NO;
        [activityView startAnimating];
        [activityIndicatorView addSubview:activityView];
        [activityIndicatorView addConstraint:[NSLayoutConstraint constraintWithItem:activityView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:activityIndicatorView attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0.0]];
        [activityIndicatorView addConstraint:[NSLayoutConstraint constraintWithItem:activityView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:activityIndicatorView attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0.0]];
        objc_setAssociatedObject(self, &activityIndicatorViewKey, activityIndicatorView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }

    return activityIndicatorView;
}

- (void)showActivityIndicatorViewAnimated:(BOOL)animated
{
    [UIView animateWithDuration:animated?0.25:0.0 animations:^{
        self.activityIndicatorView.alpha = 1.0;
    }];
}

- (void)hideActivityIndicatorViewAnimated:(BOOL)animated
{
    [UIView animateWithDuration:animated?0.25:0.0 animations:^{
        self.activityIndicatorView.alpha = 0.0;
    }];
}

@end
