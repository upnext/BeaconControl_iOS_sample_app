//
//  UIViewController+BCLValidationErrors.m
//  BCLRemoteApp
//
// Copyright (c) 2015, Upnext Technologies Sp. z o.o.
// All rights reserved.
//
// This source code is licensed under the BSD 3-Clause License found in the
// LICENSE.txt file in the root directory of this source tree.
//

#import <objc/runtime.h>
#import "UIViewController+BCLValidationErrors.h"
#import "UIColor+BCLAppColors.h"

static char validationErrorViewKey;
static char topConstraintKey;
static char errorLabelKey;

@implementation UIViewController (BCLValidationErrors)

- (void)presentValidationError:(NSString *)errorMessage completion:(void(^)(BOOL))completion
{
    if (self.validationErrorView) {
        self.errorViewLabel.text = errorMessage;
        [self showErrorViewAnimated:YES completion:^(BOOL finished) {
            [self performSelector:@selector(hideAnimation:) withObject:completion afterDelay:2.0];
        }];
    }
}

- (void)showErrorViewAnimated:(BOOL)animated completion:(void(^)(BOOL))completion
{
    self.validationErrorView.hidden = NO;
    [UIView animateWithDuration:animated?0.5:0.0 animations:^{
        self.errorViewTopConstraint.constant = 0.0;
        [self.view layoutIfNeeded];
    } completion:completion];
}

- (void)hideErrorViewAnimated:(BOOL)animated completion:(void(^)(BOOL))completion
{
    if (!animated) {
        self.errorViewTopConstraint.constant = -35;
        self.validationErrorView.hidden = YES;
        return;
    }

    [UIView animateWithDuration:0.5 animations:^{
        self.errorViewTopConstraint.constant = -35;
        [self.view layoutIfNeeded];
    } completion:^(BOOL finished) {
        self.validationErrorView.hidden = YES;
        if (completion) {
            completion(finished);
        }
    }];
}

- (void)hideErrorView
{
    [self hideErrorViewAnimated:NO completion:nil];
}

- (void)hideAnimation:(void(^)(BOOL))completion
{
    [self hideErrorViewAnimated:YES completion:completion];
}

- (UIView *)validationErrorView
{
    UIView *validationErrorView = objc_getAssociatedObject(self, &validationErrorViewKey);
    if (!validationErrorView) {
        validationErrorView = [[UIView alloc] initWithFrame:CGRectZero];
        validationErrorView.backgroundColor = [UIColor redAppColor];
        validationErrorView.translatesAutoresizingMaskIntoConstraints = NO;
        NSDictionary *views = NSDictionaryOfVariableBindings(validationErrorView);
        [self.view addSubview:validationErrorView];
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[validationErrorView]|" options:0 metrics:nil views:views]];
        NSLayoutConstraint *topConstraint =  [NSLayoutConstraint constraintWithItem:validationErrorView
                                     attribute:NSLayoutAttributeTop
                                     relatedBy:NSLayoutRelationEqual
                                        toItem:self.topLayoutGuide
                                     attribute:NSLayoutAttributeBottom
                                    multiplier:1.0
                                      constant:-35];
        [self.view addConstraint:topConstraint];

        [validationErrorView addConstraint:[NSLayoutConstraint constraintWithItem:validationErrorView
                                                                        attribute:NSLayoutAttributeHeight
                                                                        relatedBy:NSLayoutRelationEqual
                                                                           toItem:nil
                                                                        attribute:NSLayoutAttributeNotAnAttribute
                                                                       multiplier:1.0
                                                                         constant:35.0]];



        UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
        label.translatesAutoresizingMaskIntoConstraints = NO;
        label.textColor = [UIColor whiteColor];
        [validationErrorView addSubview:label];
        [validationErrorView addConstraint:[NSLayoutConstraint constraintWithItem:label
                                                                        attribute:NSLayoutAttributeCenterY
                                                                        relatedBy:NSLayoutRelationEqual
                                                                           toItem:validationErrorView
                                                                        attribute:NSLayoutAttributeCenterY
                                                                       multiplier:1.0
                                                                         constant:0.0]];
        views = NSDictionaryOfVariableBindings(label);
        [validationErrorView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-(25)-[label]-(25)-|" options:0 metrics:nil views:views]];


        objc_setAssociatedObject(self, &errorLabelKey, label, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        objc_setAssociatedObject(self, &validationErrorViewKey, validationErrorView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        objc_setAssociatedObject(self, &topConstraintKey, topConstraint, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        [self.view layoutIfNeeded];
    }

    return validationErrorView;
}

- (NSLayoutConstraint *)errorViewTopConstraint
{
    return objc_getAssociatedObject(self, &topConstraintKey);
}

- (UILabel *)errorViewLabel
{
    return objc_getAssociatedObject(self, &errorLabelKey);
}



@end
