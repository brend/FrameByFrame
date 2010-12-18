//
//  FBMovieSettingsController.h
//  FrameByFrame
//
//  Created by Philipp Brendel on 27.11.10.
//  Copyright 2010 BrendCorp. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "FBMovieSettingsControllerDelegate.h"

@interface FBMovieSettingsController : NSObject 
{
	IBOutlet NSWindow *settingsSheet;
	IBOutlet id<FBMovieSettingsControllerDelegate> delegate;
	
	NSArray *availableResolutions;
	NSValue *selectedPredefinedResolution;
	
	BOOL useCustomResolution;
	NSInteger customHorizontalResolution, customVerticalResolution;
}

#pragma mark -
#pragma mark Delegate
@property (readonly) id<FBMovieSettingsControllerDelegate> delegate;

#pragma mark -
#pragma mark Accessing and Displaying the Sheet
@property (readonly) NSWindow *settingsSheet;
- (void) beginSheetModalForWindow: (NSWindow *) window;
- (void) endSheet;

#pragma mark -
#pragma mark Accessing Movie Settings
@property BOOL useCustomResolution;
@property NSInteger customHorizontalResolution, customVerticalResolution;

@property (retain) NSValue *selectedPredefinedResolution;
@property (copy) NSArray *availableResolutions;
- (NSDictionary *) composeMovieSettings;
- (BOOL) settingsOK;

#pragma mark -
#pragma mark Interface Builder Actions
- (IBAction) acceptSettings: (id) sender;
- (IBAction) cancelSettings: (id) sender;

@end
