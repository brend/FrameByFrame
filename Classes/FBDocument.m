//
//  FBDocument.m
//  FrameByFrame
//
//  Created by Philipp Brendel on 28.10.10.
//  Copyright (c) 2010 BrendCorp. All rights reserved.
//

#import "FBDocument.h"
#import "FBReelNavigator.h"

@implementation FBDocument
@synthesize inputDevices, reel, reelNavigator, inputFilter, temporaryStorageURL, originalDocumentURL, onionLayerCount;

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
		} else
			NSLog(@"Temporary storage is at %@", self.temporaryStorageURL);
    }
    return self;
}

- (void)dealloc 
{
	self.originalDocumentURL = nil;
	self.temporaryStorageURL = nil;
	
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
#pragma mark Document Implementation
- (NSString *)windowNibName 
{
	// Override returning the nib file name of the document
	// If you need to use a subclass of NSWindowController or if your document supports multiple NSWindowControllers, you should remove this method and override -makeWindowControllers instead.
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
    }
	
	// Enumerate available video input devices
	[self refreshInputDevices];
	
	// Create filter
	// NOTE If there are no pictures, the filter will be nil,
	// and thus images will pass through the CICaptureView unfiltered.
	self.inputFilter = [self generateFilter];
	
	// Set up the reel navigator
	[self.reelNavigator bind: @"reel" toObject: self withKeyPath: @"reel" options: nil];
}

- (BOOL)writeToURL:(NSURL *)absoluteURL ofType:(NSString *)typeName error:(NSError **)outError
{
	NSError *intermediateError = nil;
	
	if (![self.reel writeToURL: self.temporaryStorageURL error: &intermediateError]) {
		NSLog(@"Error saving reel at %@: %@", self.temporaryStorageURL, intermediateError);
		
		if (outError)
			*outError = intermediateError;
		
		return NO;
	}
	
	
	NSLog(@"Attempting to copy document from %@ to %@", temporaryStorageURL, absoluteURL);
	
	NSError *error = nil;
	
	if ([[NSFileManager defaultManager] copyItemAtURL: temporaryStorageURL toURL: absoluteURL error: &error]) {
		NSLog(@"Document has been successfully copied");
		return YES;
	} else {
		NSLog(@"Document could not be copied: %@", error);
		return NO;
	}
}

- (BOOL)readFromURL:(NSURL *)absoluteURL ofType:(NSString *)typeName error:(NSError **)outError
{	
	NSError *error = nil;

	self.originalDocumentURL = absoluteURL;	
	
	NSURL *temporaryURL = [self createTemporaryURL];
	
	self.temporaryStorageURL = temporaryURL;
	
	if ([[NSFileManager defaultManager] copyItemAtURL: absoluteURL toURL: temporaryURL error: &error]) {
		NSLog(@"Document successfully copied");
//		[self showLoadingPanel];
		
		self.reel = [FBReel reelWithContentsOfURL: absoluteURL error: &error];
//		[self.reel readContentsOfURL: absoluteURL error: &error];
		self.reel.documentURL = self.temporaryStorageURL;
		
		if (self.reel == nil) {
			NSLog(@"Reel could not be loaded from %@ due to error: %@", absoluteURL, error);
			
			return NO;
		}
		
		return YES;
	} else {
		NSLog(@"Error copying document: %@", error);
		return NO;
	}
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
	
	[[NSString alloc] initWithString: @"hi"];
	
	if (shouldTakeSnapshot) {
		[self createSnapshotFromImage: videoImage];
		shouldTakeSnapshot = NO;
	}
	
	if (self.reel.count == 0 || self.onionLayerCount == 0)
		return videoImage;
	
	if (computeFilter) {
		self.inputFilter = [self generateFilter];
	}
	
	[self.inputFilter setDefaults];
	[self populateFilterWithVideoImage: videoImage];
	
	CIImage *result = [self.inputFilter valueForKey: @"outputImage"];
	
	return result;
#endif
}

- (CIFilter *) generateFilter
{
	switch (self.reel.count) {
		case 0:
			return nil;
		case 1:
			return [self generateFilterForSinglePicture];
		default:
			return [self generateFilterForMultiplePictures];
	}
}

- (CIFilter *) generateFilterForSinglePicture
{
	CIFilterGenerator *generator = [CIFilterGenerator filterGenerator];
	CIFilter
		*fade = [CIFilter filterWithName: @"CIColorMatrix"],
		*blend = [CIFilter filterWithName: @"CISourceOverCompositing"];
	
	[fade setDefaults];
	[fade setValue: [CIVector vectorWithX: 0.0f Y: 0.0f Z: 0.0f W: 0.5f] forKey: @"inputAVector"];
	
	[blend setDefaults];
	
	[generator connectObject: fade withKey: @"outputImage" toObject: blend withKey: @"inputImage"];
	[generator exportKey: @"inputImage" fromObject: fade withName: @"inputImage0"];
	[generator exportKey: @"inputBackgroundImage" fromObject: blend withName: @"videoImage"];
	[generator exportKey: @"outputImage" fromObject: blend withName: @"outputImage"];
	
	return [generator filter];
}

- (CIFilter *) generateFilterForMultiplePictures
{
	CIFilterGenerator *generator = [CIFilterGenerator filterGenerator];
	CIFilter *penultimateBlend = nil;
	NSInteger imageCount = MIN(self.onionLayerCount, self.reel.count);
	
	NSAssert(imageCount > 1, @"Multiple pictures must be present");
	
	for (NSInteger i = 0; i < imageCount; ++i) {
		CIFilter *fade = [CIFilter filterWithName: @"CIColorMatrix"];
		CIFilter *blend = [CIFilter filterWithName: @"CISourceOverCompositing"];
		float alpha = 1.0f / (float) imageCount;
//		float alpha = 0.5f;
		
		[fade setDefaults];
		[fade setValue: [CIVector vectorWithX: 0.0f Y: 0.0f Z: 0.0f W: alpha] forKey: @"inputAVector"];
		
		[blend setDefaults];
		
		NSString *exportedInput = [NSString stringWithFormat: @"inputImage%d", i];
		
		if (i == 0) {
			[generator connectObject: fade withKey: @"outputImage" toObject: blend withKey: @"inputImage"];
		} else {
			[generator connectObject: fade withKey: @"outputImage" toObject: blend withKey: @"inputBackgroundImage"];
			[generator connectObject: penultimateBlend withKey: @"outputImage" toObject: blend withKey: @"inputImage"];
		}
		
		[generator exportKey: @"inputImage" fromObject: fade withName: exportedInput];
		
		penultimateBlend = blend;
	}
	
	NSAssert(penultimateBlend != nil, @"There must be at least one picture thingy");
	
	CIFilter *finalBlend = [CIFilter filterWithName: @"CISourceOverCompositing"];
	
	[finalBlend setDefaults];
	[generator connectObject: penultimateBlend withKey: @"outputImage" toObject: finalBlend withKey: @"inputImage"];
	[generator exportKey: @"inputBackgroundImage" fromObject: finalBlend withName: @"videoImage"];
	[generator exportKey: @"outputImage" fromObject: finalBlend withName: @"outputImage"];
	
	// So wird gespeichert
	//	[generator setClassAttributes: [NSDictionary dictionary]];
	//	[generator writeToURL: [NSURL fileURLWithPath: @"/Users/brph0000/Desktop/Threeway.plist"] atomically: YES];
	
	return [generator filter];
}

#pragma mark -
#pragma mark Onion Skinning
- (void) populateFilterWithVideoImage: (CIImage *) videoImage
{
	NSAssert(self.onionLayerCount > 0, @"Filter can only be populated with an onion layer count greater than zero");
	
	// For testing purposes, we always use the last images on the reel as onion skins
	NSInteger referenceIndex = self.reel.count;
	NSInteger startIndex = MAX(0, referenceIndex - self.onionLayerCount);
	NSInteger imageCount = MIN((NSInteger) self.reel.count - startIndex, self.onionLayerCount);
	
	for (NSInteger i = 0; i < imageCount; ++i) {
		CIImage *picture = [self.reel imageAtIndex: startIndex + i];
		
		[self.inputFilter setValue: picture forKey: [NSString stringWithFormat: @"inputImage%d", i]];
	}
	[self.inputFilter setValue: videoImage forKey: @"videoImage"];	
}

#pragma mark -
#pragma mark Interface Builder Actions
- (IBAction) snapshot: (id) sender
{
	shouldTakeSnapshot = YES;
}

#pragma mark -
#pragma mark Taking Snapshots
- (void) createSnapshotFromImage:(CIImage *)image
{
	[self.reel addCellWithImage: image];
	[self.reelNavigator reelHasChanged];
}

#pragma mark -
#pragma mark Reel Navigator Delegate
- (void) reelNavigatorRequestsSnapshot:(FBReelNavigator *)strip
{
	NSLog(@"Snapshot required!");
}

@end
