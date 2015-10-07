//
//  BCLVendorChoiceViewController.m
//  BCLRemoteApp
//
// Copyright (c) 2015, Upnext Technologies Sp. z o.o.
// All rights reserved.
//
// This source code is licensed under the BSD 3-Clause License found in the
// LICENSE.txt file in the root directory of this source tree.
//

#import "BCLVendorChoiceViewController.h"
#import "BCLVendorCell.h"

@interface BCLVendorChoiceViewController () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic) NSUInteger selectedVendorIndex;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end

static NSArray *_vendors;
static const NSUInteger BCLKontaktVendorIndex = 7;

@implementation BCLVendorChoiceViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.tableView.tableFooterView = [UIView new];
}

- (NSArray *)vendors
{
    if (!_vendors) {
        _vendors = @[
                @"Other",
                @"BlueCats",
                @"BlueSense",
                @"Estimote",
                @"Gelo",
                @"Glimworm",
                @"Gimbal by Qualcomm",
                @"Kontakt (Use Admin Panel)",
                @"Sensorberg",
                @"Sonic Notify"
        ];
    }

    return _vendors;
}

- (void)setSelectedVendor:(NSString *)selectedVendor
{
    _selectedVendor = selectedVendor;
    NSUInteger vendorIndex = [self.vendors indexOfObject:selectedVendor];
    if (vendorIndex == NSNotFound) {
        vendorIndex = self.vendors.count - 1;
    }

    self.selectedVendorIndex = vendorIndex;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.vendors.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *vendorName = self.vendors[(NSUInteger) indexPath.row];
    BCLVendorCell *vendorCell = (BCLVendorCell *) [tableView dequeueReusableCellWithIdentifier:@"vendorCell"];
    [vendorCell setVendorName:vendorName selected:(self.selectedVendorIndex == indexPath.row)];
    vendorCell.active = indexPath.row != BCLKontaktVendorIndex;
    return vendorCell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row != BCLKontaktVendorIndex) {
        self.selectedVendor = self.vendors[indexPath.row];
        [tableView reloadData];
    }
}

- (IBAction)doneButtonPressed:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(vendorChoiceViewController:didChooseVendor:)]) {
        [self.delegate vendorChoiceViewController:self didChooseVendor:self.selectedVendor];
    }
}

- (IBAction)cancelButtonPressed:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(vendorChoiceViewControllerDidCancel:)]) {
        [self.delegate vendorChoiceViewControllerDidCancel:self];
    }
}

@end
