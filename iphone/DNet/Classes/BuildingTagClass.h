//
//  BuildingTagClass.h
//  DNet
//
//  Created by Harsha on 2/28/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AsyncUdpSocket.h"
#import "Common.h"


@interface BuildingTagClass : UIViewController {	
	AsyncUdpSocket *listenSocket;
	NSMutableArray *connectedSockets;
}


- (void) doResocket;

@property (retain, nonatomic) IBOutletCollection(UITextView) NSArray *allbox;

- (IBAction) clearAction:(id)sender;
- (IBAction) resocketAction:(id)sender;

@end
