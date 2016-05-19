//
//  BTagviewer-iPad.h
//  DNet
//
//  Created by Harsha on 5/13/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>
#import "AsyncUdpSocket.h"
#import "Common.h"
#import "LocationController.h"


@interface BTagviewer_iPad : UIViewController <MKMapViewDelegate>
{
    AsyncUdpSocket *listenSocket;
    MKMapView *mainmap;
   	UILabel * _locLabel;

}
- (void) doResocket;
- (IBAction)switchmaptypePressed:(id)sender;
- (void) locUP:(NSNotification *) notifi;

@property (retain, nonatomic) IBOutlet UIImageView *streetmapimage;
@property (retain, nonatomic) IBOutlet UITextView *textviewforbtag;

- (IBAction)removeallPressed:(id)sender;
- (IBAction)pressedLocate:(id)sender;
@property (retain, nonatomic) IBOutlet MKMapView *mainmap;
@property (nonatomic,retain) IBOutlet UILabel *locLabel;

@end
