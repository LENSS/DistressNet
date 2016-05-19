//
//  BtagAnnotation.m
//  DNet
//
//  Created by Harsha on 5/13/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "BtagAnnotation.h"

@implementation BtagAnnotation

@synthesize coordinate = _coordinate;

- (id)initWithData:(btagloc_t*)data {
    if ((self = [super init])) {
        
        memcpy(&_btag, &data->the_btag, sizeof(btag_t));
        
        CLLocationCoordinate2D temper;
        CFSwappedFloat32 lala;
        lala.v = data->location.loc_x;
        
        temper.latitude = CFConvertFloat32SwappedToHost(lala);
        lala.v = data->location.loc_y;
        temper.longitude = CFConvertFloat32SwappedToHost(lala);
        
        _coordinate = temper;
     
        _btag.mote_id = ntohs(_btag.mote_id);
        
    }
    return self;
}

- (NSString *)title {
    
    return FORMAT(@"BTAG %d\n", _btag.mote_id);

}

- (NSString *)subtitle {
    
        
    
    return FORMAT(@"%+.6f %+.6f\n #%d %s %s ent: %s %s ext: %s %s haz %s, %d Alive %d Dead", _coordinate.latitude, _coordinate.longitude, _btag.mote_id, _btag.address, _btag.task_force, _btag.date_entered, _btag.time_entered, _btag.date_exited, _btag.time_exited, _btag.hazards, _btag.living, _btag.dead);
    

}
@end
