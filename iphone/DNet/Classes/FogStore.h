//
//  FogStore.h
//  DNet
//
//  Created by Harsha on 11/14/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AsyncSocket.h"

@interface FogStore : UIViewController
{
	UITextView * _textview;
	UIButton * _listButton;
    AsyncSocket * _sock;
    
	NSMutableArray *connectedSockets;
	
}


@property (retain, nonatomic) IBOutlet UIButton *listButton;
@property (retain, nonatomic) IBOutlet UITextView *textview;

- (IBAction)listAct:(id)sender;
- (IBAction)getButtonAction:(id)sender;

@end
