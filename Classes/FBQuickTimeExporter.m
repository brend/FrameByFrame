//
//  FBQuickTimeExporter.m
//  FrameByFrame
//
//  Created by Philipp Brendel on 27.11.10.
//  Copyright 2010 BrendCorp. All rights reserved.
//

#import "FBQuickTimeExporter.h"
#import "QTMovieExtensions.h"

#pragma mark -
#pragma mark FBQuickTimeExporter Private Interface
@interface FBQuickTimeExporter ()

@property (readwrite, retain) FBReel *reel;
@property (readwrite, retain) NSDictionary *movieAttributes, *exportAttributes;
@property (retain) QTMovie *movie;

- (void) initializeMovieWithSettings: (NSDictionary *) settings;
- (void) initializeMovieToFile: (NSString *) filename
			   framesPerSecond: (NSUInteger) fps
						 codec: (CodecType) codecType
				   compression: (int) compression
		reportProgressDelegate: (id) delegate;

- (Movie)quicktimeMovieWithFilename: (NSString *) filename dataHandler:(DataHandler *)outDataHandler error:(OSErr *)outErr;

- (NSString *) nameForCodec: (CodecType) codec;

@end

#pragma mark -
#pragma mark FBQuickTimeExporter Implementation
@implementation FBQuickTimeExporter
@synthesize reel, movieAttributes, exportAttributes, movie;

#pragma mark -
#pragma mark Initialization and Deallocation
- (id) initWithReel: (FBReel *) aReel
		destination: (NSString *) filename
		 attributes: (NSDictionary *) attributes
{
	if ((self = [super init])) {
		self.reel = aReel;
		self.exportAttributes = attributes;
		
		// TODO: Use actual parameters
		NSNumber *fps = [exportAttributes objectForKey: FBFramesPerSecondAttributeName];
		NSDictionary *initializationSettings = [NSDictionary dictionaryWithObjectsAndKeys:
												filename, @"filename",
												fps == nil ? [NSNumber numberWithUnsignedInteger: 1] : fps, @"fps",
												[NSNumber numberWithUnsignedInteger: 0x61766331], @"codec",
												[NSNumber numberWithUnsignedInteger: codecNormalQuality], @"compression",
												nil];
		
		[self performSelectorOnMainThread: @selector(initializeMovieWithSettings:) withObject: initializationSettings waitUntilDone: YES];
	}
	
	return self;
}

- (void) dealloc
{
	self.reel = nil;
	self.movieAttributes = nil;
	self.exportAttributes = nil;
	self.movie = nil;
	[super dealloc];
}

#pragma mark -
#pragma mark Movie File Initialization
- (void) initializeMovieWithSettings: (NSDictionary *) settings
{
	NSString *filename = [settings objectForKey: @"filename"];
	NSUInteger
		fps = [[settings objectForKey: @"fps"] unsignedIntegerValue],
		codec = [[settings objectForKey: @"codec"] unsignedIntegerValue],
		compression = [[settings objectForKey: @"compression"] unsignedIntegerValue];
	
	[self initializeMovieToFile: filename framesPerSecond: fps codec: codec compression: compression reportProgressDelegate: nil];
}

- (void) initializeMovieToFile: (NSString *) filename
			   framesPerSecond: (NSUInteger) fps
						 codec: (CodecType) codecType
				   compression: (int) compression
		reportProgressDelegate: (id) delegate
{
	QTMovie *mMovie = nil;
	DataHandler mDataHandlerRef;
	
    // Check first if the new QuickTime 7.2.1 initToWritableFile: method is available
	if ([QTMovie instancesRespondToSelector: @selector(initToWritableFile:error:)])
    {
		NSString *tempName = filename;
		
        if (nil == tempName)
			return;
        
        // Create a QTMovie with a writable data reference
        mMovie = [[[QTMovie alloc] initToWritableFile:tempName error:NULL] autorelease];
    }
    else    
    {    
        // The QuickTime 7.2.1 initToWritableFile: method is not available, so use the native 
        // QuickTime API CreateMovieStorage() to create a QuickTime movie with a writable 
        // data reference
        OSErr err = 0;
		
        // create a native QuickTime movie
        Movie qtMovie = [self quicktimeMovieWithFilename: filename dataHandler:&mDataHandlerRef error:&err];
        if (nil == qtMovie)
			return;
		
		if (err) {
			NSLog(@"Error %d while creating movie with filename %@", err, filename);
			
			return;
		}
        
        // instantiate a QTMovie from our native QuickTime movie
        mMovie = [QTMovie movieWithQuickTimeMovie:qtMovie disposeWhenDone:YES error:nil];
		
        if (mMovie == nil) {
			NSLog(@"QuickTime movie is nil");
			
			return;
		}
    }
	
	
	// mark the movie as editable
	[mMovie setAttribute:[NSNumber numberWithBool:YES] forKey:QTMovieEditableAttribute];
	
	// collect movie attributes
	self.movieAttributes = [NSDictionary dictionaryWithObjectsAndKeys: [self nameForCodec: codecType],
							QTAddImageCodecType,
							// [NSNumber numberWithLong:codecHighQuality],
							[NSNumber numberWithLong: compression],
							QTAddImageCodecQuality,
							nil];
	self.movie = mMovie;
}

- (Movie)quicktimeMovieWithFilename: (NSString *) filename dataHandler:(DataHandler *)outDataHandler error:(OSErr *)outErr
{
	*outErr = -1;
	
	// generate a name for our movie file
	//NSString *tempName = [NSString stringWithCString:tmpnam(nil) 
	//										encoding:[NSString defaultCStringEncoding]];
	NSString *tempName = filename;
	
	if (nil == tempName) goto nostring;
	
	Handle	dataRefH		= nil;
	OSType	dataRefType;
	
	// create a file data reference for our movie
	*outErr = QTNewDataReferenceFromFullPathCFString((CFStringRef)tempName,
													 kQTNativeDefaultPathStyle,
													 0,
													 &dataRefH,
													 &dataRefType);
	if (*outErr != noErr) goto nodataref;
	
	// create a QuickTime movie from our file data reference
	Movie	qtMovie	= nil;
	CreateMovieStorage (dataRefH,
						dataRefType,
						'TVOD',
						smSystemScript,
						newMovieActive, 
						outDataHandler,
						&qtMovie);
	*outErr = GetMoviesError();
	if (*outErr != noErr) goto cantcreatemovstorage;
	
	return qtMovie;
	
	// error handling
cantcreatemovstorage:
	DisposeHandle(dataRefH);
nodataref:
nostring:
	
	return nil;
}

- (NSString *) nameForCodec: (CodecType) codec
{
	return [NSFileTypeForHFSTypeCode(codec) stringByReplacingOccurrencesOfString: @"'" withString: @""];
}

#pragma mark -
#pragma mark Adding Images to the Movie
- (void) exportImagesWithIndexes: (NSIndexSet *) indexes
{
	NSArray *images = [self.reel NSImagesAtIndexes: indexes];
	NSNumber *fpsAttribute = [self.exportAttributes objectForKey: FBFramesPerSecondAttributeName];
	NSInteger fps = fpsAttribute == nil ? 1 : [fpsAttribute integerValue];
	
	[self.movie addImagesAsMPEG4: images
				 framesPerSecond: fps
					  attributes: self.movieAttributes
		  reportProgressDelegate: nil];
	[self.movie updateMovieFile];
}

@end
