//
//  BTagMapView.h
//  DNet
//
//  Created by Harsha on 5/8/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

#import "LocationSenderClass.h"

@interface BTagMapView : UIViewController <MKMapViewDelegate>
{
    MKMapView *mainmap;
    
}

@property (retain, nonatomic) IBOutlet MKMapView *mainmap;

@end
