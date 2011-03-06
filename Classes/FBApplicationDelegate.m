//
//  FBApplicationDelegate.m
//  FrameByFrame
//
//  Created by Philipp Brendel on 28.10.10.
//  Copyright (c) 2010 BrendCorp. All rights reserved.
//

#import "FBApplicationDelegate.h"


@implementation FBApplicationDelegate

- (id)init 
{
    if ((self = [super init])) {
    }
    
    return self;
}

- (void)dealloc 
{
    [super dealloc];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	[self registerInitialUserDefaults];
}

#pragma mark -
#pragma mark Registering User Defaults
- (void) registerInitialUserDefaults
{
	NSString *defaultsPath = [[NSBundle mainBundle] pathForResource: @"InitialUserDefaults" ofType: @"plist"];
	NSDictionary *defaults = [NSDictionary dictionaryWithContentsOfFile: defaultsPath];
	[[NSUserDefaults standardUserDefaults] registerDefaults: defaults];
	[[NSUserDefaultsController sharedUserDefaultsController] setInitialValues: defaults];
}	

#pragma mark -
#pragma mark Presenting the Organizer
- (void) showOrganizer
{
	[organizerController show: nil];
}

@end
