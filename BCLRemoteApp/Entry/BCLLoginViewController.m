//
//  BCLLoginViewController.m
//  BCLRemoteApp
//
// Copyright (c) 2015, Upnext Technologies Sp. z o.o.
// All rights reserved.
//
// This source code is licensed under the BSD 3-Clause License found in the
// LICENSE.txt file in the root directory of this source tree.
//

#import "BCLLoginViewController.h"
#import "BCLRegisterViewController.h"
#import "BeaconCtrlManager.h"
#import "AlertControllerManager.h"
#import "AppDelegate.h"
#import "UIViewController+BCLActivityIndicator.h"
#import <BeaconCtrl/BCLBeacon.h>
#import <BeaconCtrl/BCLZone.h>
#import <BeaconCtrl/BCLLocation.h>

@interface BCLLoginViewController () <BCLRegisterViewControllerDelegate, UIScrollViewDelegate, CLLocationManagerDelegate>

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIView *containerView;

@property (weak, nonatomic) IBOutlet UIView *emailTextFieldContainer;
@property (weak, nonatomic) IBOutlet UILabel *emailLabel;
@property (weak, nonatomic) IBOutlet UITextField *emailTextField;

@property (weak, nonatomic) IBOutlet UIView *passwordTextFieldContainer;
@property (weak, nonatomic) IBOutlet UILabel *passwordLabel;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;

@property (weak, nonatomic) IBOutlet UIButton *loginButton;
@property (weak, nonatomic) IBOutlet UIButton *forgotPasswordButton;
@property (weak, nonatomic) IBOutlet UIButton *registerButton;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *logoVerticalCenterConstraint;

@end

@implementation BCLLoginViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(keyboardDidShow:) name: UIKeyboardWillShowNotification object:nil];
    [nc addObserver:self selector:@selector(keyboardWillHide:) name: UIKeyboardWillHideNotification object:nil];
    [nc addObserver:self selector:@selector(beaconCtrlManagerIsReadyForSetupNotification:) name:BeaconManagerReadyForSetupNotification object:nil];
    [nc addObserver:self selector:@selector(beaconCtrlManagerDidLogoutNotification:) name:BeaconManagerDidLogoutNotification object:nil];
    
    self.automaticallyAdjustsScrollViewInsets = NO;
    [self setUIAvailability:NO];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.emailTextField.text = @"";
    self.passwordTextField.text = @"";
}

- (void)setUIAvailability:(BOOL)availability
{
    [self setUIAvailability:availability animated:NO];
}

- (void)setUIAvailability:(BOOL)availability animated:(BOOL)animated
{
    [UIView animateWithDuration:animated?0.4:0.0 delay:animated?0.5:0.0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
        self.logoVerticalCenterConstraint.constant = availability?160:0;
        self.loginButton.alpha = self.forgotPasswordButton.alpha = self.emailLabel.alpha = self.emailTextFieldContainer.alpha = self.passwordLabel.alpha = self.passwordTextFieldContainer.alpha = availability;
        [self.view layoutIfNeeded];
    } completion:nil];
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    __weak typeof(self) weakSelf = self;
    
    if ([BeaconCtrlManager sharedManager].canTryAutoLogin) {
        [[BeaconCtrlManager sharedManager] setupForExistingUserWithAutologin:^(BOOL success, NSError *error) {
            if (!success) {
                [[BeaconCtrlManager sharedManager] logout];
                return;
            }
            
            dispatch_async(dispatch_get_main_queue(), ^() {
                [weakSelf performSegueWithIdentifier:@"goToMainViewController" sender:nil];
            });
        }];

    } else {
        [self setUIAvailability:[BeaconCtrlManager sharedManager].isReadyForSetup animated:YES];
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"goToRegistration"]) {
        ((BCLRegisterViewController *)(segue.destinationViewController)).delegate = self;
    }
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)beaconCtrlManagerIsReadyForSetupNotification:(NSNotification *)notification
{
    [self setUIAvailability:![BeaconCtrlManager sharedManager].canTryAutoLogin animated:YES];
}

- (void)beaconCtrlManagerDidLogoutNotification:(NSNotification *)notification
{
    [self.navigationController popToRootViewControllerAnimated:YES];
    [self setUIAvailability:YES animated:YES];
    AppDelegate *appDelegate = [UIApplication sharedApplication].delegate;
    appDelegate.shouldVerifySystemSettings = NO;
}

- (IBAction)loginButtonAction:(id)sender
{
    NSLog(@"login!!");
    
    [self showActivityIndicatorViewAnimated:YES];
    [self.emailTextField resignFirstResponder];
    [self.passwordTextField resignFirstResponder];

    __weak typeof(self) weakSelf = self;
    
    [[BeaconCtrlManager sharedManager] setupForExistingAdminUserWithEmail:self.emailTextField.text password:self.passwordTextField.text completion:^(BOOL success, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^() {
            [weakSelf hideActivityIndicatorViewAnimated:YES];
            if (!success) {
                [[AlertControllerManager sharedManager] presentErrorWithTitle:@"Error" message:@"Invalid email or password" inViewController:self completion:nil];
                return;
            }
            [weakSelf performSegueWithIdentifier:@"goToMainViewController" sender:nil];
        });
    }];
}

- (IBAction)forgotPasswordButtonAction:(id)sender
{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://admin.beaconctrl.com/admins/password/new"]];
}


- (IBAction)registerButtonAction:(id)sender
{
    [self performSegueWithIdentifier:@"goToRegistration" sender:nil];
}

#pragma mark - BCLRegisterViewControllerDelegate

- (void)registerViewControllerDidFinishRegistration:(BCLRegisterViewController *)registerViewController
{
    [self performSegueWithIdentifier:@"goToMainViewController" sender:nil];
    [self dismissViewControllerAnimated:YES completion:NULL];
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

    if (self.view.bounds.size.height <= 568) {
        // hide the "forgot my password" label behind keyboard for smaller devices
        self.scrollView.contentOffset = CGPointMake(0, kbRect.size.height - 40);
    } else {
        self.scrollView.contentOffset = CGPointMake(0, kbRect.size.height);
    }
}

- (void) keyboardWillHide:(NSNotification *)notification
{
    self.scrollView.contentOffset = CGPointZero;
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    CGFloat constant = MAX(160 - scrollView.contentOffset.y, 340 - self.view.bounds.size.height/2);
    self.logoVerticalCenterConstraint.constant = constant;
    [self.view layoutIfNeeded];
}

#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    [self performSegueWithIdentifier:@"goToMainViewController" sender:nil];
}



@end
