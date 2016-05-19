//
//  TweeterClass.h
//  DNet
//
//  Created by Harsha Chenji on 4/2/11.
//  Copyright 2011 Texas A&M. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Common.h"
#import "AsyncUdpSocket.h"
#import "Common.h"


@interface TweeterClass : UIViewController {
    
    UITextField *tweetField;
    UIButton *tweetButton;
    
    AsyncUdpSocket *listenSocket;
    
	NSMutableArray *connectedSockets;
}
@property (nonatomic, retain) IBOutlet UITextField *tweetField;

- (IBAction)tweetAction:(id)sender;

@property (nonatomic, retain) IBOutlet UIButton *tweetButton;

@end
