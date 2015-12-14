//
//  BCLSystemSettingsViewController.m
//  BCLRemoteApp
//
//  Created by Adrian Chojnacki on 08/07/15.
//  Copyright (c) 2015 UpNext. All rights reserved.
//

#import "BCLSystemSettingsViewController.h"
#import "BCLBeaconCtrl.h"

@interface BCLSystemSettingsViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *locationStatusImageView;
@property (weak, nonatomic) IBOutlet UIImageView *bgAppRefreshStatusImageView;
@property (weak, nonatomic) IBOutlet UIImageView *bluetoothStatusImageView;
@property (weak, nonatomic) IBOutlet UIImageView *notificationsStatusImageView;
@property (weak, nonatomic) IBOutlet UILabel *bgAppRefreshLabel;
@property (weak, nonatomic) IBOutlet UILabel *label;

@end

@implementation BCLSystemSettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self configureWithError:self.error];
    if ([UIScreen mainScreen].bounds.size.width <= 320) {
        self.bgAppRefreshLabel.text = @"Background App Refresh";
    }
}

+ (BCLSystemSettingsViewController *)viewControllerWithError:(NSError *)error
{
    BCLSystemSettingsViewController *viewController = [[BCLSystemSettingsViewController alloc] initWithNibName:@"SystemSettingsViewController" bundle:nil];
    viewController.error = error;
    return viewController;
}

- (IBAction)showSettingsButtonPressed:(id)sender
{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
}

- (IBAction)skipButtonPressed:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)setError:(NSError *)error
{
    _error = error;
    [self configureWithError:error];
}

- (void)configureWithError:(NSError *)error
{
    UIImage *noImage = [UIImage imageNamed:@"settingsview_x"];
    UIImage *yesImage = [UIImage imageNamed:@"settingsview_check"];

    if (error.userInfo[BCLDeniedMonitoringErrorKey]) {
        self.label.text = error.userInfo[BCLDeniedMonitoringErrorKey];
        self.label.font = [UIFont systemFontOfSize:20.0];
        self.bluetoothStatusImageView.image = self.bgAppRefreshStatusImageView.image =
                self.locationStatusImageView.image = self.notificationsStatusImageView.image = noImage;
    } else {
        self.bluetoothStatusImageView.image = error.userInfo[BCLBluetoothNotTurnedOnErrorKey] ? noImage : yesImage;
        self.bgAppRefreshStatusImageView.image = error.userInfo[BCLDeniedBackgroundAppRefreshErrorKey] ? noImage : yesImage;
        self.locationStatusImageView.image = error.userInfo[BCLDeniedLocationServicesErrorKey] ? noImage : yesImage;
        self.notificationsStatusImageView.image = error.userInfo[BCLDeniedNotificationsErrorKey] ? noImage : yesImage;
    }

}

@end
