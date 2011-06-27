//
//  FBApplicationDelegate.h
//  FrameByFrame
//
//  Created by Philipp Brendel on 28.10.10.
//  Copyright (c) 2010 BrendCorp. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "FBOrganizerController.h"

@interface FBApplicationDelegate : NSObject 
{
	IBOutlet FBOrganizerController *organizerController;
}

#pragma mark -
#pragma mark Registering User Defaults
- (void) registerInitialUserDefaults;

#pragma mark -
#pragma mark Presenting the Organizer
- (void) showOrganizer;

#pragma mark -
#pragma mark Presenting Help
- (IBAction) showHelp: (id) sender;

@end
