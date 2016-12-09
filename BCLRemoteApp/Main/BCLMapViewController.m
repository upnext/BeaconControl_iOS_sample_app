//
//  BCLMapViewController.m
//  BCLRemoteApp
//
// Copyright (c) 2015, Upnext Technologies Sp. z o.o.
// All rights reserved.
//
// This source code is licensed under the BSD 3-Clause License found in the
// LICENSE.txt file in the root directory of this source tree.
//

#import "BCLMapViewController.h"
#import "BCLBeacon.h"
#import "BCLLocation.h"
#import "BeaconCtrlManager.h"
#import "UIImage+BeaconMarker.h"
#import "AlertControllerManager.h"
#import "UIViewController+BCLActivityIndicator.h"
#import "UIViewController+MFSideMenuAdditions.h"
#import "AppDelegate.h"
#import "BCLAnnotation.h"

#import <MFSideMenu/MFSideMenuContainerViewController.h>

@import Mapbox;


typedef NS_ENUM(NSUInteger, BCLMapViewControllerState) {
    kBCLMapViewControllerStateNormal,
    kBCLMapViewControllerStateBeaconSelected,
    kBCLMapViewControllerStateNewBeacon,
    kBCLMapViewControllerStateShowsBeaconDetails
};

static NSString *kBCLBeaconDetailsSegueIdentifier = @"beaconDetailsSegue";
static NSString *kBCLEmbedBeaconDetailsSegueIdentifier = @"embedBeaconDetailsSegue";

static CGFloat kBCLTransitionDuration = 0.5;
static CGFloat kBCLExtendedBeaconDetailsViewHeight = 169.0;
static CGFloat kBCLHiddenBeaconDetailsViewHeight = 63.0;

@interface BCLMapViewController () <MGLMapViewDelegate, UINavigationControllerDelegate, UIViewControllerAnimatedTransitioning, BCLBeaconDetailsViewControllerDelegate>
@property(strong) IBOutlet MGLMapView *mapView;
@property(weak, nonatomic) IBOutlet UIView *mapViewContainer;
@property(weak, nonatomic) IBOutlet UIImageView *pinView;
@property(weak, nonatomic) IBOutlet UIButton *addButton;
@property(weak, nonatomic) IBOutlet UIButton *moveButton;
@property(weak, nonatomic) IBOutlet NSLayoutConstraint *beaconDetailsConstraint;
@property(weak, nonatomic) IBOutlet UIView *containerView;
@property(weak, nonatomic) IBOutlet NSLayoutConstraint *buttonsDistanceConstraint;

@property(strong, nonatomic) BCLBeaconDetailsViewController *beaconDetailsViewController;
@property(nonatomic) BCLMapViewControllerState state;

@property(strong, nonatomic) NSSet *beacons;

@property(nonatomic, strong) BCLBeacon *currentlyAddedBeacon;
@property(nonatomic, strong) BCLBeacon *currentlyEditedBeacon;
@property(nonatomic, strong) BeaconCtrlManager *beaconCtrlManager;

@property(nonatomic, strong) NSArray *filteredZones;
@property(nonatomic) BOOL showsNoneZone;
@property(nonatomic) NSNumber *floor;
@property(nonatomic) BOOL needsReload;
@property(nonatomic) BOOL didVerifySystemSettings;
@end

@implementation BCLMapViewController

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.mapView.delegate = self;
    self.mapView.showsUserLocation = YES;
    self.mapView.userTrackingMode = MGLUserTrackingModeFollow;

    //initial views setup
    self.state = kBCLMapViewControllerStateNormal;
    self.navigationController.delegate = self;
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];

    CALayer *layer = self.containerView.layer;
    layer.shadowColor = [UIColor blackColor].CGColor;
    layer.shadowOffset = CGSizeMake(0, -1);
    layer.shadowOpacity = 0.3;
    layer.shadowRadius = 5.0;

    self.mapView.zoomLevel = 0;
    self.showsNoneZone = YES;
    self.floor = nil;

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setNeedsReload) name:BeaconManagerDidFetchBeaconCtrlConfigurationNotification object:nil];
    [self reloadBeacons];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (!self.didVerifySystemSettings) {
        AppDelegate *delegate = [UIApplication sharedApplication].delegate;
        delegate.shouldVerifySystemSettings = YES;
        self.didVerifySystemSettings = YES;
    }
}

- (void)setNeedsReload {
    __weak BCLMapViewController *weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        if (weakSelf.state == kBCLMapViewControllerStateNormal) {
            [weakSelf reloadConfiguration];
        } else {
            weakSelf.needsReload = YES;
        }
    });
}

- (void)reloadConfiguration {
    if (self.filteredZones) {
        NSMutableArray *newFilteredZones = [NSMutableArray new];
        for (BCLZone *zone in [BeaconCtrlManager sharedManager].beaconCtrl.configuration.zones) {
            [self.filteredZones enumerateObjectsUsingBlock:^(BCLZone *filteredZone, NSUInteger idx, BOOL *stop) {
                if ([filteredZone.zoneIdentifier isEqualToString:zone.zoneIdentifier]) {
                    [newFilteredZones addObject:zone];
                    *stop = YES;
                }
            }];
        }
        self.filteredZones = [newFilteredZones copy];
    }
    [self reloadBeacons];
}

- (void)viewWillAppear:(BOOL)animated {
    self.menuContainerViewController.panMode = MFSideMenuPanModeDefault;
}

- (void)viewWillDisappear:(BOOL)animated {
    self.menuContainerViewController.panMode = MFSideMenuPanModeNone;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleDefault;
}


- (BCLAnnotation *)addAnnotationForBeacon:(BCLBeacon *)beacon {

    BCLAnnotation *annotation = [BCLAnnotation new];
    annotation.reuseIdentifier = [NSString stringWithFormat:@"annotationWithBeaconId_%@", beacon.instanceId];
    annotation.coordinate = beacon.location.location.coordinate;
    annotation.userInfo = beacon;
    [self.mapView addAnnotation:annotation];

    return annotation;
}

#pragma mark - Private

- (void)clearBeacons {
    [self.mapView removeAnnotations:self.mapView.annotations];
}

- (void)reloadBeacons {
    self.needsReload = NO;
    __weak BCLMapViewController *weakSelf = self;
    [self setState:kBCLMapViewControllerStateNormal animated:NO completion:^(BOOL finished) {
        [weakSelf clearBeacons];
        weakSelf.beacons = weakSelf.beaconCtrlManager.beaconCtrl.configuration.beacons;
        if (!weakSelf.filteredZones) {
            for (BCLBeacon *beacon in weakSelf.beacons) {
                if ([weakSelf beaconsOnCurrentFloor:beacon] && (weakSelf.showsNoneZone || beacon.zone)) {
                    BCLAnnotation *annotation = [weakSelf addAnnotationForBeacon:beacon];
                    [weakSelf selectAnnotationIfNecessary:annotation];
                }
            }
        } else {
            for (BCLZone *zone in weakSelf.filteredZones) {
                for (BCLBeacon *beacon in zone.beacons) {
                    if ([weakSelf beaconsOnCurrentFloor:beacon]) {
                        BCLAnnotation *annotation = [weakSelf addAnnotationForBeacon:beacon];
                        [weakSelf selectAnnotationIfNecessary:annotation];
                    }
                }
            }
            if (weakSelf.showsNoneZone) {
                for (BCLBeacon *beacon in weakSelf.beacons) {
                    if (!beacon.zone && [weakSelf beaconsOnCurrentFloor:beacon]) {
                        BCLAnnotation *annotation = [weakSelf addAnnotationForBeacon:beacon];
                        [weakSelf selectAnnotationIfNecessary:annotation];
                    }
                }
            }
        }
    }];
}

- (void)selectAnnotationIfNecessary:(BCLAnnotation *)annotation {
    BCLBeacon *beacon = annotation.userInfo;
    if ([beacon.beaconIdentifier isEqualToString:self.currentlyEditedBeacon.beaconIdentifier]) {
        [self.mapView selectAnnotation:annotation animated:NO];
    }
}

- (BOOL)beaconsOnCurrentFloor:(BCLBeacon *)beacon {
    if (!self.floor) {
        return YES;
    }

    if ([self.floor isEqualToNumber:@(NSNotFound)]) {
        return beacon.location.floor == nil;
    }

    return [beacon.location.floor isEqualToNumber:self.floor];
}

- (void)centerCurrentlySelectedAnnotationAnimated:(BOOL)animated {
    CLLocationCoordinate2D coordinate2D = [self.mapView convertPoint:self.pinView.center toCoordinateFromView:self.view];
    CLLocationDegrees latDelta = coordinate2D.latitude - self.mapView.centerCoordinate.latitude;

    CLLocationCoordinate2D centerCoordinate = self.mapView.selectedAnnotations[0].coordinate;
    centerCoordinate.latitude = centerCoordinate.latitude - latDelta;

    //don't do anything if mapview already centered
    CLLocationDegrees diff = centerCoordinate.latitude - self.mapView.centerCoordinate.latitude;
    if (fabs(diff) < 0.00001) {
        diff = centerCoordinate.longitude - self.mapView.centerCoordinate.longitude;
        if (fabs(diff) < 0.00001) {
            return;
        }
    }

    [self.mapView setCenterCoordinate:centerCoordinate animated:animated];
}

#pragma mark - IBActions

- (IBAction)moveButtonPressed:(id)sender {

    __weak BCLMapViewController *weakSelf = self;

    switch (self.state) {
        case kBCLMapViewControllerStateNormal:
            break;

        case kBCLMapViewControllerStateBeaconSelected: {
            [self centerCurrentlySelectedAnnotationAnimated:NO];
            [self setState:kBCLMapViewControllerStateNewBeacon animated:NO completion:^(BOOL finished) {
                [weakSelf.mapView removeAnnotation:weakSelf.mapView.selectedAnnotations[0]];
            }];
        };
            break;

        case kBCLMapViewControllerStateNewBeacon:
            //cancel - go back to previous state
            if (self.currentlyEditedBeacon) {
                [self setState:kBCLMapViewControllerStateBeaconSelected animated:YES];
            } else {
                [self setState:kBCLMapViewControllerStateNormal animated:YES];
            }
            break;
        case kBCLMapViewControllerStateShowsBeaconDetails:
            break;
    }
}

- (IBAction)addButtonPressed:(id)sender {
    switch (self.state) {

        case kBCLMapViewControllerStateNormal: {
            [self setState:kBCLMapViewControllerStateNewBeacon animated:YES];
        }
            break;

        case kBCLMapViewControllerStateBeaconSelected: {
            [self.navigationController pushViewController:self.beaconDetailsViewController animated:YES];
        };
            break;

        case kBCLMapViewControllerStateNewBeacon: {
            CGPoint pinPoint = [self.mapView convertPoint:self.pinView.center fromView:self.view];
            CLLocationCoordinate2D coordinate2D = [self.mapView convertPoint:pinPoint toCoordinateFromView:self.mapView];
            CLLocation *location = [[CLLocation alloc] initWithLatitude:coordinate2D.latitude longitude:coordinate2D.longitude];

            if (self.currentlyEditedBeacon) {
                //save new location
                __weak BCLMapViewController *weakSelf = self;
                BCLBeacon *beacon = [self.currentlyEditedBeacon copy];
                beacon.location = [[BCLLocation alloc] initWithLocation:location floor:beacon.location.floor];
                [self showActivityIndicatorViewAnimated:YES];
                // TODO:!!!
                [self.beaconCtrlManager updateBeacon:beacon testActionName:nil testActionTrigger:BCLEventTypeEnter testActionAttributes:nil completion:^(BCLBeacon *updatedBeacon, NSError *error) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [weakSelf hideActivityIndicatorViewAnimated:YES];
                        if (!error) {
                            weakSelf.currentlyEditedBeacon = updatedBeacon;
                            BCLAnnotation *annotation = weakSelf.mapView.selectedAnnotations[0];
                            annotation.coordinate = updatedBeacon.location.location.coordinate;
                            annotation.userInfo = updatedBeacon;
                            [self setState:kBCLMapViewControllerStateBeaconSelected animated:YES];
                        } else {
                            [[AlertControllerManager sharedManager] presentError:error inViewController:weakSelf completion:nil];
                        }
                    });
                }];
            } else {
                //create beacon and go to beacon details view
                if (!self.currentlyAddedBeacon) {
                    BCLBeacon *newBeacon = [[BCLBeacon alloc] init];
                    newBeacon.zone = self.beaconDetailsViewController.selectedZone;
                    self.currentlyAddedBeacon = newBeacon;
                }

                self.currentlyAddedBeacon.location = [[BCLLocation alloc] initWithLocation:location floor:nil];
                self.beaconDetailsViewController.beaconMode = kBCLBeaconModeNew;
                [self.beaconDetailsViewController updateView];
                [self.navigationController pushViewController:self.beaconDetailsViewController animated:YES];
            }

        }
            break;

        case kBCLMapViewControllerStateShowsBeaconDetails: {

        };
            break;
    }
}

#pragma mark - Accessors

- (void)setState:(enum BCLMapViewControllerState)state animated:(BOOL)animated completion:(void (^)(BOOL))completion {
    _state = state;
    [UIView animateWithDuration:animated ? kBCLTransitionDuration : 0.0
                          delay:0.0
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         switch (state) {
                             case kBCLMapViewControllerStateNormal: {
                                 self.beaconDetailsConstraint.constant = kBCLHiddenBeaconDetailsViewHeight;
                                 [self.addButton setImage:[UIImage imageNamed:@"plus_mapbtn"] forState:UIControlStateNormal];
                                 self.addButton.transform = CGAffineTransformIdentity;
                                 self.pinView.hidden = YES;
                                 self.buttonsDistanceConstraint.constant = 0.0;
                             };
                                 break;
                             case kBCLMapViewControllerStateBeaconSelected: {
                                 [self.beaconCtrlManager muteAutomaticBeaconCtrlConfigurationRefresh];
                                 if (!self.pinView.hidden && self.currentlyEditedBeacon) {
                                     [self.mapView addAnnotation:self.mapView.selectedAnnotations[0]];
                                 }

                                 self.beaconDetailsConstraint.constant = kBCLExtendedBeaconDetailsViewHeight;
                                 [self.addButton setImage:[UIImage imageNamed:@"settings_mapbtn"] forState:UIControlStateNormal];
                                 [self.moveButton setImage:[UIImage imageNamed:@"move_mapbtn"] forState:UIControlStateNormal];
                                 self.addButton.transform = CGAffineTransformIdentity;
                                 self.pinView.hidden = YES;
                                 self.buttonsDistanceConstraint.constant = 65.0;

                                 //center & select annotation
                                 BCLAnnotation *annotation = self.mapView.selectedAnnotations[0];
                                 BCLBeacon *beacon = annotation.userInfo;

                                 self.currentlyEditedBeacon = (BCLBeacon *) annotation.userInfo;;
                                 [self centerCurrentlySelectedAnnotationAnimated:YES];

                                 UIImage *image;
                                 if (beacon.zone) {
                                     image = [UIImage beaconMarkerWithColor:beacon.zone.color highlighted:YES needsUpdate:beacon.needsCharacteristicsUpdate || beacon.needsFirmwareUpdate];
                                 } else {
                                     image = [UIImage imageNamed:@"beaconWithoutZonePressed"];
                                 }
                                 MGLAnnotationImage *annotationImage = [self.mapView dequeueReusableAnnotationImageWithIdentifier:annotation.reuseIdentifier];
                                 annotationImage.image = image;
                             };
                                 break;
                             case kBCLMapViewControllerStateNewBeacon: {
                                 [self.beaconCtrlManager muteAutomaticBeaconCtrlConfigurationRefresh];
                                 if (self.currentlyEditedBeacon) {
                                     [self.addButton setImage:[UIImage imageNamed:@"ok_mapbtn"] forState:UIControlStateNormal];
                                 } else {
                                     [self.addButton setImage:[UIImage imageNamed:@"arrow_mapbtn"] forState:UIControlStateNormal];
                                 }
                                 [self.moveButton setImage:[UIImage imageNamed:@"cancel_mapbtn"] forState:UIControlStateNormal];
                                 self.beaconDetailsConstraint.constant = kBCLExtendedBeaconDetailsViewHeight;
                                 self.addButton.transform = CGAffineTransformIdentity;
                                 self.buttonsDistanceConstraint.constant = 65.0;
                             };
                                 break;
                             case kBCLMapViewControllerStateShowsBeaconDetails: {
                                 [self.beaconCtrlManager muteAutomaticBeaconCtrlConfigurationRefresh];
                                 self.beaconDetailsConstraint.constant = self.view.bounds.size.height;
                                 self.addButton.transform = CGAffineTransformMakeRotation(3 * M_PI_2);
                                 self.buttonsDistanceConstraint.constant = 0.0;
                             };
                                 break;
                         }

                         [self.view layoutIfNeeded];
                     } completion:^(BOOL finished) {
                //check if state wasn't changed before animation completion
                if (state == _state && finished) {
                    switch (state) {
                        case kBCLMapViewControllerStateNormal:
                            [self.beaconCtrlManager unmuteAutomaticBeaconCtrlConfigurationRefresh];
                            self.currentlyAddedBeacon = nil;
                            self.currentlyEditedBeacon = nil;
                            self.beaconDetailsViewController.view.userInteractionEnabled = NO;
                            self.beaconDetailsViewController.beaconMode = kBCLBeaconModeHidden;
                            if (self.needsReload) {
                                [self reloadConfiguration];
                            }
                            break;
                        case kBCLMapViewControllerStateBeaconSelected:
                            self.beaconDetailsViewController.view.userInteractionEnabled = NO;
                            self.beaconDetailsViewController.beaconMode = kBCLBeaconModeDetails;
                            break;
                        case kBCLMapViewControllerStateNewBeacon:
                            self.beaconDetailsViewController.view.userInteractionEnabled = NO;
                            self.pinView.hidden = NO;
                            self.beaconDetailsViewController.beaconMode = kBCLBeaconModeNew;
                            break;
                        case kBCLMapViewControllerStateShowsBeaconDetails:
                            self.beaconDetailsViewController.view.userInteractionEnabled = YES;
                            break;
                    }
                }
                if (completion) {
                    completion(finished);
                }
            }];
}

- (void)setState:(BCLMapViewControllerState)state animated:(BOOL)animated {
    [self setState:state animated:animated completion:nil];
}

- (void)setState:(BCLMapViewControllerState)state {
    [self setState:state animated:NO];
}

- (void)setCurrentlyAddedBeacon:(BCLBeacon *)currentlyAddedBeacon {
    _currentlyAddedBeacon = currentlyAddedBeacon;
    _currentlyEditedBeacon = nil;
    self.beaconDetailsViewController.beacon = currentlyAddedBeacon;
    self.beaconDetailsViewController.beaconMode = kBCLBeaconModeNew;
}

- (void)setCurrentlyEditedBeacon:(BCLBeacon *)currentlyEditedBeacon {
    _currentlyEditedBeacon = currentlyEditedBeacon;
    _currentlyAddedBeacon = nil;
    self.beaconDetailsViewController.beacon = currentlyEditedBeacon;
    self.beaconDetailsViewController.beaconMode = kBCLBeaconModeDetails;
}

- (BeaconCtrlManager *)beaconCtrlManager {
    return [BeaconCtrlManager sharedManager];
}

#pragma mark Side Menu Delegate

- (void)sideMenuViewController:(BCLSideMenuViewController *)controller didChangeSelection:(NSArray *)selection showsNoneZone:(BOOL)showsNone {
    self.filteredZones = selection;
    self.showsNoneZone = showsNone;
    [self reloadBeacons];
}

- (void)sideMenuViewController:(BCLSideMenuViewController *)controller didSelectFloorNumber:(NSNumber *)floorNumber {
    self.floor = floorNumber;
    [self reloadBeacons];
}

#pragma mark MapView Delegate

- (nullable MGLAnnotationImage *)mapView:(nonnull MGLMapView *)mapView imageForAnnotation:(nonnull id <MGLAnnotation>)annotation {

    if (![annotation isKindOfClass:[BCLAnnotation class]]) {
        return nil;
    }

    BCLAnnotation *bclAnnotation = (BCLAnnotation *) annotation;
    BCLBeacon *beacon = bclAnnotation.userInfo;

    UIImage *image;

    if (mapView.selectedAnnotations.count > 0 && bclAnnotation == [mapView.selectedAnnotations objectAtIndex:0]) {
        image = [UIImage beaconMarkerWithColor:[UIColor redColor] highlighted:NO needsUpdate:YES];
    } else {
        if (beacon.zone.color) {
            image = [UIImage beaconMarkerWithColor:beacon.zone.color highlighted:NO needsUpdate:beacon.needsCharacteristicsUpdate || beacon.needsFirmwareUpdate];
        } else {
            image = [UIImage imageNamed:beacon.needsFirmwareUpdate || beacon.needsCharacteristicsUpdate ? @"beaconWithoutZoneRed" : @"beaconWithoutZone"];
        }
    }

    return [MGLAnnotationImage annotationImageWithImage:image reuseIdentifier:bclAnnotation.reuseIdentifier];
}

- (void)mapView:(nonnull MGLMapView *)mapView didSelectAnnotation:(nonnull id <MGLAnnotation>)annotation {
    if ([annotation isKindOfClass:[BCLAnnotation class]]) {
        [self setState:kBCLMapViewControllerStateBeaconSelected animated:YES];
    }
}

- (void)mapView:(nonnull MGLMapView *)mapView didDeselectAnnotation:(nonnull id <MGLAnnotation>)annotation {

    if ([annotation isKindOfClass:[BCLAnnotation class]]) {
        BCLAnnotation *bclAnnotation = (BCLAnnotation *) annotation;
        BCLBeacon *beacon = bclAnnotation.userInfo;
        UIImage *image;

        if (beacon.zone.color) {
            image = [UIImage beaconMarkerWithColor:beacon.zone.color highlighted:NO needsUpdate:beacon.needsCharacteristicsUpdate || beacon.needsFirmwareUpdate];
        } else {
            image = [UIImage imageNamed:beacon.needsCharacteristicsUpdate || beacon.needsFirmwareUpdate ? @"beaconWithoutZoneRed" : @"beaconWithoutZone"];
        }

        if (self.state == kBCLMapViewControllerStateNewBeacon) {
            [self.mapView addAnnotation:annotation];
        } else {
            MGLAnnotationImage *annotationImage = [self.mapView dequeueReusableAnnotationImageWithIdentifier:bclAnnotation.reuseIdentifier];
            annotationImage.image = image;

        }

        [self setState:kBCLMapViewControllerStateNormal animated:YES];
    }
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:kBCLBeaconDetailsSegueIdentifier]) {
        BCLBeaconDetailsViewController *viewController = segue.destinationViewController;
        viewController.beacon = (BCLBeacon *) sender;
        viewController.delegate = self;
    } else if ([segue.identifier isEqualToString:kBCLEmbedBeaconDetailsSegueIdentifier]) {
        self.beaconDetailsViewController = segue.destinationViewController;
        self.beaconDetailsViewController.view.userInteractionEnabled = NO;
        self.beaconDetailsViewController.delegate = self;
    }
}

#pragma mark - UINavigationController Delegate

- (id <UIViewControllerAnimatedTransitioning>)navigationController:(UINavigationController *)navigationController animationControllerForOperation:(UINavigationControllerOperation)operation fromViewController:(UIViewController *)fromVC toViewController:(UIViewController *)toVC {
    if (([toVC isKindOfClass:[BCLBeaconDetailsViewController class]] && fromVC == self) || ([fromVC isKindOfClass:[BCLBeaconDetailsViewController class]] && toVC == self)) {
        return self;
    }
    return nil;
}

#pragma mark - Animated Transitioning

- (NSTimeInterval)transitionDuration:(id <UIViewControllerContextTransitioning>)transitionContext {
    return kBCLTransitionDuration;
}

- (void)animateTransition:(id <UIViewControllerContextTransitioning>)transitionContext {
    __weak BCLMapViewController *weakSelf = self;
    //disable interactions during transition
    self.view.userInteractionEnabled = NO;
    void (^completion)(BOOL finished) = ^(BOOL finished) {
        weakSelf.view.userInteractionEnabled = YES;
    };

    UIViewController *toViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    if ([toViewController isKindOfClass:[BCLBeaconDetailsViewController class]]) {
        [self setState:kBCLMapViewControllerStateShowsBeaconDetails animated:YES completion:^(BOOL finished) {
            [transitionContext completeTransition:![transitionContext transitionWasCancelled]];
            [[transitionContext containerView] addSubview:toViewController.view];
            completion(finished);
        }];
    } else {
        [[transitionContext containerView] addSubview:toViewController.view];
        [transitionContext completeTransition:![transitionContext transitionWasCancelled]];
        [self addChildViewController:self.beaconDetailsViewController];
        [self.containerView addSubview:self.beaconDetailsViewController.view];
        if (self.state == kBCLMapViewControllerStateShowsBeaconDetails) {
            if (self.pinView.hidden) {
                [self setState:kBCLMapViewControllerStateBeaconSelected animated:YES completion:completion];
            } else {
                [self setState:kBCLMapViewControllerStateNewBeacon animated:YES completion:completion];
            }
        } else {
            completion(YES);
        }
    }
}

#pragma mark - Beacon Details View Delegate

- (void)beaconDetailsViewController:(BCLBeaconDetailsViewController *)viewController didSaveNewBeacon:(BCLBeacon *)beacon {

    BCLAnnotation *annotation = [self addAnnotationForBeacon:beacon];
    [self.mapView selectAnnotation:annotation animated:YES];
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)beaconDetailsViewController:(BCLBeaconDetailsViewController *)viewController didEditBeacon:(BCLBeacon *)beacon {
    BCLAnnotation *annotation = self.mapView.selectedAnnotations[0];
    annotation.userInfo = beacon;
    annotation.coordinate = beacon.location.location.coordinate;
    annotation.reuseIdentifier = [NSString stringWithFormat:@"annotationWithBeaconId_%@", beacon.instanceId];
    [self.mapView addAnnotation:annotation];
    [self.mapView selectAnnotation:annotation animated:YES];
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)beaconDetailsViewController:(BCLBeaconDetailsViewController *)controller didDeleteBeacon:(BCLBeacon *)beacon {
    self.currentlyEditedBeacon = nil;
    BCLAnnotation *annotation = self.mapView.selectedAnnotations[0];
    [self.mapView removeAnnotation:annotation];
    [self.mapView deselectAnnotation:annotation animated:NO];
    [self.navigationController popViewControllerAnimated:YES];
}

@end
