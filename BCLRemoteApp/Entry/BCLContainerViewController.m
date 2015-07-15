//
//  BCLContainerViewController.m
//  BCLRemoteApp
//
// Copyright (c) 2015, Upnext Technologies Sp. z o.o.
// All rights reserved.
//
// This source code is licensed under the BSD 3-Clause License found in the
// LICENSE.txt file in the root directory of this source tree.
//

#import "BCLContainerViewController.h"
#import "BCLSideMenuViewController.h"
#import "BCLMapViewController.h"

@interface BCLContainerViewController ()

@end

@implementation BCLContainerViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    //initial view controllers
    UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    UINavigationController *navigationController = [mainStoryboard instantiateInitialViewController];
    BCLMapViewController *mapViewController = (BCLMapViewController *)navigationController.topViewController;
    [self bcl_setCurrentViewController:navigationController];
    UIStoryboard *sideMenuStoryboard = [UIStoryboard storyboardWithName:@"SideMenu" bundle:nil];
    BCLSideMenuViewController *sideMenuViewController = [sideMenuStoryboard instantiateInitialViewController];
    sideMenuViewController.delegate = mapViewController;
    self.leftMenuViewController = sideMenuViewController;
}

#pragma mark - Private

- (void)bcl_setCurrentViewController:(UIViewController *)viewController
{
    if ([viewController isKindOfClass:[UINavigationController class]]) {
        UIViewController *topViewController = ((UINavigationController *)viewController).topViewController;
        topViewController.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"menuIcon"] style:UIBarButtonItemStylePlain target:self action:@selector(bcl_toggleMenu)];
    }
    self.centerViewController = viewController;
}

- (void)bcl_toggleMenu
{
    [self toggleLeftSideMenuCompletion:nil];
}

@end
