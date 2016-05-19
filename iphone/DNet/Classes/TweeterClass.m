//
//  TweeterClass.m
//  DNet
//
//  Created by Harsha Chenji on 4/2/11.
//  Copyright 2011 Texas A&M. All rights reserved.
//

#import "TweeterClass.h"


@implementation TweeterClass
@synthesize tweetButton;
@synthesize tweetField;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)dealloc
{
    [tweetField release];
    [tweetButton release];
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    [self.tweetField setDelegate:self];

	listenSocket = [[AsyncUdpSocket alloc] initWithDelegate:self];
    NSError *error = nil;
    [listenSocket enableBroadcast:TRUE error:&error];
    
    
	connectedSockets = [[NSMutableArray alloc] initWithCapacity:1];
	[listenSocket setRunLoopModes:[NSArray arrayWithObject:NSRunLoopCommonModes]];
}

- (void)viewDidUnload
{
    [self setTweetField:nil];
    [self setTweetButton:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	[textField resignFirstResponder];
	return NO;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (IBAction)tweetAction:(id)sender {
    
    tweet_t mytweet;
    mytweet.to_id = 2;
    strcpy(mytweet.tweet, [self.tweetField.text UTF8String]);

    NSData* usd = [NSData dataWithBytes:(void *) &mytweet length:sizeof(tweet_t)];
    [listenSocket sendData:usd toHost:@"225.0.11.5" port:7010 withTimeout:-1 tag:0];

}
@end
