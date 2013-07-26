//
//  MapViewController.h
//  Instagrawr
//
//  Created by Brian Eng on 7/25/13.
//  Copyright (c) 2013 Brian Eng. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "Instagram.h"

@class MapViewController;
@protocol MapViewControllerDelegate <NSObject>
- (UIImage *)mapViewController:(MapViewController *)sender imageForAnnotation:(id <MKAnnotation>)annotation;
@end

@interface MapViewController : UIViewController

@property (nonatomic, strong) NSArray *annotations; // of id <MKAnnotation>
@property (nonatomic, weak) id <MapViewControllerDelegate> delegate;

- (void)mapFrameRegion;
@end
