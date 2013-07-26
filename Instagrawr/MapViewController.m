//
//  MapViewController.m
//  Instagrawr
//
//  Created by Brian Eng on 7/25/13.
//  Copyright (c) 2013 Brian Eng. All rights reserved.
//

#import "MapViewController.h"
#import "AppDelegate.h"

@interface MapViewController () <MKMapViewDelegate>
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (nonatomic) MKCoordinateRegion *annotationRegion;

@end

@implementation MapViewController
@synthesize mapView = _mapView;
@synthesize annotations = _annotations;
@synthesize delegate = _delegate;
@synthesize annotationRegion = _annotationRegion;

- (void)updateMapView
{
    if (self.mapView.annotations) [self.mapView removeAnnotations:self.mapView.annotations];
    if (self.annotations) [self.mapView addAnnotations:self.annotations];
}

- (void)setMapView:(MKMapView *)mapView
{
    _mapView = mapView;
    [self updateMapView];
}

- (void)setAnnotations:(NSArray *)annotations
{
    _annotations = annotations;
    [self updateMapView];
}

- (void)mapFrameRegion
{
    double leastLatitude = 99999;
    double leastLongitude = 99999;
    double mostLatitude = -99999;
    double mostLongitude = -99999;
    //CLLocationCoordinate2D center;
    MKCoordinateRegion mapRegion = self.mapView.region;
    
    // Calculate the boundaries using the extremes among all annotations
    for (id <MKAnnotation> point in self.annotations) {
        if (point.coordinate.latitude < leastLatitude) {
            leastLatitude = point.coordinate.latitude;
        } else if (point.coordinate.latitude > mostLatitude) {
            mostLatitude = point.coordinate.latitude;
        }
        
        if (point.coordinate.longitude < leastLongitude) {
            leastLongitude = point.coordinate.longitude;
        } else if (point.coordinate.longitude > mostLongitude) {
            mostLongitude = point.coordinate.longitude;
        }
    }
    
    // Calculate the geographical center
    mapRegion.center.latitude = (leastLatitude + mostLatitude) / 2;
    mapRegion.center.longitude = (leastLongitude + mostLongitude) / 2;
    
    mapRegion.span.latitudeDelta = (mostLatitude - leastLatitude)*1.05;
    mapRegion.span.longitudeDelta = (mostLongitude - leastLongitude)*1.05;
    
    NSLog(@"Least: (%g,%g), Most: (%g,%g)",leastLatitude, leastLongitude, mostLatitude, mostLongitude);
    
    //[self.mapView setCenterCoordinate:center animated:YES];
    if (leastLatitude != 99999 && leastLongitude != 99999 && mostLatitude != -99999 && mostLongitude != -99999) [self.mapView setRegion:mapRegion animated:YES];
    
}

#pragma mark - MKMapViewDelegate

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation
{
    MKAnnotationView *aView = [mapView dequeueReusableAnnotationViewWithIdentifier:@"MapVC"];
    if (!aView) {
        aView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"MapVC"];
        aView.canShowCallout = YES;
        aView.leftCalloutAccessoryView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 30, 30)];
    }
    
    aView.annotation = annotation;
    [(UIImageView *)aView.leftCalloutAccessoryView setImage:nil];
    
    return aView;
}

- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)aView
{
    UIImage *image = [self.delegate mapViewController:self imageForAnnotation:aView.annotation];
    [(UIImageView *)aView.leftCalloutAccessoryView setImage:image];
}

- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control
{
    NSLog(@"callout accessory tapped for annotation %@", [view.annotation title]);
}

#pragma mark - View Controller Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    self.mapView.delegate = self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self mapFrameRegion];
}

@end
