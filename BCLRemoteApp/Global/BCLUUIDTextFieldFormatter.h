//
//  BCLUUIDTextFieldFormatter.h
//  BCLRemoteApp
//
// Copyright (c) 2015, Upnext Technologies Sp. z o.o.
// All rights reserved.
//
// This source code is licensed under the BSD 3-Clause License found in the
// LICENSE.txt file in the root directory of this source tree.
//

@import UIKit;
#import <Foundation/Foundation.h>

@interface BCLUUIDTextFieldFormatter : NSObject <UITextFieldDelegate>
@property (nonatomic, strong) UITextField *textField;

- (BOOL)isValid;
@end
