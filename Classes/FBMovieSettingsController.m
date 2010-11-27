//
//  FBMovieSettingsController.m
//  FrameByFrame
//
//  Created by Philipp Brendel on 27.11.10.
//  Copyright 2010 BrendCorp. All rights reserved.
//

#import "FBMovieSettingsController.h"


@implementation FBMovieSettingsController
@synthesize resolutionString;

- (void) beginSheetModalForWindow: (NSWindow *) window
{
	[NSApp beginSheet: settingsSheet modalForWindow: window modalDelegate: nil didEndSelector: nil contextInfo: nil];
}

#pragma mark -
#pragma mark Retrieving the Movie Settings
- (NSDictionary *) composeMovieSettings
{
	NSSize resolution = NSSizeFromString(self.resolutionString);
	
	NSAssert(resolution.width > 0 && resolution.height > 0, @"Invalid resolution");
	
	NSDictionary *settings = [NSDictionary dictionaryWithObjectsAndKeys:
							  [NSValue valueWithSize: resolution], FBResolutionSettingName,
							  nil];
	
	return settings;
}

- (IBAction) acceptSettings: (id) sender
{
	if ([self settingsOK]) {
		[settingsSheet orderOut: self];
	}
}

- (BOOL) settingsOK
{
	NSSize resolution = NSSizeFromString(self.resolutionString);
	
	return resolution.width > 0 && resolution.height > 0;
}

@end
