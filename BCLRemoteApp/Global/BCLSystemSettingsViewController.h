//
//  BCLSystemSettingsViewController.h
//  BCLRemoteApp
//
//  Created by Adrian Chojnacki on 08/07/15.
//  Copyright (c) 2015 UpNext. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BCLSystemSettingsViewController : UIViewController
+ (BCLSystemSettingsViewController *)viewControllerWithError:(NSError *)error;
@property (nonatomic, strong) NSError *error;
@end
