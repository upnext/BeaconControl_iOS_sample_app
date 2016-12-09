//
//  BCLAnnotation.h
//  BCLRemoteApp
//
//  Created by minh on 17/11/16.
//  Copyright © 2016 UpNext. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BCLBeacon.h"
@import Mapbox;

@interface BCLAnnotation : NSObject <MGLAnnotation>

@property (nonatomic, assign) CLLocationCoordinate2D coordinate;
@property (nonatomic, strong, nullable) BCLBeacon* userInfo;
@property (nonatomic, copy, nonnull) NSString *reuseIdentifier;

@end
