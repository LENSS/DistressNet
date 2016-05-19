//
//  BTagprogrammer-iPad.h
//  DNet
//
//  Created by Harsha on 5/14/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AsyncUdpSocket.h"
#import "LocationController.h"

@interface BTagprogrammer_iPad : UIViewController <UITextFieldDelegate>

{
   	AsyncUdpSocket *listenSocket;
}
- (IBAction)sliderChanged:(id)sender;
@property (retain, nonatomic) IBOutlet UILabel *livingLabel;
@property (retain, nonatomic) IBOutlet UILabel *deadLabel;

@property (retain, nonatomic) IBOutlet UIView *mainview;
@property (retain, nonatomic) IBOutlet UILabel *yourlocationLabel;
@property (retain, nonatomic) IBOutlet UISlider *deadSlider;
@property (retain, nonatomic) IBOutlet UISlider *livingSlider;
@property (retain, nonatomic) IBOutlet UISegmentedControl *hazardChooser;
- (IBAction)programPressed:(id)sender;
@property (retain, nonatomic) IBOutlet UISegmentedControl *taskforceChooser;
@property (retain, nonatomic) IBOutlet UISlider *idSlider;
@property (retain, nonatomic) IBOutlet UILabel *dentlabel;
@property (retain, nonatomic) IBOutlet UILabel *tentlabel;
@property (retain, nonatomic) IBOutlet UILabel *dexitlabel;
@property (retain, nonatomic) IBOutlet UILabel *texitlabel;
@property (retain, nonatomic) IBOutlet UILabel *idLabel;
@property (retain, nonatomic) IBOutlet UITextField *addressField;


@end
