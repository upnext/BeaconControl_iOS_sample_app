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
#import "BCLBeaconCtrlAdmin.h"
#import "BeaconCtrlManager.h"
#import "UIViewController+BCLActivityIndicator.h"

@interface BCLVendorChoiceViewController () <UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, strong) NSArray *vendors;

@end

@implementation BCLVendorChoiceViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.tableView.tableFooterView = [UIView new];
    [self fetchVendors];
}

- (void)fetchVendors
{
    [self showActivityIndicatorViewAnimated:YES];
    __weak typeof(self) weakSelf = self;
    [[BeaconCtrlManager sharedManager].beaconCtrlAdmin fetchVendors:^(NSArray *array, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf hideActivityIndicatorViewAnimated:YES];
            if (!error) {
                weakSelf.vendors = array;
                [weakSelf.tableView reloadData];
            } else {
                UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Error" message:@"Failed to get vendors list" preferredStyle:UIAlertControllerStyleAlert];
                [alertController addAction:[UIAlertAction actionWithTitle:@"Retry" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                    [weakSelf fetchVendors];
                }]];

                [alertController addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
                    [weakSelf cancelButtonPressed:weakSelf];
                }]];

                [weakSelf presentViewController:alertController animated:YES completion:nil];
            }
        });
    }];
}

- (void)setSelectedVendor:(NSString *)selectedVendor
{
    _selectedVendor = selectedVendor;
}

- (NSUInteger)selectedVendorIndex
{
    NSUInteger vendorIndex = [self.vendors indexOfObject:self.selectedVendor];
    if (vendorIndex == NSNotFound) {
        vendorIndex = [self.vendors indexOfObject:@"Other"];
        if (vendorIndex == NSNotFound) {
            vendorIndex = 0;
        }
    }

    return vendorIndex;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.vendors.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *vendorName = self.vendors[(NSUInteger) indexPath.row];
    BCLVendorCell *vendorCell = (BCLVendorCell *) [tableView dequeueReusableCellWithIdentifier:@"vendorCell"];
    vendorCell.active = [self indexPathShouldBeSelectable:indexPath];
    if (!vendorCell.active) {
        vendorName = [vendorName stringByAppendingString:@" (Use Admin Panel)"];
    }
    [vendorCell setVendorName:vendorName selected:(self.selectedVendorIndex == indexPath.row)];
    return vendorCell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self indexPathShouldBeSelectable:indexPath]) {
        self.selectedVendor = self.vendors[indexPath.row];
        [tableView reloadData];
    }
}

- (BOOL)indexPathShouldBeSelectable:(NSIndexPath *)indexPath
{
    NSString *vendorName = self.vendors[(NSUInteger) indexPath.row];
    return ![[vendorName lowercaseString] isEqualToString:@"kontakt"];
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
