//
//  FogStore.m
//  DNet
//
//  Created by Harsha on 11/14/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "FogStore.h"

@implementation FogStore
@synthesize listButton = _listButton;
@synthesize textview = _textview;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
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
    _sock = [[AsyncSocket alloc] initWithDelegate:self];
    
    [_sock connectToHost:@"192.168.2.1" onPort:7003 error:nil];
    self.textview.text = @"starting app\n";

}

- (void)viewDidUnload
{
    [self setListButton:nil];
    [self setTextview:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)dealloc {
    [_listButton release];
    [_textview release];
    [super dealloc];
}
- (IBAction)listAct:(id)sender {
    
    const char bytes[] = "GET\r\n";
    size_t length = (sizeof bytes) - 1; //string literals have implicit trailing '\0'
    
    NSData *data = [NSData dataWithBytes:bytes length:length];
    
    [_sock writeData:data withTimeout:-1 tag:0];

    
    const char endbytes[] = "\r\n";
    size_t endlength = (sizeof endbytes) - 1; //string literals have implicit trailing '\0'
    
    NSData *enddata = [NSData dataWithBytes:endbytes length:endlength];
    [_sock readDataToData:enddata withTimeout:-1 tag:0];
    
    
}

- (IBAction)getButtonAction:(id)sender {

    const char bytes[] = "GET file1.txt\r\n";
    size_t length = (sizeof bytes) - 1; //string literals have implicit trailing '\0'
    
    NSData *data = [NSData dataWithBytes:bytes length:length];
    
    [_sock writeData:data withTimeout:-1 tag:0];
    
    
    const char endbytes[] = "\r\n";
    size_t endlength = (sizeof endbytes) - 1; //string literals have implicit trailing '\0'
    
    NSData *enddata = [NSData dataWithBytes:endbytes length:endlength];
    [_sock readDataToData:enddata withTimeout:-1 tag:1];
    
    
}

- (void) appendTxt:(NSString *) string 
{
	self.textview.text = [NSString stringWithFormat:@"%@%@", self.textview.text, string];
}


- (void)onSocket:(AsyncSocket *)sender didReadData:(NSData *)data withTag:(long)tag
{
    if (tag == 0)
    {   NSString *someString = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
        [self appendTxt:someString];
    }

    if (tag == 1)
    {   NSString *someString = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
        self.textview.text = someString;
    }
}

@end
