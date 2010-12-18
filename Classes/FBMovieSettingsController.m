//
//  FBMovieSettingsController.m
//  FrameByFrame
//
//  Created by Philipp Brendel on 27.11.10.
//  Copyright 2010 BrendCorp. All rights reserved.
//

#import "FBMovieSettingsController.h"


@implementation FBMovieSettingsController

#pragma mark -
#pragma mark Initialization and Deallocation
- (id) init
{
	if ((self = [super init])) {
		self.availableResolutions = 
			[NSArray arrayWithObjects:
				 [NSValue valueWithSize: NSMakeSize(640, 480)], 
				 [NSValue valueWithSize: NSMakeSize(800, 600)], 
				 nil];
		if (self.availableResolutions.count > 0)
			self.selectedResolution = [self.availableResolutions objectAtIndex: 0];
	}
	
	return self;
}

- (void) dealloc
{
	delegate = nil;
	[availableResolutions release];
	availableResolutions = nil;
	[super dealloc];
}

#pragma mark -
#pragma mark Delegate
@synthesize delegate;

#pragma mark -
#pragma mark Accessing and Displaying the Sheet
@synthesize settingsSheet;

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
#pragma mark Interface Builder Actions
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

#pragma mark -
#pragma mark Accessing Movie Settings
@synthesize selectedResolution, availableResolutions;

- (BOOL) settingsOK
{
	NSSize resolution = [self.selectedResolution sizeValue];
	
	return resolution.width > 0 && resolution.height > 0;
}

- (NSDictionary *) composeMovieSettings
{
	if (![self settingsOK])
		return nil;
	
	NSSize resolution = [self.selectedResolution sizeValue];
	
	NSAssert(resolution.width > 0 && resolution.height > 0, @"Invalid resolution");
	
	NSMutableDictionary *settings = [NSMutableDictionary dictionaryWithDictionary: [NSDictionary defaultMovieSettings]];
	NSDictionary *localSettings =
		[NSDictionary dictionaryWithObjectsAndKeys:
			[NSNumber numberWithInteger: resolution.width], FBHorizontalResolutionSettingName,
			[NSNumber numberWithInteger: resolution.height], FBVerticalResolutionSettingName,
			nil];
	
	[settings addEntriesFromDictionary: localSettings];
	
	return settings;
}

@end
