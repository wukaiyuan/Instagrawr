//
//  PhotoListTableViewController.m
//  Instagrawr
//
//  Created by Brian Eng on 7/25/13.
//  Copyright (c) 2013 Brian Eng. All rights reserved.
//

#import "PhotoListTableViewController.h"
#import "AppDelegate.h"
#import "MapViewController.h"

static TTTTimeIntervalFormatter *timeFormatter;

@interface PhotoListTableViewController () <MapViewControllerDelegate>

@property(nonatomic, strong) NSArray* data;

@end

@implementation PhotoListTableViewController
@synthesize data = _data;
@synthesize photos = _photos;
@synthesize photoID = _photoID;

- (void)setPhotos:(NSArray *)photos
{
    if (_photos != photos) {
        _photos = photos;
        // Model changed, so update our View (the table)
        if ([self splitViewController]) {
            [self updateSplitViewDetail];
        }
        
        if (self.tableView.window) [self.tableView reloadData];
    }
}

- (void)updateSplitViewDetail
{
    id detail = [self.splitViewController.viewControllers lastObject];
    if ([detail isKindOfClass:[MapViewController class]]) {
        MapViewController *mapVC = (MapViewController *)detail;
        mapVC.delegate = self;
        mapVC.annotations = [self mapAnnotations];
        [mapVC mapFrameRegion];
    }
}

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Logic to test if a user is logged in, otherwise authenticate
    AppDelegate* appDelegate = (AppDelegate*)[UIApplication sharedApplication].delegate;
    
    appDelegate.instagram.accessToken = [[NSUserDefaults standardUserDefaults] objectForKey:@"accessToken"];
    appDelegate.instagram.sessionDelegate = self;
    if ([appDelegate.instagram isSessionValid]) {
        UIBarButtonItem* loginButton = [[UIBarButtonItem alloc] initWithTitle:@"Logout"
                                                                        style:UIBarButtonItemStyleBordered
                                                                       target:self
                                                                       action:@selector(doLogout)];
        self.navigationItem.leftBarButtonItem = loginButton;
    } else {
        [appDelegate.instagram authorize:[NSArray arrayWithObjects:@"comments", @"likes", nil]];
    }
    
    // Initial data lookup to populate the table
    NSMutableDictionary* params = [NSMutableDictionary dictionaryWithObjectsAndKeys:@"users/self/media/recent", @"method", nil];
    [appDelegate.instagram requestWithParams:params
                                    delegate:self];
}

-(void)login {
    AppDelegate* appDelegate = (AppDelegate*)[UIApplication sharedApplication].delegate;
    [appDelegate.instagram authorize:[NSArray arrayWithObjects:@"comments", @"likes", nil]];
    // Change the button to Logout and reset table view
}

-(void)doLogout {
    AppDelegate* appDelegate = (AppDelegate*)[UIApplication sharedApplication].delegate;
    [appDelegate.instagram logout];
    // Change the button to Login and reset table view
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    NSLog(@"%d rows", [self.data count]);
    return [self.data count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    // Configure the cell...
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                      reuseIdentifier:CellIdentifier];
    }
    NSLog(@"Populating cell");
    //cell.textLabel.text = [[self.data objectAtIndex:indexPath.row] objectForKey:@"created_time"];
    if (!timeFormatter) {
        timeFormatter = [[TTTTimeIntervalFormatter alloc] init];
    }
    int created_time = [[[self.data objectAtIndex:indexPath.row] objectForKey:@"created_time"] integerValue];
    NSDate *createdAt = [[NSDate alloc] initWithTimeIntervalSince1970:created_time];
    cell.textLabel.text = [timeFormatter stringForTimeIntervalFromDate:[NSDate date] toDate:createdAt];
    cell.detailTextLabel.text = [[[self.data objectAtIndex:indexPath.row] objectForKey:@"caption"] objectForKey:@"text"];
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    self.photoID = [self.data objectAtIndex:indexPath.row];
    
    // Shouldn't need to segue for this
    // Just do the geo data lookup here and map the annotations
    AppDelegate* appDelegate = (AppDelegate*)[UIApplication sharedApplication].delegate;
    
    NSMutableDictionary* params = [NSMutableDictionary dictionaryWithObjectsAndKeys:@"media/search", @"method", @"lat", lat, @"lng", lng, @"min_timestamp", min_timestamp, @"max_timestamp", max_timestamp , nil];
    [appDelegate.instagram requestWithParams:params
                                    delegate:self];
}

#pragma mark - Mapping and Annotating

// Need to fix this
- (NSArray *)mapAnnotations
{
    NSMutableArray *annotations = [NSMutableArray arrayWithCapacity:[self.photos count]];
    for (NSDictionary *photo in self.photos) {
        // Add the annotation here
        //[annotations addObject:[FlickrPhotoAnnotation annotationForPhoto:photo]];
    }
    return annotations;
}

#pragma mark - MapViewControllerDelegate
// Need to fix this
- (UIImage *)mapViewController:(MapViewController *)sender imageForAnnotation:(id <MKAnnotation>)annotation
{
    // Fix this part
    FlickrPhotoAnnotation *fpa = (FlickrPhotoAnnotation *)annotation;
    NSURL *url = [FlickrFetcher urlForPhoto:fpa.photo format:FlickrPhotoFormatSquare];
    
    // Logic to load from cache or from web
    NSString *photoFilename = [url lastPathComponent];
    NSFileManager *photoFileManager = [NSFileManager defaultManager];
    NSURL *photoFilepath = [[photoFileManager URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask] lastObject];
    photoFilepath = [photoFilepath URLByAppendingPathComponent:photoFilename];
    NSLog(@"Filepath: %@", [photoFilepath absoluteString]);
    
    // Branch this guy off
    NSData *imageData = [[NSData alloc] init];
    if ([photoFileManager fileExistsAtPath:[photoFilepath path]]) {
        imageData = [NSData dataWithContentsOfURL:photoFilepath];
        NSLog(@"We are loading the saved file");
    } else {
        // This is the line that calls from web or file
        imageData = [NSData dataWithContentsOfURL:url];
        NSLog(@"We are loading the web image");
        
        // Manage the cache and save the data if it's new
        [imageData writeToURL:photoFilepath atomically:YES];
    }
    
    //NSData *data = [NSData dataWithContentsOfURL:url];
    return imageData ? [UIImage imageWithData:imageData] : nil;
}

#pragma mark - IGRequestDelegate

- (void)request:(IGRequest *)request didFailWithError:(NSError *)error {
    NSLog(@"Instagram did fail: %@", error);
    UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:@"Error"
                                                        message:[error localizedDescription]
                                                       delegate:nil
                                              cancelButtonTitle:@"Ok"
                                              otherButtonTitles:nil];
    [alertView show];
}

- (void)request:(IGRequest *)request didLoad:(id)result {
    NSLog(@"Instagram did load: %@", result);
    self.data = (NSArray*)[result objectForKey:@"data"];
    [self.tableView reloadData];
}

#pragma - IGSessionDelegate

-(void)igDidLogin {
    NSLog(@"Instagram did login");
    // here i can store accessToken
    AppDelegate* appDelegate = (AppDelegate*)[UIApplication sharedApplication].delegate;
    [[NSUserDefaults standardUserDefaults] setObject:appDelegate.instagram.accessToken forKey:@"accessToken"];
	[[NSUserDefaults standardUserDefaults] synchronize];
    
    // Do any changes to interface after login
}

-(void)igDidNotLogin:(BOOL)cancelled {
    NSLog(@"Instagram did not login");
    NSString* message = nil;
    if (cancelled) {
        message = @"Access cancelled!";
    } else {
        message = @"Access denied!";
    }
    UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:@"Error"
                                                        message:message
                                                       delegate:nil
                                              cancelButtonTitle:@"Ok"
                                              otherButtonTitles:nil];
    [alertView show];
}

-(void)igDidLogout {
    NSLog(@"Instagram did logout");
    // remove the accessToken
    [[NSUserDefaults standardUserDefaults] setObject:nil forKey:@"accessToken"];
	[[NSUserDefaults standardUserDefaults] synchronize];
}

-(void)igSessionInvalidated {
    NSLog(@"Instagram session was invalidated");
}

@end
