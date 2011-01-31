//
//  FBOrganizerController.h
//  FrameByFrame
//
//  Created by Philipp Brendel on 22.01.11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FBCrashRecoveryController.h"

@interface FBOrganizerController : NSObject 
{
@private
	IBOutlet NSWindow *window;
	IBOutlet NSTableView *recentDocumentsView;
	IBOutlet NSTabView *organizerTabs;
	IBOutlet FBCrashRecoveryController *crashRecovery;
	
   	NSArray *availableResolutions;
	NSValue *selectedPredefinedResolution;
	
	BOOL useCustomResolution;
	NSInteger customHorizontalResolution, customVerticalResolution;
	
	NSArray *recentDocuments;
	NSIndexSet *recentDocumentsSelection;
}

#pragma mark -
#pragma mark Creating a New Movie
@property BOOL useCustomResolution;
@property NSInteger customHorizontalResolution, customVerticalResolution;

@property (retain) NSValue *selectedPredefinedResolution;
@property (copy) NSArray *availableResolutions;
- (NSDictionary *) composeMovieSettings;
- (BOOL) settingsOK;

- (IBAction) newMovie: (id) sender;

#pragma mark -
#pragma mark Opening a Recently Used Movie
@property (copy) NSArray *recentDocuments;
@property (retain) NSIndexSet *recentDocumentsSelection;
- (IBAction) openRecent: (id) sender;

#pragma mark -
#pragma mark Handling Unsaved Movies
- (IBAction) openUnsaved: (id) sender;
- (IBAction) deleteUnsaved: (id) sender;

#pragma mark -
#pragma mark Toolbar Actions
- (IBAction) toolbarNewDocument: (id) sender;
- (IBAction) toolbarOpenDocument: (id) sender;
- (IBAction) toolbarRecoverDocument: (id) sender;

@end
