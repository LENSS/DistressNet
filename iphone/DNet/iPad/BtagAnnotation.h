//
//  BtagAnnotation.h
//  DNet
//
//  Created by Harsha on 5/13/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>
#import "Common.h"

@interface BtagAnnotation : NSObject <MKAnnotation>
{
    btag_t _btag;
    CLLocationCoordinate2D _coordinate;
}


@property (nonatomic, readonly) CLLocationCoordinate2D coordinate;

- (id)initWithData:(btagloc_t*) data;


@end
