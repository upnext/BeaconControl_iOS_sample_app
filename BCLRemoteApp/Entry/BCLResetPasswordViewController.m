//
//  BCLResetPasswordViewController.m
//  BCLRemoteApp
//
// Copyright (c) 2015, Upnext Technologies Sp. z o.o.
// All rights reserved.
//
// This source code is licensed under the BSD 3-Clause License found in the
// LICENSE.txt file in the root directory of this source tree.
//

#import "BCLResetPasswordViewController.h"
#import "BeaconCtrlManager.h"

@interface BCLResetPasswordViewController ()

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIView *containerView;
@property (weak, nonatomic) IBOutlet UIButton *resetPasswordButton;
@property (weak, nonatomic) IBOutlet UITextField *emailTextField;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;


@end

@implementation BCLResetPasswordViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(keyboardDidShow:) name: UIKeyboardWillShowNotification object:nil];
    [nc addObserver:self selector:@selector(keyboardWillHide:) name: UIKeyboardWillHideNotification object:nil];
    [nc addObserver:self selector:@selector(beaconCtrlManagerIsReadyForSetupNotification:) name:BeaconManagerReadyForSetupNotification object:nil];
    
    self.automaticallyAdjustsScrollViewInsets = NO;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.view.backgroundColor = [UIColor colorWithRed:0.46 green:0.66 blue:0.89 alpha:1];
    self.containerView.backgroundColor = [UIColor colorWithRed:0.46 green:0.66 blue:0.89 alpha:1];
    
    self.resetPasswordButton.enabled = [BeaconCtrlManager sharedManager].isReadyForSetup;
    
    [self.cancelButton setTitleColor:[UIColor colorWithRed:0.05 green:0.13 blue:0.25 alpha:1] forState:UIControlStateNormal];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)beaconCtrlManagerIsReadyForSetupNotification:(NSNotification *)notification
{
    self.resetPasswordButton.enabled = YES;
}

- (IBAction)resetPasswordButtonAction:(id)sender
{
    
}

- (IBAction)cancelButtonAction:(id)sender
{
    [self.presentingViewController dismissViewControllerAnimated:YES completion:NULL];
}

#pragma mark - UITextFieldDelegate

-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    
    return YES;
}

#pragma mark - Keyboard

- (void) keyboardDidShow:(NSNotification *)notification
{
    NSDictionary* info = [notification userInfo];
    CGRect kbRect = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue];
    
    self.scrollView.contentOffset = CGPointMake(0, kbRect.size.height);
}

- (void) keyboardWillHide:(NSNotification *)notification
{
    self.scrollView.contentOffset = CGPointZero;
}

@end
