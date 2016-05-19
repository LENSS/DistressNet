//
//  DNetAppDelegate.h
//  DNet
//
//  Created by Harsha on 2/22/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Common.h"
#import "BTagProgrammer.h"

@class DNetViewController;

@interface DNetAppDelegate : NSObject <UIApplicationDelegate,UITabBarControllerDelegate> {
    UIWindow *window;
    UITabBarController *tabBarController;

}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet UITabBarController *tabBarController;
@end

