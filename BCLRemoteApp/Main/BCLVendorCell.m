//
//  BCLVendorCell.m
//  BCLRemoteApp
//
// Copyright (c) 2015, Upnext Technologies Sp. z o.o.
// All rights reserved.
//
// This source code is licensed under the BSD 3-Clause License found in the
// LICENSE.txt file in the root directory of this source tree.
//

#import "BCLVendorCell.h"

@interface BCLVendorCell()

@property (weak, nonatomic) IBOutlet UIView *checkmark;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;

@end

@implementation BCLVendorCell

- (void)setVendorName:(NSString *)vendorName selected:(BOOL)selected
{
    self.checkmark.hidden = !selected;
    self.nameLabel.text = vendorName;
}

- (void)setActive:(BOOL)active
{
    _active = active;
    self.nameLabel.textColor = active ? [UIColor blackColor] : [UIColor lightGrayColor];
}

@end
