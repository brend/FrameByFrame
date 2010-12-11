//
//  FBMovieSettingsController.m
//  FrameByFrame
//
//  Created by Philipp Brendel on 27.11.10.
//  Copyright 2010 BrendCorp. All rights reserved.
//

#import "FBMovieSettingsController.h"


@implementation FBMovieSettingsController
@synthesize delegate, settingsSheet;

- (id) init
{
	if ((self = [super init])) {
		self.availableResolutions = [NSArray arrayWithObjects:
									 [NSValue valueWithSize: NSMakeSize(640, 480)], 
									 [NSValue valueWithSize: NSMakeSize(800, 600)], 
									 nil];
	}
	
	return self;
}

- (void) dealloc
{
	delegate = nil;
	[super dealloc];
}

- (void) beginSheetModalForWindow: (NSWindow *) window
{
	[NSApp beginSheet: settingsSheet modalForWindow: window modalDelegate: nil didEndSelector: nil contextInfo: nil];
}

- (void) endSheet
{
	[NSApp endSheet: settingsSheet];
	[settingsSheet orderOut: self];
}

#pragma mark -
#pragma mark Retrieving the Movie Settings
- (NSDictionary *) composeMovieSettings
{
	// TODO: Error handling if (somehow) selectedResolution is (inexplicably) nil
	NSSize resolution = [self.selectedResolution sizeValue];
	
	NSAssert(resolution.width > 0 && resolution.height > 0, @"Invalid resolution");
	
	NSDictionary *settings = [NSDictionary dictionaryWithObjectsAndKeys:
							  [NSNumber numberWithInteger: resolution.width], FBHorizontalResolutionSettingName,
							  [NSNumber numberWithInteger: resolution.height], FBVerticalResolutionSettingName,
							  nil];
	
	return settings;
}

- (IBAction) acceptSettings: (id) sender
{
	if ([self settingsOK]) {
		[self.delegate movieSettingsController: self didSaveSettings: [self composeMovieSettings]];
	}
}

- (IBAction) cancelSettings: (id) sender
{
	[self.delegate movieSettingsControllerDidCancel: self];
}

- (BOOL) settingsOK
{
	NSSize resolution = [self.selectedResolution sizeValue];
	
	return resolution.width > 0 && resolution.height > 0;
}

@synthesize selectedResolution, availableResolutions;

@end
