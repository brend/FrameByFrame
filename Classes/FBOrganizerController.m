//
//  FBOrganizerController.m
//  FrameByFrame
//
//  Created by Philipp Brendel on 22.01.11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "FBOrganizerController.h"
#import "FBDocument.h"

@implementation FBOrganizerController

- (id)init 
{
    if ((self = [super init])) {
		// Make default resolutions available
		self.availableResolutions = 
		[NSArray arrayWithObjects:
		 [NSValue valueWithSize: NSMakeSize(640, 480)],
		 [NSValue valueWithSize: NSMakeSize(800, 450)],
		 [NSValue valueWithSize: NSMakeSize(800, 600)],
		 nil];
		if (self.availableResolutions.count > 0)
			self.selectedPredefinedResolution = [self.availableResolutions objectAtIndex: 0];
		self.customHorizontalResolution = 640;
		self.customVerticalResolution = 480;
    }
    
    return self;
}

- (void)dealloc 
{
//	delegate = nil;
	[availableResolutions release];
	availableResolutions = nil;
    
    [super dealloc];
}

#pragma mark -
#pragma mark Creating a New Movie
@synthesize selectedPredefinedResolution, availableResolutions;
@synthesize useCustomResolution, customHorizontalResolution, customVerticalResolution;

- (BOOL) settingsOK
{
	NSSize resolution = NSZeroSize;
	
	if (self.useCustomResolution) {
		resolution = NSMakeSize(self.customHorizontalResolution, self.customVerticalResolution);
	} else {
		resolution = [self.selectedPredefinedResolution sizeValue];
	}
	
	return resolution.width > 0 && resolution.height > 0;
}

- (NSDictionary *) composeMovieSettings
{
	if (![self settingsOK])
		return nil;
	
	NSSize resolution = NSZeroSize;
	
	if (self.useCustomResolution) {
		resolution = NSMakeSize(self.customHorizontalResolution, self.customVerticalResolution);
	} else {
		resolution = [self.selectedPredefinedResolution sizeValue];
	}	
	
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

- (IBAction) newMovie: (id) sender
{
	if ([self settingsOK]) {
		NSDictionary *movieSettings = [self composeMovieSettings];
		
//		[self.delegate movieSettingsController: self didSaveSettings: [self composeMovieSettings]];
		
        NSDocumentController *controller = [NSDocumentController sharedDocumentController];
		NSError *error = nil;
		FBDocument *document = [controller makeUntitledDocumentOfType: @"FrameByFrame Movie" error: &error];
		
		if (document) {
			// TODO: Do I *really* have to do this manually?
			[document makeWindowControllers];
			[document showWindows];
			
			document.movieSettings = [NSMutableDictionary dictionaryWithDictionary: movieSettings];
		} else
			NSLog(@"Error creating untitled document: %@", error);
	} else {
		NSRunAlertPanel(@"Bad resolution", @"Please select a resolution that is suitable to your camera", @"OK", nil, nil);
	}
}

#pragma mark -
#pragma mark Opening a Recently Used Movie
- (IBAction) openRecent: (id) sender
{
	NSLog(@"TODO Implement FBOrganizerController-openRecent:");
}

@end
