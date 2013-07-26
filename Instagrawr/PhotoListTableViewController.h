//
//  PhotoListTableViewController.h
//  Instagrawr
//
//  Created by Brian Eng on 7/25/13.
//  Copyright (c) 2013 Brian Eng. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Instagram.h"
#import "TTTTimeIntervalFormatter.h"

@interface PhotoListTableViewController : UITableViewController <IGSessionDelegate>

@property (nonatomic, strong) NSArray *photos; // of Instagram photo dictionaries
@property (nonatomic, strong) NSDictionary *photoID;

@end
