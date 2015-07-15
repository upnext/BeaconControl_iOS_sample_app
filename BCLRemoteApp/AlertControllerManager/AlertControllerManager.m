//
//  AlertControllerManager.m
//  BCLRemoteApp
//
// Copyright (c) 2015, Upnext Technologies Sp. z o.o.
// All rights reserved.
//
// This source code is licensed under the BSD 3-Clause License found in the
// LICENSE.txt file in the root directory of this source tree.
//

#import "AlertControllerManager.h"
#import <BeaconCtrl/BCLBeaconCtrl.h>

@implementation AlertControllerManager

+(instancetype)sharedManager
{
    static AlertControllerManager *sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[AlertControllerManager alloc] init];
    });
    return sharedManager;
}

- (void)presentError:(NSError *)error inViewController:(UIViewController *)viewController completion:(void (^)(void))completion
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:[self titleForError:error]
                                                                             message:[self messageForError:error]
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK"
                                                       style:UIAlertActionStyleDefault
                                                     handler:NULL];
    
    [alertController addAction:okAction];
    
    dispatch_async(dispatch_get_main_queue(), ^() {
        [viewController presentViewController:alertController animated:YES completion:completion];
    });
}

- (void)presentErrorWithTitle:(NSString *)title message:(NSString *)errorMessage inViewController:(UIViewController *)viewController completion:(void (^)(void))completion
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title
                                                                             message:errorMessage
                                                                      preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK"
                                                       style:UIAlertActionStyleDefault
                                                     handler:NULL];

    [alertController addAction:okAction];

    dispatch_async(dispatch_get_main_queue(), ^() {
        [viewController presentViewController:alertController animated:YES completion:completion];
    });
}

#pragma mark - Private

- (NSString *)titleForError:(NSError *)error
{
    return @"Error";
}

- (NSString *)messageForError:(NSError *)error
{
    if (error.code == BCLInvalidDeviceConfigurationError) {
        if (error.userInfo[BCLDeniedMonitoringErrorKey]) {
            return @"This device doesn't support monitoring beacons. BeaconCtrl will not work properly";
        }
        
        NSMutableString *message = @"In order for the BeaconCtrl to work properly, you need to do the following:".mutableCopy;
        
        if (error.userInfo[BCLBluetoothNotTurnedOnErrorKey]) {
            [message appendString:@"\n* Turn on bluetooth."];
        }
        
        if (error.userInfo[BCLDeniedBackgroundAppRefreshErrorKey]) {
            [message appendString:@"\n* Turn on background app refresh for this app."];
        }
        
        if (error.userInfo[BCLDeniedLocationServicesErrorKey]) {
            [message appendString:@"\n* Turn on location services for this app."];
        }
        
        return message.copy;
    }
    
    if (error.userInfo) {
        if (error.userInfo[@"BCLResponseDictionaryKey"]) {
            if (error.userInfo[@"BCLResponseDictionaryKey"][@"error_description"]) {
                return error.userInfo[@"BCLResponseDictionaryKey"][@"error_description"];
            } else if (error.userInfo[@"BCLResponseDictionaryKey"][@"errors"]) {
                NSArray *errorKeys = [error.userInfo[@"BCLResponseDictionaryKey"][@"errors"] allKeys];
                for (NSString *errorKey in errorKeys) {
                    if ([error.userInfo[@"BCLResponseDictionaryKey"][@"errors"][errorKey] isKindOfClass:[NSArray class]]) {
                        NSArray *errors = error.userInfo[@"BCLResponseDictionaryKey"][@"errors"][errorKey];
                        if (errors.count > 0) {
                            NSString *description = [error.userInfo[@"BCLResponseDictionaryKey"][@"errors"][errorKey] firstObject];
                            description = [NSString stringWithFormat:@"%@ %@", errorKey.capitalizedString, description];
                            return description;
                        }
                    } else if ([error.userInfo[@"BCLResponseDictionaryKey"][@"errors"][errorKey] isKindOfClass:[NSString class]]){
                        return error.userInfo[@"BCLResponseDictionaryKey"][@"errors"][errorKey];
                    }
                }
                return @"Something went wrong. Please, try again later";
            }
        }
    }
    
    return @"Something went wrong. Please, try again later";
}

@end
