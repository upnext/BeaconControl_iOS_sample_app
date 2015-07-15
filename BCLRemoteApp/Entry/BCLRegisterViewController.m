//
//  BCLRegisterViewController.m
//  BCLRemoteApp
//
// Copyright (c) 2015, Upnext Technologies Sp. z o.o.
// All rights reserved.
//
// This source code is licensed under the BSD 3-Clause License found in the
// LICENSE.txt file in the root directory of this source tree.
//

#import "BCLRegisterViewController.h"
#import "BeaconCtrlManager.h"
#import "AlertControllerManager.h"
#import <BeaconCtrl/BCLBeaconCtrl.h>

@interface BCLRegisterViewController ()
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIView *containerView;

@property (weak, nonatomic) IBOutlet UITextField *emailTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordConfirmationTextField;
@property (weak, nonatomic) IBOutlet UITextField *voucherNumberTextField;

@property (weak, nonatomic) IBOutlet UIButton *registerButton;

@end

@implementation BCLRegisterViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(keyboardDidShow:) name: UIKeyboardWillShowNotification object:nil];
    [nc addObserver:self selector:@selector(keyboardWillHide:) name: UIKeyboardWillHideNotification object:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.view.backgroundColor = [UIColor colorWithRed:0.46 green:0.66 blue:0.89 alpha:1];
    self.containerView.backgroundColor = [UIColor colorWithRed:0.46 green:0.66 blue:0.89 alpha:1];
    [self.registerButton setTitleColor:[UIColor colorWithRed:0.05 green:0.13 blue:0.25 alpha:1] forState:UIControlStateNormal];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (IBAction)registerButtonAction:(id)sender
{
    __weak typeof(self) weakSelf = self;
    
    [[BeaconCtrlManager sharedManager] setupForNewAdminUserWithEmail:self.emailTextField.text password:self.passwordTextField.text passwordConfirmation:self.passwordConfirmationTextField.text completion:^(BOOL success, NSError *error) {
        if (!success) {
            [[AlertControllerManager sharedManager] presentError:error inViewController:weakSelf completion:nil];
            return;
        }
        
        dispatch_async(dispatch_get_main_queue(), ^() {
            [weakSelf.delegate registerViewControllerDidFinishRegistration:weakSelf];
        });
    }];
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
