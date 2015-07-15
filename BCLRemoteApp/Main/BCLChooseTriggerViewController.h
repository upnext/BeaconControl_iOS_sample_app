//
//  BOSChooseTriggerViewController.h
//  BCLRemoteApp
//
//  Created by Artur Wdowiarski on 05.07.2015.
//  Copyright (c) 2015 UpNext. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <BeaconCtrl/BCLTypes.h>

@class BCLChooseTriggerViewController;

@protocol BCLChooseTriggerViewControllerDelegate <NSObject>

- (void)chooseTriggerViewController:(BCLChooseTriggerViewController *)viewController didChooseTrigger:(BCLEventType)trigger;

@end

@interface BCLChooseTriggerViewController : UIViewController

@property (nonatomic, weak) id<BCLChooseTriggerViewControllerDelegate> delegate;
@property (nonatomic) BCLEventType chosenTrigger;

@end
