//
//  FBOrganizerController.h
//  FrameByFrame
//
//  Created by Philipp Brendel on 22.01.11.
//  Copyright 2011 BrendCorp. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FBCrashRecoveryController.h"

@interface FBOrganizerController : NSObject <NSTableViewDataSource, NSTableViewDelegate>
{
@private
	IBOutlet NSWindow *window;
	IBOutlet NSTableView *recentDocumentsView;
	IBOutlet NSTabView *organizerTabs;
	IBOutlet FBCrashRecoveryController *crashRecovery;
	IBOutlet NSToolbar *organizerBar;
	IBOutlet NSToolbarItem *documentRecoveryItem;
		
   	NSArray *availableResolutions;
	NSValue *selectedPredefinedResolution;
	
	BOOL useCustomResolution;
	NSInteger customHorizontalResolution, customVerticalResolution;
	
	NSArray *recentDocuments;
	NSIndexSet *recentDocumentsSelection;
}

#pragma mark -
#pragma mark Presenting the Organizer
- (IBAction) show: (id) sender;

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
- (NSImage *) thumbnailForDocumentAtURL: (NSURL *) url;

#pragma mark -
#pragma mark Handling Unsaved Movies
- (IBAction) openUnsaved: (id) sender;
- (IBAction) deleteUnsaved: (id) sender;

#pragma mark -
#pragma mark Toolbar Actions
- (IBAction) toolbarNewDocument: (id) sender;
- (IBAction) toolbarOpenDocument: (id) sender;
- (IBAction) toolbarRecoverDocument: (id) sender;

#pragma mark -
#pragma mark Resizing the Window
- (void) setFrameSize: (NSSize) newSize resizable: (BOOL) resize;

#pragma mark -
#pragma mark Auxiliary Actions
- (IBAction) noOp: (id) sender;

@end
