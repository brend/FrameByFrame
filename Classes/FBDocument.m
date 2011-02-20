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

@interface FBDocument ()
- (void) adaptFilterControls;
- (void) constructProductPipeline;
@end

#pragma mark -

@implementation FBDocument
@synthesize inputDevices, temporaryStorageURL, originalFileURL;

#pragma mark -
#pragma mark Initialization and Deallocation
- (id)init
{
    self = [super init];
    if (self) {
		// Add your subclass-specific initialization here.
		// If an error occurs here, send a [self release] message and return nil.
		
		self.onionLayerCount = 2;
		self.opacity = 0.5f;
		self.framesPerSecond = 15;
		self.temporaryStorageURL = [self createTemporaryURL];
		self.reel = [FBReel reel];
		self.reel.documentURL = self.temporaryStorageURL;
		[self constructProductPipeline];
		// self.productPipeline = [[[FBProductPipeline alloc] initWithArtisticFilter: nil] autorelease];
				
		reelLock = [[NSLock alloc] init];

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
	NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
	
//	[notificationCenter removeObserver: self name: QTCaptureDeviceFormatDescriptionsDidChangeNotification object: nil];
	[notificationCenter removeObserver: self name: NSApplicationWillTerminateNotification object: nil];
	
	self.temporaryStorageURL = nil;
	self.originalFileURL = nil;
	
	[filterPipeline release];
	filterPipeline = nil;
	[productPipeline release];
	productPipeline = nil;
	[reel release];
	reel = nil;
	[reelLock release];
	reelLock = nil;
	[movieSettings release];
	movieSettings = nil;
	
	[captureSession release];
	captureSession = nil;
	[videoDeviceInput release];
	videoDeviceInput = nil;
	[captureDecompressedVideoOutput release];
	captureDecompressedVideoOutput = nil;
	
	self.inputDevices = nil;
	
	// Outlets
	captureView = nil;
	progressSheetController = nil;

    [super dealloc];
}

#pragma mark -
#pragma mark Retrieving the Document Window
- (NSWindow *) window
{
	return [[self.windowControllers objectAtIndex: 0] window];
}

#pragma mark -
#pragma mark Awaking from Nib: Such as Bindings
- (void) awakeFromNib
{
	[previewController bind: @"framesPerSecond" toObject: self withKeyPath: @"framesPerSecond" options: nil];
	[filterProvider bind: @"artisticFilter" toObject: self withKeyPath: @"artisticFilter" options: nil];
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
	
	NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
	
	// Binding properties
	[self.reelNavigator bind: @"framesPerSecond" toObject: self withKeyPath: @"framesPerSecond" options: nil];
	
	// Create a capture session
	if (!captureSession) {
        BOOL success;
		NSError *error = nil;
        captureSession = [[QTCaptureSession alloc] init];
		
		QTCaptureDevice *device = [QTCaptureDevice defaultInputDeviceWithMediaType:QTMediaTypeVideo];
        success = [device open: &error];
        if (!success) {
            [[NSAlert alertWithError:error] runModal];
            return;
        }
		
		videoDeviceInput = [[QTCaptureDeviceInput alloc] initWithDevice: device];
		
		// Register for notification of format change
//		[notificationCenter addObserver: self 
//							   selector: @selector(captureDeviceFormatDescriptionsDidChange:) 
//								   name: QTCaptureDeviceFormatDescriptionsDidChangeNotification
//								 object: device];
		
        success = [captureSession addInput: videoDeviceInput error: &error];
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
	
	// Register for notification on application termination
	[notificationCenter addObserver: self selector: @selector(applicationWillTerminate:) name: NSApplicationWillTerminateNotification object: nil];
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
	
	// FIXME: Handle movie settings more elegantly
	[self.movieSettings setObject: [NSNumber numberWithInteger: self.framesPerSecond] forKey: FBFramesPerSecondAttributeName];
	
	if (self.movieSettings) {		
		if (![self.movieSettings writeToURL: self.movieSettingsURL atomically: YES]) {
			NSLog(@"Couldn't write movie settings to url %@; continuing anyway", self.movieSettingsURL);
		}
	}
	
	// Copy all the files to their destination
	NSFileManager *fileManager = [NSFileManager defaultManager];
	
	if ([fileManager copyItemAtURL: temporaryStorageURL toURL: absoluteURL error: &error]) {
		// Add QuickLook data
		NSURL *quickLookURL = [absoluteURL URLByAppendingPathComponent: @"QuickLook"];
		
		if ([fileManager createDirectoryAtPath: quickLookURL.path withIntermediateDirectories: NO attributes: nil error: NULL]) {
			NSImage *quickLookPreview = [self quickLookPreview], *quickLookThumbnail = [self quickLookThumbnail];
			
			if (quickLookPreview)
				[[quickLookPreview TIFFRepresentation] writeToURL: [quickLookURL URLByAppendingPathComponent: @"Preview.tiff"] atomically: YES];
			if (quickLookThumbnail)
				[[quickLookThumbnail TIFFRepresentation] writeToURL: [quickLookURL URLByAppendingPathComponent: @"Thumbnail.tiff"] atomically: YES];
		}
		
		return YES;
	} else {
		if (outError)
			*outError = error;
		
		return NO;
	}
}

- (BOOL)readFromURL:(NSURL *)absoluteURL ofType:(NSString *)typeName error:(NSError **)outError
{
	self.originalFileURL = absoluteURL;
	
	return YES;
}

- (void) showWindows
{
	[super showWindows];
	
	// If an existing document has been opened,
	// copy the contents asynchronously while displaying a progress sheet
	if (self.originalFileURL) {
		[self.progressSheetController beginSheetModalForWindow: self.window indeterminate: YES];
		[NSThread detachNewThreadSelector: @selector(copyDocumentContents) toTarget: self withObject: nil];
	}
}

#pragma mark -
#pragma mark Managing the Movie Reel
@synthesize reel, reelNavigator;

#pragma mark -
#pragma mark Managing Movie Settings
- (NSMutableDictionary *) movieSettings
{
	return movieSettings;
}

- (void) setMovieSettings: (NSMutableDictionary *) settings
{
	if (settings != movieSettings) {
		[self willChangeValueForKey: @"movieSettings"];
		[movieSettings release];
		movieSettings = [settings retain];
		
		// TODO: Re-position this code
		[self applyMovieSettings];
		[resolutionLabel setStringValue: [NSString stringWithFormat: @"%dx%d", (NSInteger) settings.horizontalResolution, (NSInteger) settings.verticalResolution]];
		
		[self didChangeValueForKey: @"movieSettings"];
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
	
	// Set the desired frames per second
	NSInteger fps = MAX(1, movieSettings.framesPerSecond);
	
	self.framesPerSecond = fps;
}

#pragma mark -
#pragma mark Handling Document Storage
- (NSURL *) createTemporaryURL
{
	char *tempdir = (char *) malloc(sizeof(char) * (1 + strlen(FBTemporaryFilenamePattern)));
	
	strcpy(tempdir, FBTemporaryFilenamePattern);
	mktemp(tempdir);
	
	NSURL *url = [NSURL fileURLWithPath: [NSString stringWithCString: tempdir encoding: NSASCIIStringEncoding]];
	
	free(tempdir);
	
	return url;
}

- (NSURL *) movieSettingsURL
{
	return [self.temporaryStorageURL URLByAppendingPathComponent: @"settings"];
}

- (void) copyDocumentContents
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSError *error = nil;
	
	[self copyDocumentContents: &error];
	
	[self performSelectorOnMainThread: @selector(documentOpened:) withObject: [error retain] waitUntilDone: NO];
	[pool release];
}

- (BOOL) copyDocumentContents: (NSError **) outError
{
	NSError *error = nil;
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSURL *temporaryURL = [self createTemporaryURL];
	
	self.temporaryStorageURL = temporaryURL;
	
	BOOL copyingSuccessful = [fileManager copyItemAtURL: self.originalFileURL toURL: temporaryURL error: &error];
	
	if (copyingSuccessful) {
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
		
		NSDictionary *storedSettings = [NSDictionary dictionaryWithContentsOfURL: self.movieSettingsURL];
		
		// Use default settings if none are present
		self.movieSettings = [NSMutableDictionary dictionaryWithDictionary: storedSettings == nil ? [NSDictionary defaultMovieSettings] : storedSettings];
		
		return YES;
	} else {
		if (outError)
			*outError = error;
		
		return NO;
	}	
}

- (void) documentOpened: (NSError *) error
{	
	[self.progressSheetController endSheet];
	
	if (error) {
		NSRunAlertPanel(@"An error has occurred while opening the document", [NSString stringWithFormat: @"%@", error], @"OK", nil, nil);
		[self close];
	} else {
		[self.reelNavigator reelHasChanged];
	}
}

- (void) removeTemporaryStorage
{
	NSError *error = nil;
	BOOL success = [[NSFileManager defaultManager] removeItemAtURL: self.temporaryStorageURL error: &error];
	
	if (!success)
		NSLog(@"Could not delete temporary storage due to error: %@", error);
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

- (CIImage *) view: (QTCaptureView *) view 
  willDisplayImage: (CIImage *) videoImage
{
	if (self.reel == nil)
		return nil;
	
	self.productPipeline.transform = [self productTransform];
	
	// Transmogrify the video image (transform, filter, etc.)
	// NOTE From this point on, use self.currentFrame instead of videoImage/nil 
	// in order to keep the applied transformations
	
	@try
	{
		self.currentFrame = [self.productPipeline pipeImage: videoImage];
	} @catch (NSException *exn) {
		self.currentFrame = nil;
		
		NSLog(@"The selected filter can't be applied: %@", exn);
	}
	
	if (self.reel.count == 0 || self.onionLayerCount == 0)
		return self.currentFrame;
	
	BOOL computeFilter = [self skinImageRange].length != self.filterPipeline.skinCount;
	
	[reelLock lock];
	
	if (computeFilter)
		[self createFilterPipeline];
		
	NSArray *skinImages = [self skinImages];
	CIImage *result = [self.filterPipeline pipeVideoImage: self.currentFrame skinImages: skinImages];
	
	[reelLock unlock];
	
	return result;
}

// TODO: Find out native resolution for use in Organizer
//- (void) captureDeviceFormatDescriptionsDidChange:(NSNotification*)notification
//{	
//	id device = [notification object];
//	NSArray *formats = [device formatDescriptions];
//	NSMutableSet *acceptableResolutions = [NSMutableSet setWithArray: self.movieSettingsController.availableResolutions];
//	
//	// Add current resolution(s?) to the set
//	// of existing resolutions
//	for (id format in formats) {
//		NSValue *size = [format attributeForKey: QTFormatDescriptionVideoCleanApertureDisplaySizeAttribute];
//		
//		[acceptableResolutions addObject: size];
//	}
//	
//	// Sort the resolutions
//	NSArray *allResolutions = [[acceptableResolutions allObjects] sortedArrayUsingComparator:
//							   ^(id a, id b) {
//								   float wa = [a sizeValue].width, wb = [b sizeValue].width;
//								   
//								   if (wa < wb)
//									   return NSOrderedAscending;
//								   else if (wa > wb)
//									   return NSOrderedDescending;
//								   else
//									   return NSOrderedSame;
//							   }];
//	
//	self.movieSettingsController.availableResolutions = allResolutions;
//}

#pragma mark -
#pragma mark Filter Pipeline
@synthesize filterPipeline;

- (void) createFilterPipeline
{
	NSInteger imageCount = [self skinImageRange].length;
	FBFilterPipeline *fp = [FBFilterPipeline filterPipelineWithSkinCount: imageCount];
	
	self.filterPipeline = fp;
}

#pragma mark -
#pragma mark Onion Skinning

@synthesize onionLayerCount;

- (void) setOnionLayerCount: (NSInteger) skinCount
{
	if (skinCount != onionLayerCount) {
		[self willChangeValueForKey: @"onionLayerCount"];
		onionLayerCount = skinCount;
		[self createFilterPipeline];
		[self didChangeValueForKey: @"onionLayerCount"];
	}
}

- (NSRange) skinImageRange
{
	NSUInteger selectedImageIndex = self.reelNavigator.selectedIndex;
	
	if (selectedImageIndex == NSNotFound)
		return NSMakeRange(0, 0);
	
	// imageCount := min { skinCount, selectedImageIndex + 1 }
	NSUInteger imageCount = MIN(self.onionLayerCount, selectedImageIndex + 1);
	NSUInteger startIndex = selectedImageIndex + 1 - imageCount;
	
	return NSMakeRange(startIndex, imageCount);
}

- (NSArray *) skinImages
{
	NSRange range = [self skinImageRange];
	
	return [self.reel imagesAtIndexes: [NSIndexSet indexSetWithIndexesInRange: range]];
}

@synthesize opacity;

- (void) setOpacity: (float) f
{
	[self willChangeValueForKey: @"opacity"];
	opacity = f;
	self.filterPipeline.opacity = opacity;
	[self didChangeValueForKey: @"opacity"];
}

#pragma mark -
#pragma mark Frames Per Second
@synthesize framesPerSecond;

#pragma mark -
#pragma mark Interface Builder Actions
- (IBAction) snapshot: (id) sender
{
	if (self.currentFrame)
		[self createSnapshotFromImage: self.currentFrame];
}

- (IBAction) remove: (id) sender
{
	NSIndexSet *indexes = self.reelNavigator.selectedIndexes;
	
	if (indexes.count > 0)
		[self removeImagesAtIndexes: indexes];
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

#pragma mark -
#pragma mark Exporting Movies
- (void) exportMovieToURL: (NSURL *) fileURL
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	// Initialize movie exporter
	// This will create a QTMovie on the main thread
	NSDictionary *exportAttributes = [NSDictionary dictionaryWithObject: [NSNumber numberWithInteger: self.framesPerSecond] forKey: FBFramesPerSecondAttributeName];
	FBQuickTimeExporter *exporter = [[FBQuickTimeExporter alloc] initWithReel: self.reel destination: fileURL.path attributes: exportAttributes];
	NSInteger chunkSize = 10;
	NSInteger i = 0;
	
	[self.progressSheetController performSelectorOnMainThread: @selector(beginDeterminateSheetModalForWindow:) withObject: self.window waitUntilDone: YES];
	
	// Add images to the movie, chunk-wise
	while (i < self.reel.count) {
		NSRange range = NSMakeRange(i, MIN(chunkSize, (NSInteger) self.reel.count - i));
		NSImage *thumbnail = [[self.reel cellAtIndex: i] thumbnail];
		
		[self.progressSheetController setValue: i];
		[self.progressSheetController performSelectorOnMainThread: @selector(setThumbnail:) withObject: thumbnail waitUntilDone: NO];
		
		// Update progress display
		[exporter exportImagesWithIndexes: [NSIndexSet indexSetWithIndexesInRange: range]];
		i += range.length;
	}
	
	// Done exporting
	[self.progressSheetController performSelectorOnMainThread: @selector(endSheet) withObject: nil waitUntilDone: NO];
	
	[exporter release];
	[pool release];
}

#pragma mark -
#pragma mark Taking Snapshots

@synthesize currentFrame, productPipeline, mirroring;

- (void) createSnapshotFromImage:(CIImage *)image
{
	NSUInteger selectedIndex = (NSUInteger) self.reelNavigator.selectedIndex;
	NSUInteger insertionIndex = selectedIndex == NSNotFound ? 0 : selectedIndex + 1;
	
	[self insertImages: [NSArray arrayWithObject: image] atIndex: insertionIndex];
}

- (CIImage *) adaptImage: (CIImage *) image
{
	CGSize size = image.extent.size;
	NSSize desiredSize = self.movieSettings.movieResolution;
	
	// TODO: Ensure desiredSize != 0, or else!
	if (!(size.width == desiredSize.width && size.height == desiredSize.height)) {
		CGAffineTransform scale = CGAffineTransformMakeScale(desiredSize.width / size.width, desiredSize.height / size.height);
		
		return [image imageByApplyingTransform: scale];
	} else
		return image;
}

- (NSAffineTransform *) productTransform
{
	NSAffineTransform *transform = [NSAffineTransform transform];
	float
		scaleX = (mirroring == FBMirrorImageHorizontal || mirroring == FBMirrorImageBoth) ? -1 : 1,
		scaleY = (mirroring == FBMirrorImageVertical || mirroring == FBMirrorImageBoth) ? -1 : 1;
	
	[transform scaleXBy: scaleX yBy: scaleY];
	
	return transform;
}

- (void) constructProductPipeline
{
	CIFilter *filter = self.artisticFilter;
	
	if (filter) {
		NSDictionary *attrs = filter.attributes;
		NSDictionary *controls = [NSDictionary dictionaryWithObjectsAndKeys:
								  sliderRadius, @"inputRadius",
								  sliderIntensity, @"inputIntensity", 
								  sliderSharpness, @"inputSharpness",
								  nil];
		
		for (NSString *key in controls) {
			NSControl *control = [controls objectForKey: key];
			BOOL hasInput = [attrs objectForKey: key] != nil;

			if (hasInput) {
				[filter setValue: [NSNumber numberWithDouble: control.doubleValue] forKey: key];
			}
		}
	}
	
	self.productPipeline = [[[FBProductPipeline alloc] initWithArtisticFilter: self.artisticFilter] autorelease];
}

- (void) adaptFilterControls
{
	CIFilter *filter = artisticFilter;
	NSDictionary *attrs = filter.attributes;
	NSDictionary *controls = [NSDictionary dictionaryWithObjectsAndKeys:
							  sliderRadius, @"inputRadius",
							  sliderIntensity, @"inputIntensity", 
							  sliderSharpness, @"inputSharpness",
							  nil];
	NSDictionary *boxes = [NSDictionary dictionaryWithObjectsAndKeys:
							  boxRadius, @"inputRadius",
							  boxIntensity, @"inputIntensity", 
							  boxSharpness, @"inputSharpness",
							  nil];

	
	for (NSString *key in controls) {
		BOOL hasInput = [attrs objectForKey: key] != nil;
		NSSlider *control = [controls objectForKey: key];
		
		[[boxes objectForKey: key] setHidden: !hasInput];
		
		if (hasInput) {
			[control setMinValue: [[[attrs objectForKey: key] objectForKey: @"CIAttributeSliderMin"] doubleValue]];
			[control setMaxValue: [[[attrs objectForKey: key] objectForKey: @"CIAttributeSliderMax"] doubleValue]];
		}
	}
}

#pragma mark -
#pragma mark Displaying the Progress Sheet
@synthesize progressSheetController;

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

- (NSArray *) urlsForImagesAtIndexes: (NSIndexSet *) indexes
{
	return [self.reel urlsForImagesAtIndexes: indexes];
}

#pragma mark -
#pragma mark Reel Navigator Delegate
- (void) reelNavigatorRequestsSnapshot:(FBReelNavigator *)strip
{
	[self snapshot: self];
}

- (void) reelNavigatorRequestsDeletion: (FBReelNavigator *)navigator;
{
	[self remove: self];
}

//- (void) reelNavigator: (FBReelNavigator *) navigator didSelectImageAtIndex: (NSUInteger) imageIndex
//{
//	NSLog(@"Reel navigator selected image at %d", imageIndex);
//}


- (NSArray *)namesOfPromisedFilesDroppedAtDestination:(NSURL *)dropDestination
{
	NSArray *sourceURLs = [self urlsForImagesAtIndexes: self.reelNavigator.selectedIndexes];
	NSMutableArray *names = [NSMutableArray arrayWithCapacity: sourceURLs.count];
	NSFileManager *fileManager = [NSFileManager defaultManager];
	
	for (NSURL *source in sourceURLs) {
		NSError *error = nil;
		NSString *name = source.lastPathComponent;
		NSURL *destination = [dropDestination URLByAppendingPathComponent: name];
		
		if ([fileManager copyItemAtURL: source toURL: destination error: &error]) {
			[names addObject: name];
		}
		else {
			NSLog(@"Error copying file from %@ to %@ : %@", source, destination, error);
		}
	}
	
	return names;
}

#pragma mark -
#pragma mark Window Delegate
- (void) windowWillClose: (NSWindow *) aWindow
{
	[captureSession stopRunning];
}

#pragma mark -
#pragma mark Drag Drop Buddy
- (NSArray *) namesOfFilesAtIndexes: (NSIndexSet *) indexes forDestination: (NSURL *) dropDestination
{
	NSArray *sourceURLs = [self urlsForImagesAtIndexes: indexes];
	NSMutableArray *names = [NSMutableArray arrayWithCapacity: sourceURLs.count];
	NSFileManager *fileManager = [NSFileManager defaultManager];
	
	for (NSURL *source in sourceURLs) {
		NSError *error = nil;
		NSString *name = source.lastPathComponent;
		NSURL *destination = [dropDestination URLByAppendingPathComponent: name];
		
		if ([fileManager copyItemAtURL: source toURL: destination error: &error]) {
			[names addObject: name];
		}
		else {
			NSLog(@"Error copying file from %@ to %@ : %@", source, destination, error);
		}
	}
	
	return names;	
}

- (NSArray *) pathsOfFilesAtIndexes:(NSIndexSet *)indexes
{
	NSMutableArray *paths = [NSMutableArray arrayWithCapacity: indexes.count];

	for (NSURL *url in [self urlsForImagesAtIndexes: indexes])
		[paths addObject: url.path];
	
	return paths;
}

- (void) insertImages: (NSArray *) importedImages atIndex: (NSUInteger) insertionIndex
{
	if (importedImages.count == 0)
		return;
	
	[reelLock lock];
	
	// Insert images in the correct order
	for (NSInteger i = 0; i < importedImages.count; ++i) {
		CIImage *ciImage = [importedImages objectAtIndex: importedImages.count - (i + 1)];
		// Adapt image to movie settings
		CIImage *adaptedImage = [self adaptImage: ciImage];
		
		[self.reel insertCellWithImage: adaptedImage atIndex: insertionIndex];
	}
	
	[reelLock unlock];
	
	// Set up undo action
	[self.undoManager registerUndoWithTarget: self selector: @selector(removeImagesAtIndexes:) object: [NSIndexSet indexSetWithIndexesInRange: NSMakeRange(insertionIndex, importedImages.count)]];
	
	// Update navigator selection
	[self.reelNavigator setSelectedIndexes: [NSMutableIndexSet indexSetWithIndex: insertionIndex + (importedImages.count - 1)]];
	[self.reelNavigator reelHasChanged];
}

- (void) insertImages: (NSArray *) importedImages atIndexes: (NSIndexSet *) indexes
{
	// Adapt images to movie settings
	NSMutableArray *adaptedImages = [NSMutableArray arrayWithCapacity: importedImages.count];
	
	for (CIImage *image in importedImages)
		[adaptedImages addObject: [self adaptImage: image]];
	
	// Insert images into reel
	[reelLock lock];
	[self.reel insertCellsWithImages: adaptedImages atIndexes: indexes];
	[reelLock unlock];
	
	// Set up undo action
	[self.undoManager registerUndoWithTarget: self selector: @selector(removeImagesAtIndexes:) object: indexes];
	
	// Update navigator selection
	[self.reelNavigator setSelectedIndexes: [NSMutableIndexSet indexSetWithIndex: indexes.lastIndex]];
	[self.reelNavigator reelHasChanged];
}

- (void) moveCellsAtIndexes: (NSIndexSet *) sourceIndexes toIndex: (NSUInteger) destinationIndex
{
	if (sourceIndexes.count == 0)
		return;

	[reelLock lock];
	NSUInteger finalDestination = [self.reel moveCellsAtIndexes: sourceIndexes toIndex: destinationIndex];
	[reelLock unlock];
	
	// Set up undo action
	[(FBDocument *) [self.undoManager prepareWithInvocationTarget: self] moveCellsAtIndexes: [NSIndexSet indexSetWithIndexesInRange: NSMakeRange(finalDestination, sourceIndexes.count)]
																				  toIndexes: sourceIndexes];
	
	// Update navigator selection
	[self.reelNavigator setSelectedIndexes: [NSMutableIndexSet indexSetWithIndex: finalDestination + sourceIndexes.count - 1]];
	[self.reelNavigator reelHasChanged];
}

- (void) moveCellsAtIndexes: (NSIndexSet *) sourceIndexes toIndexes: (NSIndexSet *) destinationIndexes;
{
	[reelLock lock];
	[self.reel moveCellsAtIndexes: sourceIndexes toIndexes: destinationIndexes];
	[reelLock unlock];
	
	// Set up undo action
	[(FBDocument *) [self.undoManager prepareWithInvocationTarget: self] moveCellsAtIndexes: destinationIndexes toIndexes: sourceIndexes];
	
	// Update navigator selection
	[self.reelNavigator setSelectedIndexes: [NSMutableIndexSet indexSetWithIndex: destinationIndexes.lastIndex]];
	[self.reelNavigator reelHasChanged];
}

- (void) removeImagesAtIndexes: (NSIndexSet *) indexes
{
	[reelLock lock];
	NSArray *images = [self.reel imagesAtIndexes: indexes];
	[self.reel removeCellsAtIndexes: indexes];
	[reelLock unlock];
	
	// Set up undo action
	[[self.undoManager prepareWithInvocationTarget: self] insertImages: images atIndexes: indexes];
	
	// Update navigator selection
	NSUInteger newSelection = MIN(self.reel.count - 1, indexes.firstIndex);
	NSMutableIndexSet *newIndexes = newSelection < self.reel.count 
									? [NSMutableIndexSet indexSetWithIndex: newSelection] 
									: [NSMutableIndexSet indexSet];
	
	[self.reelNavigator setSelectedIndexes: newIndexes];
	[self.reelNavigator reelHasChanged];
}

#pragma mark -
#pragma mark Application Termination
- (void) applicationWillTerminate: (NSNotification *) n
{
	// Remove temporary storage,
	// but only if all changes have been saved
	if (!self.isDocumentEdited)
		[self removeTemporaryStorage];
}

#pragma mark -
#pragma mark QuickLook
- (NSImage *) quickLookPreview
{
	if (self.reel.count == 0)
		return nil;
	
	CIImage *ciImage = [self.reel imageAtIndex: self.reel.count / 2];
	NSBitmapImageRep *r = [[NSBitmapImageRep alloc] initWithCIImage: ciImage];
	NSImage *image = [[NSImage alloc] init];
	
	[image addRepresentation: r];
	[r release];
	
	return [image autorelease];
}

- (NSImage *) quickLookThumbnail
{
	if (self.reel.count == 0)
		return nil;
	
	return [[self.reel cellAtIndex: self.reel.count / 2] thumbnail];
}

#pragma mark -
#pragma mark Playing Previews
@synthesize previewController;

- (IBAction) showPreviewWindow: (id) sender
{
	NSUInteger selectedFrame = self.reelNavigator.selectedIndex;
	NSUInteger startFrame = (selectedFrame == NSNotFound) 
								? 0
								: ((selectedFrame == self.reel.count - 1) ? 0 : selectedFrame);
	
	[self.previewController setupPreviewWithReel: self.reel
								fromImageAtIndex: startFrame
								 framesPerSecond: self.framesPerSecond];
}

#pragma mark -
#pragma mark Applying Artistic Filters

- (CIFilter *) artisticFilter
{
	return artisticFilter;
}

- (void) setArtisticFilter: (CIFilter *) aFilter
{
	[self willChangeValueForKey: @"artisticFilter"];
	[artisticFilter autorelease];
	artisticFilter = [aFilter retain];
	[self adaptFilterControls];
	[self constructProductPipeline];
	[self didChangeValueForKey: @"artisticFilter"];
}

- (IBAction) sliderDidChangeValue: (id) sender
{
	if (self.artisticFilter) {
		[self constructProductPipeline];
	}
}

- (void) filterProviderDidEditFilter: (FBFilterProvider *) fp
{
	[self constructProductPipeline];
}

@end
