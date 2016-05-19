//
//  BTagProgrammer.h
//  DNet
//
//  Created by Harsha Chenji on 3/5/11.
//  Copyright 2011 Texas A&M. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import "Common.h"
#import "AsyncUdpSocket.h"
#import "BuildingTagClass.h"

@interface BTagProgrammer : UIViewController <UITextFieldDelegate> {
    
	UILabel * _idLabel;
	UISlider * _idSlider;
	UITextField * _addr1Field;
	UITextField * _addr2Field;
	UISegmentedControl * _teamField;
	UILabel * _livingLabel;
	UISlider * _livingSlider;
	UILabel * _deadLabel;
	UISlider * _deadSlider;
	UILabel * _searchLabel;
	UISlider * _searchSlider;
	
    UILabel * _locLabel;
    
	UIButton * _sendButton;
	
	AsyncUdpSocket *listenSocket;
	NSMutableArray *connectedSockets;
}

- (void) doResocket;

@property (nonatomic,retain) IBOutlet UILabel * idLabel;
@property (nonatomic,retain) IBOutlet UILabel * livingLabel;
@property (nonatomic,retain) IBOutlet UILabel * deadLabel;
@property (nonatomic,retain) IBOutlet UILabel * searchLabel;

@property (nonatomic,retain) IBOutlet UISlider * idSlider;
@property (nonatomic,retain) IBOutlet UISlider * livingSlider;
@property (nonatomic,retain) IBOutlet UISlider * deadSlider;
@property (nonatomic,retain) IBOutlet UISlider * searchSlider;

@property (nonatomic,retain) IBOutlet UISegmentedControl * teamField;
@property (nonatomic,retain) IBOutlet UITextField * addr1Field;
@property (nonatomic,retain) IBOutlet UITextField * addr2Field;
@property (nonatomic,retain) IBOutlet UIButton * sendButton;
@property (retain, nonatomic) IBOutlet UILabel *loclabel;
@property (retain, nonatomic) IBOutlet UISegmentedControl *hazardField;

- (IBAction) sliderAction:(id)sender;
- (IBAction) sendAction:(id)sender;

@end
