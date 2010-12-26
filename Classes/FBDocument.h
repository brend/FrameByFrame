//
//  FBDocument.h
//  FrameByFrame
//
//  Created by Philipp Brendel on 28.10.10.
//  Copyright (c) 2010 BrendCorp. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QTKit/QTKit.h>
#import <QuartzCore/QuartzCore.h>
#import "FBReel.h"
#import "FBReelNavigator.h"
#import "FBDragDropBuddy.h"
#import "FBFilterPipeline.h"
#import "FBProgressSheetController.h"
#import "FBMovieSettingsController.h"

@interface FBDocument : NSDocument <FBReelNavigatorDelegate, 
									FBReelNavigatorDataSource, 
									FBMovieSettingsControllerDelegate, FBDragDropBuddy>
{
	QTCaptureSession *captureSession;
	QTCaptureDecompressedVideoOutput *captureDecompressedVideoOutput;
	IBOutlet QTCaptureView *captureView;
	
	NSArray *inputDevices;
	QTCaptureDeviceInput *videoDeviceInput;
	
	IBOutlet FBReelNavigator *reelNavigator;
	BOOL shouldTakeSnapshot;

	FBReel *reel;
	NSURL *temporaryStorageURL, *originalFileURL;
	NSMutableDictionary *movieSettings;
	
	FBFilterPipeline *filterPipeline;
	NSInteger onionLayerCount, framesPerSecond;
	
	IBOutlet FBProgressSheetController *progressSheetController;
	IBOutlet FBMovieSettingsController *movieSettingsController;
}

#pragma mark -
#pragma mark Retrieving the Document Window
@property (readonly) NSWindow *window;

#pragma mark -
#pragma mark Handling Document Storage
@property (retain) NSURL *temporaryStorageURL, *originalFileURL;
- (NSURL *) createTemporaryURL;
- (NSURL *) movieSettingsURL;
- (void) copyDocumentContents;
- (BOOL) copyDocumentContents: (NSError **) outError;
- (void) documentOpened: (NSError *) error;

#pragma mark -
#pragma mark Video Input Devices
@property (retain) NSArray *inputDevices;
@property (retain) QTCaptureDevice *selectedInputDevice;
- (void) refreshInputDevices;

#pragma mark -
#pragma mark Displaying Video Input
- (CIImage *) view: (QTCaptureView *) view willDisplayImage: (CIImage *) image;
- (void) captureDeviceFormatDescriptionsDidChange: (NSNotification*) notification;

#pragma mark -
#pragma mark Taking Pictures
- (void) createSnapshotFromImage: (CIImage *) image;

#pragma mark -
#pragma mark Exporting Movies
- (void) exportMovieToURL: (NSURL *) fileURL;

#pragma mark -
#pragma mark Managing the Movie Reel
@property (retain) FBReel *reel;
@property (readonly) FBReelNavigator *reelNavigator;

#pragma mark -
#pragma mark Movie Settings
@property (retain) NSMutableDictionary *movieSettings;
@property (retain) FBMovieSettingsController *movieSettingsController;
- (void) applyMovieSettings;

#pragma mark -
#pragma mark Onion Skinning
@property (nonatomic, assign) NSInteger onionLayerCount;
- (NSRange) skinImageRange;
- (NSArray *) skinImages;

#pragma mark -
#pragma mark Frames Per Second
@property NSInteger framesPerSecond;

#pragma mark -
#pragma mark Filter Pipeline
@property (retain) FBFilterPipeline *filterPipeline;
- (void) createFilterPipeline;

#pragma mark -
#pragma mark Displaying the Progress Sheet
@property (retain) FBProgressSheetController *progressSheetController;

#pragma mark -
#pragma mark Reel Navigator Data Source
- (NSInteger) numberOfCellsForReelNavigator: (FBReelNavigator *) navigator;
- (CIImage *) reelNavigator: (FBReelNavigator *) navigator imageForCellAtIndex:(NSInteger)index;
- (NSImage *) reelNavigator: (FBReelNavigator *) navigator thumbnailForCellAtIndex:(NSInteger)index;
- (NSArray *) urlsForImagesAtIndexes: (NSIndexSet *) indexes;

#pragma mark -
#pragma mark Reel Navigator Delegate
- (void) reelNavigatorRequestsSnapshot:(FBReelNavigator *) navigator;
// - (void) reelNavigator: (FBReelNavigator *) navigator didSelectImageAtIndex: (NSUInteger) imageIndex;

#pragma mark -
#pragma mark Movie Settings Controller Delegate
- (void) movieSettingsController: (FBMovieSettingsController *) controller
				 didSaveSettings: (NSDictionary *) settings;
- (void) movieSettingsControllerDidCancel: (FBMovieSettingsController *)controller;

#pragma mark -
#pragma mark Drag Drop Buddy
- (NSArray *) namesOfFilesAtIndexes: (NSIndexSet *) indexes forDestination: (NSURL *) destination;
- (void) insertImages: (NSArray *) images atIndex: (NSUInteger) index;
- (void) moveCellsAtIndexes: (NSIndexSet *) sourceIndexes toIndex: (NSUInteger) destinationIndex;

#pragma mark -
#pragma mark Interface Builder Actions
- (IBAction) snapshot: (id) sender;
- (IBAction) exportMovie: (id) sender;

@end
