//
//  DNetViewController.h
//  DNet
//
//  Created by Harsha on 2/22/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AsyncUdpSocket.h"
#import <MessageUI/MFMailComposeViewController.h>

#define MAX_NBR_NUM 3

struct ntableentry
{
	uint8_t idee;
	uint8_t age;
	float state;
};
typedef struct ntableentry NEntry;

struct cutdet 
{
	uint8_t myid;
	CFSwappedFloat32 state;
}__attribute__ ((packed));

@interface CutDetectionClass : UIViewController <MFMailComposeViewControllerDelegate> {
	UITextView *_scrollview;
	UIButton *_startstopButton;
   	UIButton *_emailButton;
	UISegmentedControl * _roleChooser;
	AsyncUdpSocket *listenSocket;
	NSMutableArray *connectedSockets;
	UILabel * _currStateLabel;
	NEntry nbr[MAX_NBR_NUM];
}

@property (nonatomic,retain) IBOutlet UITextView *scrollview;
@property (nonatomic,retain) IBOutlet UIButton *startstopButton;
@property (nonatomic,retain) IBOutlet UIButton *emailButton;
@property (nonatomic,retain) IBOutlet UISegmentedControl *roleChooser;
@property (nonatomic,retain) IBOutlet UILabel *currStateLabel;

- (IBAction) startOrStopAction:(id)sender;
- (IBAction) emailAction:(id)sender;
@end

