//
//  FBDocument.m
//  FrameByFrame
//
//  Created by Philipp Brendel on 28.10.10.
//  Copyright (c) 2010 BrendCorp. All rights reserved.
//

#import "FBDocument.h"
#import "FBReelNavigator.h"
#import "FBQuickTimeExporter.h"

@implementation FBDocument
@synthesize inputDevices, temporaryStorageURL, onionLayerCount;

#pragma mark -
#pragma mark Initialization and Deallocation
- (id)init
{
    self = [super init];
    if (self) {
		// Add your subclass-specific initialization here.
		// If an error occurs here, send a [self release] message and return nil.
		
		self.onionLayerCount = 2;
		self.temporaryStorageURL = [self createTemporaryURL];
		self.reel = [FBReel reel];
		self.reel.documentURL = self.temporaryStorageURL;
		
		NSError *error = nil;
		
		if (![[NSFileManager defaultManager] createDirectoryAtPath: self.temporaryStorageURL.path withIntermediateDirectories: NO attributes: nil error: &error])
		{
			NSLog(@"Error creating temporary document storage at %@: %@", self.temporaryStorageURL, error);
			
			[self release];
			
			return nil;
		}
    }
    return self;
}

- (void)dealloc 
{
	self.temporaryStorageURL = nil;
	self.filterPipeline = nil;
	
	[captureSession release];
	captureSession = nil;
	[videoDeviceInput release];
	videoDeviceInput = nil;
//	[movieFileOutput release];
//	movieFileInput = nil;
	
	[inputDevices release];
	inputDevices = nil;

    [super dealloc];
}

#pragma mark -
#pragma mark Retrieving the Document Window
- (NSWindow *) window
{
	return [[self.windowControllers objectAtIndex: 0] window];
}

#pragma mark -
#pragma mark Document Implementation
- (NSString *)windowNibName 
{
	return @"FBDocument";
}

- (void)windowControllerDidLoadNib:(NSWindowController *)aController 
{
	[super windowControllerDidLoadNib:aController];
	
	// Create a capture session
	if (!captureSession) {
        BOOL success;
		NSError *error = nil;
        captureSession = [[QTCaptureSession alloc] init];
		
		QTCaptureDevice *device = [QTCaptureDevice defaultInputDeviceWithMediaType:QTMediaTypeVideo];
        success = [device open:&error];
        if (!success) {
            [[NSAlert alertWithError:error] runModal];
            return;
        }
		
		captureDeviceInput = [[QTCaptureDeviceInput alloc] initWithDevice:device];
        success = [captureSession addInput:captureDeviceInput error:&error];
        if (!success) {
            [[NSAlert alertWithError:error] runModal];
            return;
        }
		
		captureDecompressedVideoOutput = [[QTCaptureDecompressedVideoOutput alloc] init];
        [captureDecompressedVideoOutput setDelegate:self];
        success = [captureSession addOutput:captureDecompressedVideoOutput error:&error];
        if (!success) {
            [[NSAlert alertWithError:error] runModal];
            return;
        }
		
		[captureView setCaptureSession:captureSession];
		[captureSession startRunning];
		
		[self applyMovieSettings];
    }
	
	// Enumerate available video input devices
	[self refreshInputDevices];
	
	// Create filter pipeline
	[self createFilterPipeline];
}

- (BOOL)writeToURL:(NSURL *)absoluteURL ofType:(NSString *)typeName error:(NSError **)outError
{
	NSError *error = nil;
	
	// Save the reel
	if (![self.reel writeToURL: self.temporaryStorageURL error: &error]) {
		if (outError)
			*outError = error;
		
		return NO;
	}
	
	// Save the movie settings
	if (self.movieSettings) {		
		if (![self.movieSettings writeToURL: self.movieSettingsURL atomically: YES]) {
			NSLog(@"Couldn't write movie settings to url %@; continuing anyway", self.movieSettingsURL);
		}
	}
	
	// Copy all the files to their destination
	if ([[NSFileManager defaultManager] copyItemAtURL: temporaryStorageURL toURL: absoluteURL error: &error]) {
		return YES;
	} else {
		if (outError)
			*outError = error;
		
		return NO;
	}
}

- (BOOL)readFromURL:(NSURL *)absoluteURL ofType:(NSString *)typeName error:(NSError **)outError
{	
	NSError *error = nil;
	NSURL *temporaryURL = [self createTemporaryURL];
	NSFileManager *fileManager = [NSFileManager defaultManager];
	
	self.temporaryStorageURL = temporaryURL;
	
	if ([fileManager copyItemAtURL: absoluteURL toURL: temporaryURL error: &error]) {		
		
		if ([fileManager fileExistsAtPath: [temporaryURL.path stringByAppendingPathComponent: @"reel"]]) {		
			self.reel = [FBReel reelWithContentsOfURL: temporaryURL error: &error];
		} else {
			self.reel = [FBReel reelWithContentsOfDirectory: temporaryURL error: &error];
		}
		
		if (self.reel == nil) {
			if (outError)
				*outError = error;
			
			return NO;
		}
		
		self.reel.documentURL = self.temporaryStorageURL;
		// TODO Decide: If settings aren't available, user will be asked. OK - or default? Ooor: Default if legacy document
		self.movieSettings = [NSDictionary dictionaryWithContentsOfURL: self.movieSettingsURL];
		
		return YES;
	} else {
		if (outError)
			*outError = error;
		
		return NO;
	}
}

- (void) showWindows
{
	[super showWindows];
	
	// If this is a newly created document,
	// ask for settings
	if (self.movieSettings == nil) {
		[movieSettingsController beginSheetModalForWindow: self.window];
	}
	
	[self.reelNavigator reelHasChanged];
}

#pragma mark -
#pragma mark Managing the Movie Reel
@synthesize reel, reelNavigator;

#pragma mark -
#pragma mark Managing Movie Settings
- (NSDictionary *) movieSettings
{
	return movieSettings;
}

- (void) setMovieSettings: (NSDictionary *) settings
{
	if (settings != movieSettings) {
		[movieSettings release];
		movieSettings = [settings retain];
		
		// TODO Re-position this code
		[self applyMovieSettings];
	}
}

- (void) applyMovieSettings
{
	if (movieSettings == nil)
		return;
	
	// Change the capture view's resolution
	NSInteger
		horizontalResolution = movieSettings.horizontalResolution,
		verticalResolution = movieSettings.verticalResolution;
	
	if (horizontalResolution > 0 && verticalResolution > 0) {
		[[[captureSession outputs] objectAtIndex:0] setPixelBufferAttributes: [NSDictionary dictionaryWithObjectsAndKeys:
																			   [NSNumber numberWithInt: (int) verticalResolution], kCVPixelBufferHeightKey,
																			   [NSNumber numberWithInt: (int) horizontalResolution], kCVPixelBufferWidthKey, nil]];
	} else
		NSLog(@"Invalid resolution: %d x %d", horizontalResolution, verticalResolution);	
}

#pragma mark -
#pragma mark Handling Document Storage
- (NSURL *) createTemporaryURL
{
	char template[] = "/tmp/fbf.XXXXXXXX";
	char *tempdir = mktemp(template);
	
	NSURL *url = [NSURL fileURLWithPath: [NSString stringWithCString: tempdir encoding: NSASCIIStringEncoding]];
	
	return url;
}

- (NSURL *) movieSettingsURL
{
	return [self.temporaryStorageURL URLByAppendingPathComponent: @"settings"];
}

#pragma mark -
#pragma mark Video Input Devices
- (void)refreshInputDevices
{
	NSArray *a = [[QTCaptureDevice inputDevicesWithMediaType:QTMediaTypeVideo] arrayByAddingObjectsFromArray:[QTCaptureDevice inputDevicesWithMediaType:QTMediaTypeMuxed]];

	self.inputDevices = a;
	
	if (!(self.selectedInputDevice == nil || [self.inputDevices containsObject: self.selectedInputDevice]))
		self.selectedInputDevice = nil;
}

- (QTCaptureDevice *)selectedInputDevice
{
	return [videoDeviceInput device];
}

- (void)setSelectedInputDevice:(QTCaptureDevice *)selectedVideoDevice
{
	if (videoDeviceInput) {
		// Remove the old device input from the session and close the device
		[captureSession removeInput: videoDeviceInput];
		[[videoDeviceInput device] close];
		[videoDeviceInput release];
		videoDeviceInput = nil;
	}
	
	if (selectedVideoDevice) {
		NSError *error = nil;
		BOOL success;
		
		// Try to open the new device
		success = [selectedVideoDevice open:&error];
		if (!success) {
			[[NSAlert alertWithError:error] beginSheetModalForWindow:[[[self windowControllers] objectAtIndex:0] window] modalDelegate:self didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:NULL];
			return;
		}
		
		// Create a device input for the device and add it to the session
		videoDeviceInput = [[QTCaptureDeviceInput alloc] initWithDevice:selectedVideoDevice];
		
		success = [captureSession addInput:videoDeviceInput error:&error];
		if (!success) {
			[[NSAlert alertWithError:error] beginSheetModalForWindow:[[[self windowControllers] objectAtIndex:0] window] modalDelegate:self didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:NULL];
			[videoDeviceInput release];
			videoDeviceInput = nil;
			[selectedVideoDevice close];
			return;
		}
	}
}

#pragma mark -
#pragma mark Displaying Video Input
- (CIImage *)view:(QTCaptureView *)view willDisplayImage:(CIImage *)videoImage
{
#ifdef DEBUG_FILTER	
	// DEBUG
	if (shouldTakeSnapshot) {
		[self createSnapshotFromImage: videoImage];
		shouldTakeSnapshot = NO;
	}
	
	return videoImage;
#else
	BOOL computeFilter = shouldTakeSnapshot;
		
	if (shouldTakeSnapshot) {
		[self createSnapshotFromImage: videoImage];
		shouldTakeSnapshot = NO;
	}
	
	if (self.reel.count == 0 || self.onionLayerCount == 0)
		return videoImage;
	
	if (computeFilter)
		[self createFilterPipeline];
	
	NSArray *skinImages = [self skinImages];
	CIImage *result = [self.filterPipeline pipeVideoImage: videoImage skinImages: skinImages];
	
	return result;
#endif
}

#pragma mark -
#pragma mark Filter Pipeline
@synthesize filterPipeline;

- (void) createFilterPipeline
{
	NSInteger imageCount = MIN(self.onionLayerCount, self.reel.count);
	FBFilterPipeline *fp = [FBFilterPipeline filterPipelineWithSkinCount: imageCount];
	
	self.filterPipeline = fp;
}

#pragma mark -
#pragma mark Onion Skinning
- (void) setOnionLayerCount: (NSInteger) skinCount
{
	if (skinCount != onionLayerCount) {
		[self willChangeValueForKey: @"onionLayerCount"];
		onionLayerCount = skinCount;
		[self createFilterPipeline];
		[self didChangeValueForKey: @"onionLayerCount"];
	}
}

- (NSArray *) skinImages
{
	NSAssert(self.reel.count >= self.filterPipeline.skinCount, @"Not enough pictures on reel to fill the filter pipeline");
	
	NSUInteger selectedImageIndex = self.reelNavigator.selectedIndex;
	NSInteger imageCount = self.filterPipeline.skinCount;
//	NSInteger startIndex = self.reel.count - imageCount;
	NSInteger startIndex = MAX(0, (NSInteger) ((selectedImageIndex == NSNotFound ? 0 : selectedImageIndex) - imageCount + 1));
	NSMutableArray *a = [NSMutableArray arrayWithCapacity: imageCount];
	
	for (NSInteger i = 0; i < imageCount; ++i) {
		// NOTE Use FBReel-imageAtIndex: to retrieve the image
		// (instead of accessing cells directly)
		// This way, the reel can release non-adjacent images
		// in order to relieve memory stress
		CIImage *image = [self.reel imageAtIndex: startIndex + i];
		
		[a addObject: image];
	}
	
	return a;
}

#pragma mark -
#pragma mark Interface Builder Actions
- (IBAction) snapshot: (id) sender
{
	shouldTakeSnapshot = YES;
}

- (IBAction) exportMovie: (id) sender
{
	NSSavePanel *savePanel = [NSSavePanel savePanel];
		
	[savePanel beginSheetModalForWindow: self.window completionHandler:
	 ^(NSInteger result) {
		 if (result == NSFileHandlingPanelOKButton) {
			 NSString *filename = [savePanel.filename stringByAppendingPathExtension: @"mov"];
			 NSURL *fileURL = [NSURL fileURLWithPath: filename];
			 
			 [NSThread detachNewThreadSelector: @selector(exportMovieToURL:) toTarget: self withObject: fileURL];
		 }
	 }];
}

- (IBAction) cancelMovieSettingsSheet: (id) sender
{
	NSBeginAlertSheet(@"Do you want to use default settings?", @"No", @"Yes", nil, movieSettingsController.settingsSheet, self, @selector(sheetDidEnd:returnCode:contextInfo:), nil, FBCancelMovieSettingsContext, @"They may not be very useful.");
}

- (void) sheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo
{
	if ([(NSObject *) contextInfo isEqual: FBCancelMovieSettingsContext]) {
		if (returnCode == 0) {
			[movieSettingsController endSheet];
		}
	}
}

#pragma mark -
#pragma mark Exporting Movies
- (void) exportMovieToURL: (NSURL *) fileURL
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	// Initialize movie exporter
	// This will create a QTMovie on the main thread
	FBQuickTimeExporter *exporter = [[FBQuickTimeExporter alloc] initWithReel: self.reel destination: fileURL.path];
	NSInteger chunkSize = 10;
	NSInteger i = 0;
	
	// Show progress
	[progressSheetController setValue: 0];
	[progressSheetController setMaxValue: self.reel.count];
	[progressSheetController performSelectorOnMainThread: @selector(beginSheetModalForWindow:) withObject: self.window waitUntilDone: NO];	
	
	// Add images to the movie, chunk-wise
	while (i < self.reel.count) {
		NSRange range = NSMakeRange(i, MIN(chunkSize, (NSInteger) self.reel.count - i));
		NSImage *thumbnail = [[self.reel cellAtIndex: i] thumbnail];
		
		[progressSheetController setValue: i];
		[progressSheetController performSelectorOnMainThread: @selector(setThumbnail:) withObject: thumbnail waitUntilDone: NO];
		
		// Update progress display
		[exporter exportImagesWithIndexes: [NSIndexSet indexSetWithIndexesInRange: range]];
		i += range.length;
	}
	
	// Done exporting
	NSLog(@"Export complete");
	
	[progressSheetController performSelectorOnMainThread: @selector(endSheet) withObject: nil waitUntilDone: NO];
	
	[exporter release];
	[pool release];
}

#pragma mark -
#pragma mark Taking Snapshots
- (void) createSnapshotFromImage:(CIImage *)image
{	
	[self.reel addCellWithImage: image];
	[self.reelNavigator reelHasChanged];
}

#pragma mark -
#pragma mark Reel Navigator Data Source
- (NSInteger) numberOfCellsForReelNavigator: (FBReelNavigator *) navigator
{
	return self.reel.count;
}

- (CIImage *) reelNavigator: (FBReelNavigator *) navigator imageForCellAtIndex:(NSInteger)index
{
	return [[self.reel cellAtIndex: index] image];
}

- (NSImage *) reelNavigator: (FBReelNavigator *) navigator thumbnailForCellAtIndex:(NSInteger)index
{
	return [[self.reel cellAtIndex: index] thumbnail];
}

#pragma mark -
#pragma mark Movie Settings Controller Delegate
- (void) movieSettingsController: (FBMovieSettingsController *) controller
				 didSaveSettings: (NSDictionary *) settings
{
	self.movieSettings = settings;
	
	[movieSettingsController endSheet];
}

#pragma mark -
#pragma mark Reel Navigator Delegate
- (void) reelNavigatorRequestsSnapshot:(FBReelNavigator *)strip
{
	NSLog(@"Snapshot required!");
}

//- (void) reelNavigator: (FBReelNavigator *) navigator didSelectImageAtIndex: (NSUInteger) imageIndex
//{
//	NSLog(@"Reel navigator selected image at %d", imageIndex);
//}

#pragma mark -
#pragma mark Testing
- (IBAction)foo:(id)sender 
{
	[movieSettingsController beginSheetModalForWindow: self.window];
}

// Kopieren von Dateien mit Benachrichtigungen
//- (void) bar: (id) data
//{
//	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
//	NSFileManager *fileManager = [NSFileManager defaultManager];
//	
//	[fileManager setDelegate: self];
//	[fileManager copyItemAtPath: @"/Users/brph0000/Desktop/x.ffm" toPath: @"/Users/brph0000/Desktop/Kopie von Untitled.ffm" error: NULL];
//	[pool release];
//}
//
//- (BOOL)fileManager:(NSFileManager *)fileManager shouldCopyItemAtPath:(NSString *)srcPath toPath:(NSString *)dstPath
//{
//	NSLog(@"Ich kopiere %@", srcPath);
//	progressSheetController.value += 1;
//	
//	return YES;
//}

@end
