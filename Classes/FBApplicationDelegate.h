//
//  FBApplicationDelegate.h
//  FrameByFrame
//
//  Created by Philipp Brendel on 28.10.10.
//  Copyright (c) 2010 BrendCorp. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "FBCrashRecoveryController.h"

@interface FBApplicationDelegate : NSObject 
{
@private
    IBOutlet NSWindow *crashRecoveryWindow;
	IBOutlet FBCrashRecoveryController *crashRecoveryController;
	
	BOOL applicationHasStarted;
}

#pragma mark -
#pragma mark Registering User Defaults
- (void) registerInitialUserDefaults;

#pragma mark -
#pragma mark Recovering Unsaved Documents
- (void) showCrashRecoveryWindowIfNecessary;

@end
