//
//  BCLNotificationSetupViewController.m
//  BCLRemoteApp
//
// Copyright (c) 2015, Upnext Technologies Sp. z o.o.
// All rights reserved.
//
// This source code is licensed under the BSD 3-Clause License found in the
// LICENSE.txt file in the root directory of this source tree.
//

#import "BCLNotificationSetupViewController.h"
#import "BCLChooseTriggerViewController.h"

@interface BCLNotificationSetupViewController () <UITextViewDelegate, BCLChooseTriggerViewControllerDelegate>
@property (weak, nonatomic) IBOutlet UITextView *textView;
@property (weak, nonatomic) IBOutlet UILabel *triggerNameLabel;
@end

@implementation BCLNotificationSetupViewController

- (void)viewDidLoad
{
    self.textView.textContainerInset = UIEdgeInsetsMake(10.0f, 10.0f, 10.0f, 10.0f);
    self.textView.text = self.notificationMessage;
    self.triggerNameLabel.text = [self nameForTrigger:self.chosenTrigger];
}

- (void)viewWillLayoutSubviews
{
    [self.textView becomeFirstResponder];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"goToChooseTrigger"]) {
        BCLChooseTriggerViewController *vc = segue.destinationViewController;
        vc.chosenTrigger = self.chosenTrigger;
        vc.delegate = self;
    }
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {

    if([text isEqualToString:@"\n"]) {
        if ([[self delegate] respondsToSelector:@selector(notificationSetupViewController:didSetupNotificationMessage:trigger:)])
        [self.delegate notificationSetupViewController:self didSetupNotificationMessage:self.textView.text trigger:self.chosenTrigger];
        return NO;
    }

    return YES;
}

#pragma mark - BCLChooseTriggerViewControllerDelegate

- (void)chooseTriggerViewController:(BCLChooseTriggerViewController *)viewController didChooseTrigger:(BCLEventType)trigger
{
    self.chosenTrigger = trigger;
    self.triggerNameLabel.text = [self nameForTrigger:trigger];
    [self.navigationController popToViewController:self animated:YES];
}

#pragma mark - Private

- (NSString *)nameForTrigger:(BCLEventType)trigger
{
    switch (trigger) {
        case BCLEventTypeEnter:
            return @"On Hello";
            break;
        case BCLEventTypeLeave:
            return @"On Leave";
            break;
        case BCLEventTypeRangeImmediate:
            return @"Almost Touching";
            break;
        case BCLEventTypeRangeNear:
            return @"Nearby";
            break;
        case BCLEventTypeRangeFar:
            return @"In Sight";
            break;
        default:
            return nil;
            break;
    }
    
    return nil;
}

@end
