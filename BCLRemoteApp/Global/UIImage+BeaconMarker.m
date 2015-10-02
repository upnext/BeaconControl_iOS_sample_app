//
//  UIImage+Color.m
//  BCLRemoteApp
//
// Copyright (c) 2015, Upnext Technologies Sp. z o.o.
// All rights reserved.
//
// This source code is licensed under the BSD 3-Clause License found in the
// LICENSE.txt file in the root directory of this source tree.
//

#import "UIImage+BeaconMarker.h"

@implementation UIImage (BeaconMarker)

+ (UIImage *)beaconMarkerWithColor:(UIColor *)color highlighted:(BOOL)highlighted needsUpdate:(BOOL)needsUpdate
{
    // load the image
    UIImage *image = [UIImage imageNamed:highlighted ? @"marker_highlighted" : @"beacon"];
    UIImage *backgroundImage = [UIImage imageNamed:needsUpdate ?  @"beaconBackgroundRed" : @"beaconBackground"];

    UIGraphicsBeginImageContextWithOptions(image.size, NO, image.scale);
    CGContextRef context = UIGraphicsGetCurrentContext();
    [backgroundImage drawAtPoint:CGPointZero];
    [color setFill];
    CGContextTranslateCTM(context, 0, image.size.height);
    CGContextScaleCTM(context, 1.0, -1.0);
    CGContextClipToMask(context, CGRectMake(0, 0, image.size.width, image.size.height), [image CGImage]);
    CGContextFillRect(context, CGRectMake(0, 0, image.size.width, image.size.height));

    UIImage *coloredImg = UIGraphicsGetImageFromCurrentImageContext();

    UIGraphicsEndImageContext();

    //return the color-burned image
    return coloredImg;
}

@end
