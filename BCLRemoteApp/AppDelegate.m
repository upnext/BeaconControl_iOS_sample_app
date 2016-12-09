//
//  AppDelegate.m
//  BCLRemoteApp
//
// Copyright (c) 2015, Upnext Technologies Sp. z o.o.
// All rights reserved.
//
// This source code is licensed under the BSD 3-Clause License found in the
// LICENSE.txt file in the root directory of this source tree.
//

#import "AppDelegate.h"
#import <BeaconCtrl/BCLBeaconCtrlAdmin.h>
#import "BeaconCtrlManager.h"
#import "BCLSystemSettingsViewController.h"
#import <CoreLocation/CoreLocation.h>

NSString * const BCLApplicationDidRegisterForRemoteNotificationsNotification = @"BCLApplicationDidRegisterForRemoteNotificationsNotification";
NSString * const BCLApplicationDidFailToRegisterForRemoteNotificationsNotification = @"BCLApplicationDidFailToRegisterForRemoteNotificationsNotification";

@interface AppDelegate () <CLLocationManagerDelegate>
@property (nonatomic, strong) CLLocationManager *locationManager;
@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:(UIRemoteNotificationTypeBadge
                                                                                         |UIRemoteNotificationTypeSound
                                                                                         |UIRemoteNotificationTypeAlert) categories:nil];

    [application registerUserNotificationSettings:settings];

    self.locationManager = [CLLocationManager new];
    self.locationManager.delegate = self;
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    if (self.shouldVerifySystemSettings) {
        [self verifySystemSettings];
    }
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    if (self.shouldVerifySystemSettings) {
        [self performSelector:@selector(verifySystemSettings) withObject:nil afterDelay:0.5];
    }
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

#pragma mark - Phone Settings Verification

- (void)setShouldVerifySystemSettings:(BOOL)shouldVerifySystemSettings
{
    _shouldVerifySystemSettings = shouldVerifySystemSettings;
    if (shouldVerifySystemSettings) {
        if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusNotDetermined) {
            [self.locationManager requestAlwaysAuthorization];
        } else {
            [self verifySystemSettings];
        }
    }
}

- (void)verifySystemSettings
{
#if (!TARGET_IPHONE_SIMULATOR)
    NSError *error;
    if (![[BeaconCtrlManager sharedManager].beaconCtrl isBeaconCtrlReadyToProcessBeaconActions:&error]) {
        if ([self.window.rootViewController.presentedViewController isKindOfClass:[BCLSystemSettingsViewController class]]) {
            BCLSystemSettingsViewController *viewController = (BCLSystemSettingsViewController *) self.window.rootViewController.presentedViewController;
            viewController.error = error;
        } else {
            BCLSystemSettingsViewController *viewController = [BCLSystemSettingsViewController viewControllerWithError:error];
            [self.window.rootViewController presentViewController:viewController animated:YES completion:nil];
        }
    } else {
        if ([self.window.rootViewController.presentedViewController isKindOfClass:[BCLSystemSettingsViewController class]]) {
            [self.window.rootViewController dismissViewControllerAnimated:YES completion:nil];
        }
    }
#endif
}

#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    if (self.shouldVerifySystemSettings) {
        [self verifySystemSettings];
    }
}

#pragma mark - Push Notifications

- (void)application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings
{
    NSLog(@"Did register user notification settings");
    
    [application registerForRemoteNotifications];
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    NSLog(@"Did register for remote notifications");
    
    NSString *deviceTokenString = [[[[deviceToken description] stringByReplacingOccurrencesOfString: @"<" withString: @""] stringByReplacingOccurrencesOfString: @">" withString: @""] stringByReplacingOccurrencesOfString: @" " withString: @""];
    
    self.isRemoteNotificationSetupReady = YES;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:BCLApplicationDidRegisterForRemoteNotificationsNotification object:application userInfo:@{@"deviceToken": deviceTokenString}];
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
    NSLog(@"Did fail to register for remote notifications");
    
    self.isRemoteNotificationSetupReady = YES;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:BCLApplicationDidFailToRegisterForRemoteNotificationsNotification object:application];
}

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification
{
    [[BeaconCtrlManager sharedManager].beaconCtrl handleNotification:notification.userInfo error:nil];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
{
    [[BeaconCtrlManager sharedManager].beaconCtrl handleNotification:userInfo error:nil];
}

@end
