//
//  BCLZonesTableViewCell.h
//  BCLRemoteApp
//
// Copyright (c) 2015, Upnext Technologies Sp. z o.o.
// All rights reserved.
//
// This source code is licensed under the BSD 3-Clause License found in the
// LICENSE.txt file in the root directory of this source tree.
//

#import <UIKit/UIKit.h>

@interface BCLZonesTableViewCell : UITableViewCell

@property (nonatomic, strong) IBOutlet UIView * contentWrap;
@property (nonatomic, strong) IBOutlet UIView * colorBar;
@property (nonatomic, strong) IBOutlet UITextField * nameLabel;
@property (nonatomic, strong) IBOutlet UIImageView * checkIcon;
@property (nonatomic, strong) IBOutlet UIButton * saveButton;
@property (nonatomic, strong) IBOutlet UIActivityIndicatorView * indicatorView;

@property (nonatomic, weak) IBOutlet NSLayoutConstraint * nameLabelWidthConstraint;

@end
