//
//  AlertControllerManager.h
//  BCLRemoteApp
//
// Copyright (c) 2015, Upnext Technologies Sp. z o.o.
// All rights reserved.
//
// This source code is licensed under the BSD 3-Clause License found in the
// LICENSE.txt file in the root directory of this source tree.
//

#import <Foundation/Foundation.h>
@import UIKit;

@interface AlertControllerManager : NSObject

+ (instancetype)sharedManager;

- (void)presentError:(NSError *)error inViewController:(UIViewController *)viewController completion:(void (^)(void))completion;

- (void)presentErrorWithTitle:(NSString *)title message:(NSString *)errorMessage inViewController:(UIViewController *)viewController completion:(void (^)(void))completion;

- (NSString *)messageForError:(NSError *)error;
@end
