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
#import "FBFilterPipeline.h"
#import "FBProgressSheetController.h"

@interface FBDocument : NSDocument <FBReelNavigatorDelegate, FBReelNavigatorDataSource>
{
	QTCaptureSession *captureSession;
	QTCaptureDeviceInput *captureDeviceInput;
	QTCaptureDecompressedVideoOutput *captureDecompressedVideoOutput;
	IBOutlet QTCaptureView *captureView;
	
	NSArray *inputDevices;
	QTCaptureDeviceInput *videoDeviceInput;
	
	IBOutlet FBReelNavigator *reelNavigator;
	FBReel *reel;
	BOOL shouldTakeSnapshot;
	
	NSURL *temporaryStorageURL;
	
	FBFilterPipeline *filterPipeline;
	NSInteger onionLayerCount;
	
	IBOutlet NSWindow *progressSheet;
	IBOutlet FBProgressSheetController *progressSheetController;
}

- (IBAction)foo:(id)sender;

#pragma mark -
#pragma mark Retrieving the Document Window
@property (readonly) NSWindow *window;

#pragma mark -
#pragma mark Handling Document Storage
@property (retain) NSURL *temporaryStorageURL;
- (NSURL *) createTemporaryURL;

#pragma mark -
#pragma mark Video Input Devices
@property (retain) NSArray *inputDevices;
@property (retain) QTCaptureDevice *selectedInputDevice;
- (void) refreshInputDevices;

#pragma mark -
#pragma mark Displaying Video Input
- (CIImage *)view:(QTCaptureView *)view willDisplayImage:(CIImage *)image;

#pragma mark -
#pragma mark Taking Pictures
- (void) createSnapshotFromImage: (CIImage *) image;

#pragma mark -
#pragma mark Exporting Movies
- (BOOL) exportMovieToURL: (NSURL *)fileURL error: (NSError **)outError;

#pragma mark -
#pragma mark Managing the Movie Reel
@property (retain) FBReel *reel;
@property (readonly) FBReelNavigator *reelNavigator;

#pragma mark -
#pragma mark Onion Skinning
@property (nonatomic, assign) NSInteger onionLayerCount;
- (NSArray *) skinImages;

#pragma mark -
#pragma mark Filter Pipeline
@property (retain) FBFilterPipeline *filterPipeline;
- (void) createFilterPipeline;

#pragma mark -
#pragma mark Reel Navigator Data Source
- (NSInteger) numberOfCellsForReelNavigator: (FBReelNavigator *) navigator;
- (CIImage *) reelNavigator: (FBReelNavigator *) navigator imageForCellAtIndex:(NSInteger)index;
- (NSImage *) reelNavigator: (FBReelNavigator *) navigator thumbnailForCellAtIndex:(NSInteger)index;

#pragma mark -
#pragma mark Reel Navigator Delegate
- (void) reelNavigatorRequestsSnapshot:(FBReelNavigator *)strip;

#pragma mark -
#pragma mark Interface Builder Actions
- (IBAction) snapshot: (id) sender;
- (IBAction) exportMovie: (id) sender;

@end
