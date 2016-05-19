//
//  UDPListenerTab.h
//  DNet
//
//  Created by Harsha on 2/24/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import "AsyncUdpSocket.h"
#import "Common.h"

@interface LocationSenderClass : UIViewController <CLLocationManagerDelegate>
{
	UITextView * _scrollview;
	UIButton * _startstopButton;
	UILabel * _locLabel;
	UISegmentedControl * _idChooser;
	AsyncUdpSocket *listenSocket;

	NSMutableArray *connectedSockets;
	
	CLLocationManager *_locationManager;
}

@property (nonatomic,retain) IBOutlet UITextView *scrollview;
@property (nonatomic,retain) IBOutlet UILabel *locLabel;
@property (nonatomic,retain) IBOutlet UIButton *startstopButton;
@property (nonatomic,retain) IBOutlet UISegmentedControl *idChooser;
@property (nonatomic,retain) CLLocationManager *locationManager;


- (IBAction) startOrStopAction:(id)sender;

@end