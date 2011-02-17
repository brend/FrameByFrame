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
#import "FBProductPipeline.h"
#import "FBProgressSheetController.h"
#import "FBPreviewController.h"

@interface FBDocument : NSDocument <FBReelNavigatorDelegate, 
									FBReelNavigatorDataSource, 
									FBDragDropBuddy>
{
@private
	QTCaptureSession *captureSession;
	QTCaptureDecompressedVideoOutput *captureDecompressedVideoOutput;
	IBOutlet QTCaptureView *captureView;
	
	NSArray *inputDevices;
	QTCaptureDeviceInput *videoDeviceInput;
	
	IBOutlet FBReelNavigator *reelNavigator;
	NSInteger mirroring;
	CIImage *currentFrame;
	FBProductPipeline *productPipeline;

	FBReel *reel;
	NSURL *temporaryStorageURL, *originalFileURL;
	NSMutableDictionary *movieSettings;
	
	FBFilterPipeline *filterPipeline;
	NSInteger onionLayerCount, framesPerSecond;
	float opacity;
	
	IBOutlet FBProgressSheetController *progressSheetController;
	IBOutlet FBPreviewController *previewController;
	
	IBOutlet NSTextField *resolutionLabel;
	
	NSLock *reelLock;
	
	CIFilter *selectedArtisticFilter;
}

#pragma mark -
#pragma mark Application Termination
- (void) applicationWillTerminate: (NSNotification *) n;

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
- (void) removeTemporaryStorage;

#pragma mark -
#pragma mark Video Input Devices
@property (retain) NSArray *inputDevices;
@property (retain) QTCaptureDevice *selectedInputDevice;
- (void) refreshInputDevices;

#pragma mark -
#pragma mark Displaying Video Input
- (CIImage *) view: (QTCaptureView *) view willDisplayImage: (CIImage *) image;
// - (void) captureDeviceFormatDescriptionsDidChange: (NSNotification*) notification;

#pragma mark -
#pragma mark Taking Pictures
@property (retain) CIImage *currentFrame;
@property (retain) FBProductPipeline *productPipeline;
@property NSInteger mirroring;
- (void) createSnapshotFromImage: (CIImage *) image;
- (CIImage *) adaptImage: (CIImage *) image;
- (NSAffineTransform *) productTransform;

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
- (void) applyMovieSettings;

#pragma mark -
#pragma mark Onion Skinning
@property (nonatomic, assign, setter = setOnionLayerCount:) NSInteger onionLayerCount;
@property (nonatomic, assign, setter = setOpacity:) float opacity;
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
#pragma mark Playing Previews
@property (retain) FBPreviewController *previewController;
- (IBAction) showPreviewWindow: (id) sender;

#pragma mark -
#pragma mark Reel Navigator Data Source
- (NSInteger) numberOfCellsForReelNavigator: (FBReelNavigator *) navigator;
- (CIImage *) reelNavigator: (FBReelNavigator *) navigator imageForCellAtIndex:(NSInteger)index;
- (NSImage *) reelNavigator: (FBReelNavigator *) navigator thumbnailForCellAtIndex:(NSInteger)index;
- (NSArray *) urlsForImagesAtIndexes: (NSIndexSet *) indexes;

#pragma mark -
#pragma mark Reel Navigator Delegate
- (void) reelNavigatorRequestsSnapshot:(FBReelNavigator *) navigator;
- (void) reelNavigatorRequestsDeletion: (FBReelNavigator *)navigator;
// - (void) reelNavigator: (FBReelNavigator *) navigator didSelectImageAtIndex: (NSUInteger) imageIndex;

#pragma mark -
#pragma mark Window Delegate
- (void) windowWillClose:(NSWindow *)aWindow;

#pragma mark -
#pragma mark Drag Drop Buddy
- (NSArray *) namesOfFilesAtIndexes: (NSIndexSet *) indexes forDestination: (NSURL *) destination;
- (NSArray *) pathsOfFilesAtIndexes:(NSIndexSet *)indexes;
- (void) insertImages: (NSArray *) images atIndex: (NSUInteger) index;
- (void) moveCellsAtIndexes: (NSIndexSet *) sourceIndexes toIndex: (NSUInteger) destinationIndex;
- (void) moveCellsAtIndexes: (NSIndexSet *) sourceIndexes toIndexes: (NSIndexSet *) destinationIndexes;
- (void) insertImages: (NSArray *) images atIndexes: (NSIndexSet *) indexes;
- (void) removeImagesAtIndexes: (NSIndexSet *) indexes;

#pragma mark -
#pragma mark QuickLook
- (NSImage *) quickLookPreview;
- (NSImage *) quickLookThumbnail;

#pragma mark -
#pragma mark Interface Builder Actions
- (IBAction) snapshot: (id) sender;
- (IBAction) remove: (id) sender;
- (IBAction) exportMovie: (id) sender;

#pragma mark -
#pragma mark Applying Artistic Filters
@property (retain) CIFilter *selectedArtisticFilter;

@end
