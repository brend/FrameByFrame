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
	
	NSString *resolutionString;
}

@property (readonly) id<FBMovieSettingsControllerDelegate> delegate;

- (void) beginSheetModalForWindow: (NSWindow *) window;
- (void) endSheet;

@property (copy) NSString *resolutionString;

- (NSDictionary *) composeMovieSettings;

- (IBAction) acceptSettings: (id) sender;

- (BOOL) settingsOK;

@end
