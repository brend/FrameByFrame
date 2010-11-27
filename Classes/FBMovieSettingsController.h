//
//  FBMovieSettingsController.h
//  FrameByFrame
//
//  Created by Philipp Brendel on 27.11.10.
//  Copyright 2010 BrendCorp. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface FBMovieSettingsController : NSObject 
{
	IBOutlet NSWindow *settingsSheet;
	
	NSString *resolutionString;
}

- (void) beginSheetModalForWindow: (NSWindow *) window;

@property (copy) NSString *resolutionString;

- (NSDictionary *) composeMovieSettings;

- (IBAction) acceptSettings: (id) sender;

- (BOOL) settingsOK;

@end
