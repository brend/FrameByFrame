//
//  FBOrganizerController.h
//  FrameByFrame
//
//  Created by Philipp Brendel on 22.01.11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface FBOrganizerController : NSObject 
{
@private
   	NSArray *availableResolutions;
	NSValue *selectedPredefinedResolution;
	
	BOOL useCustomResolution;
	NSInteger customHorizontalResolution, customVerticalResolution;
	
	NSArray *recentDocuments;
	NSIndexSet *recentDocumentsSelection;
}

//#pragma mark -
//#pragma mark Delegate
//@property (readonly) id<FBMovieSettingsControllerDelegate> delegate;

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
@property (readonly) NSArray *recentDocuments;
@property (retain) NSIndexSet *recentDocumentsSelection;
- (IBAction) openRecent: (id) sender;

//#pragma mark -
//#pragma mark Interface Builder Actions
//- (IBAction) acceptSettings: (id) sender;
//- (IBAction) cancelSettings: (id) sender;

@end
