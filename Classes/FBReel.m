//
//  FBReel.m
//  FrameByFrame
//
//  Created by Philipp Brendel on 30.10.10.
//  Copyright (c) 2010 BrendCorp. All rights reserved.
//

#import "FBReel.h"

#pragma mark Private FBReel Interface
@interface FBReel ()
@property (retain) NSMutableArray *cells;
@property NSUInteger recentImageIndex;
@end

#pragma mark -
#pragma mark FBReel Implementation
@implementation FBReel
@synthesize cells, recentImageIndex;

static NSArray *FBSystemFilenames = nil, *FBReadableMagics = nil;

#pragma mark -
#pragma mark Initialization and Deallocation
- (id)init 
{
    if ((self = [super init])) {
		self.cells = [NSMutableArray arrayWithCapacity: 1024];
		self.recentImageIndex = NSNotFound;
    }
    
    return self;
}

- (id) initWithCoder:(NSCoder *)aDecoder
{
	if ((self = [super init])) {
		NSArray *savedCells = [aDecoder decodeObjectForKey: @"cells"];
		
		if (savedCells == nil)
			NSLog(@"No cells could be decoded");
		
		self.cells = savedCells == nil ? [NSMutableArray array] : [NSMutableArray arrayWithArray: savedCells];
		self.recentImageIndex = NSNotFound;
	}
	
	return self;
}

+ (void) initialize
{
	FBSystemFilenames = [[NSArray alloc] initWithObjects: @"QuickLook", @"reel", @"settings", nil];
	
	// Magic numbers are as follows (not all are in use)
	// BMP	0x424D
	// JPG	0xFFD8FFE0
	// PNG	0x89504E47
	// TIFF	0x4D4D002A
	NSArray *magicNumbers = [NSArray arrayWithObjects: @"MM", @"BM", nil];
	NSMutableArray *magicData = [NSMutableArray array];
	
	for (NSString *mn in magicNumbers)
		[magicData addObject: [mn dataUsingEncoding: NSASCIIStringEncoding]];
	
	FBReadableMagics = [[NSArray alloc] initWithArray: magicData];
}

+ (id) reel
{
	return [[[FBReel alloc] init] autorelease];
}

+ (id) reelWithContentsOfURL: (NSURL *) url error: (NSError **) outError
{
	NSError *intermediateError = nil;
	NSString *path = [[url path] stringByAppendingPathComponent: @"reel"];
	NSData *data = [NSData dataWithContentsOfFile: path options: 0 error: &intermediateError];
	
	if (data == nil) {
		if (outError)
			*outError = intermediateError;
		
		return nil;
	}
	
	FBReel *reel = nil;
	
	@try {
		reel = [NSKeyedUnarchiver unarchiveObjectWithData: data];
	} @catch (NSException *e) {
		NSLog(@"Error unarchiving reel: %@", e);
		
		if (outError)
			*outError = [NSError errorWithDomain: [e description] code: 0 userInfo: nil];
		
		return nil;
	}
	
	// Perform sanity check on reel files
	NSMutableIndexSet *insaneIndexes = [NSMutableIndexSet indexSet];
	
	for (NSInteger i = 0; i < reel.count; ++i) {
		FBCell *cell = [reel cellAtIndex: i];
		
		if (![FBReel saneFile: cell.identifier atPath: url.path]) {
			NSLog(@"Insane reel reference: %@", cell.identifier);
			[insaneIndexes addIndex: i];
		}
	}
	[reel removeCellsAtIndexes: insaneIndexes];
	
	return reel;
}

+ (id) reelWithContentsOfDirectory: (NSURL *) directoryURL error: (NSError **) error
{
	NSError *intermediateError = nil;
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSString *directoryPath = directoryURL.path;
	NSArray *files = [fileManager contentsOfDirectoryAtPath: directoryURL.path error: &intermediateError];
	NSMutableArray *cells = [NSMutableArray arrayWithCapacity: files.count];
	
	if (files) {
		for (NSString *file in files) {
			if ([FBReel saneFile: file atPath: directoryPath]) {
				FBCell *cell = [[FBCell alloc] initWithIdentifier: file];
				
				[cell setDocumentURL: directoryURL];
				[cells addObject: cell];
				[cell release];
			} else {
				NSLog(@"Insane file not added to reel: %@", file);
			}

		}
		
		FBReel *reel = [FBReel reel];
		
		reel.documentURL = directoryURL;
		reel.cells = cells;
		
		return reel;
	} else {
		if (error)
			*error = intermediateError;
		
		return nil;
	}
}

- (BOOL) readContentsOfURL: (NSURL *) url error: (NSError **) error
{
	FBReel *reel = [FBReel reelWithContentsOfURL: url error: error];
	
	if (reel) {
		self.cells = [NSMutableArray arrayWithArray: reel.cells];
		self.documentURL = reel.documentURL;
	}
	
	return reel != nil;
}

- (void)dealloc 
{
	self.cells = nil;
	
    [super dealloc];
}

#pragma mark -
#pragma mark NSCoding Implementation
- (void) encodeWithCoder:(NSCoder *)aCoder
{
	[aCoder encodeObject: self.cells forKey: @"cells"];
}

#pragma mark -
#pragma mark Reel Sanity
+ (NSArray *) systemFilenames
{
	return FBSystemFilenames;
}

+ (NSArray *) readableMagics
{
	return FBReadableMagics;
}

+ (BOOL) saneFile: (NSString *) filename atPath: (NSString *) path
{
	if ([[FBReel systemFilenames] containsObject: filename])
		return NO;
		
	NSFileHandle *fileHandle = [NSFileHandle fileHandleForReadingAtPath: [path stringByAppendingPathComponent: filename]];
	
	if (fileHandle == nil)
		return NO;
	
	NSData *magic = [fileHandle readDataOfLength: 2];
	
	return [[FBReel readableMagics] containsObject: magic];
}

#pragma mark -
#pragma mark Saving the Reel
// @synthesize documentURL;

- (NSURL *) documentURL
{
	return documentURL;
}

- (void) setDocumentURL:(NSURL *) aURL
{
	[documentURL autorelease];
	documentURL = [aURL retain];
	
	for (FBCell *cell in self.cells)
		cell.documentURL = aURL;
}

- (BOOL) writeToURL: (NSURL *) url error: (NSError **) error
{
	NSData *data = [NSKeyedArchiver archivedDataWithRootObject: self];
	NSString *path = [[url path] stringByAppendingPathComponent: @"reel"];
	NSError *intermediateError = nil;
	
	if (![data writeToFile: path options: 0 error: &intermediateError]) {
		if (error)
			*error = intermediateError;
		
		return NO;
	}
	
	return YES;
}

#pragma mark -
#pragma mark Querying the Reel
- (NSUInteger) count
{
	return self.cells.count;
}

#pragma mark -
#pragma mark Adding, Retrieving and Counting Pictures
- (void) insertCell: (FBCell *) cell
			atIndex: (NSUInteger) i
{
	[self insertCells: [NSArray arrayWithObject: cell] atIndexes: [NSIndexSet indexSetWithIndex: i]];
}

- (void) insertCells: (NSArray *) someCells
		   atIndexes: (NSIndexSet *) indexes
{
	for (FBCell *cell in someCells)
		cell.documentURL = self.documentURL;
	
	[self.cells insertObjects: someCells atIndexes: indexes];
	
	if (self.documentURL) {		
		for (FBCell *cell in someCells) {
			NSString *filename = [self.documentURL.path stringByAppendingPathComponent: cell.identifier];
			NSError *error = nil;
			
			if (![cell writeToFile: filename error: &error]) {
				NSLog(@"Cell could not be written to %@ due to error: %@", filename, error);
			}
		}
	}
}

- (void) addCell:(FBCell *)cell
{
	[self insertCell: cell atIndex: self.count];
}

- (FBCell *) cellAtIndex:(NSUInteger)i
{
	return [self.cells objectAtIndex: i];
}

- (FBCell *) lastCell
{
	NSAssert(self.cells.count > 0, @"Cell count must be greater than zero");
	
	return [self.cells objectAtIndex: self.cells.count - 1];
}

#pragma mark -
#pragma mark Removing Cells
- (void) removeCellsAtIndexes: (NSIndexSet *) indexes
{
	[self.cells removeObjectsAtIndexes: indexes];
}

#pragma mark -
#pragma mark Adding and Retrieving Images
- (void) addCellWithImage:(CIImage *) image
{
	[self insertCellWithImage: image atIndex: self.count];
}

- (void) insertCellWithImage: (CIImage *) image
					 atIndex: (NSUInteger) i
{
	[self insertCellsWithImages: [NSArray arrayWithObject: image] atIndexes: [NSIndexSet indexSetWithIndex: i]];
}

- (void) insertCellsWithImages: (NSArray *) images
					 atIndexes: (NSIndexSet *) indexes
{
	NSAssert(indexes.count == images.count, @"Number of images doesn't fit number of indexes");
	
	NSMutableArray *imageCells = [NSMutableArray arrayWithCapacity: indexes.count];
	
	for (CIImage *image in images) {
		NSString *identifier = [self createUniqueCellIdentifier];
		FBCell *cell = [FBCell cellWithIdentifier: identifier image: image];
		
		[imageCells addObject: cell];
	}
	
	[self insertCells: imageCells atIndexes: indexes];
}

- (CIImage *) imageAtIndex: (NSUInteger) i
{
	FBCell *cell = [self cellAtIndex: i];
	
	// Release images not in range [i - FBMaxSkinCount, ..., i + maxSkinCount]
	NSInteger n = self.count;
	
	for (NSInteger k = 0; k < n; ++k) {
		if (abs(i - k) > FBMaxSkinCount) {
			[[self cellAtIndex: k] setImage: nil];
		}
	}
	
	self.recentImageIndex = i;
	
	return cell.image;
}

- (NSArray *) imagesAtIndexes:(NSIndexSet *)indexes
{
	NSArray *addressedCells = [self.cells objectsAtIndexes: indexes];
	NSMutableArray *images = [NSMutableArray arrayWithCapacity: indexes.count];
	
	for (FBCell *cell in addressedCells)
		[images addObject: cell.image];
	
	return images;
}

- (NSArray *) NSImagesAtIndexes: (NSIndexSet *) indexes
{
	NSArray *ciImages = [self imagesAtIndexes: indexes];
	NSMutableArray *nsImages = [NSMutableArray arrayWithCapacity: ciImages.count];
	
	for (CIImage *coreImage in ciImages) {
		NSBitmapImageRep *rep = [[NSBitmapImageRep alloc] initWithCIImage: coreImage];
		NSImage *image = [[NSImage alloc] init];
		
		[image addRepresentation: rep];
		[nsImages addObject: image];
		[rep release];
		[image release];
	}
	
	return nsImages;
}

#pragma mark -
#pragma mark Removing Images
- (void) removeImagesAtIndexes: (NSIndexSet *) indexes
{
	[self removeCellsAtIndexes: indexes];
}

#pragma mark -
#pragma mark Creating Cell Identifiers
- (NSString *) createUniqueCellIdentifier
{
	return [NSString stringWithFormat: @"%f", [NSDate timeIntervalSinceReferenceDate]];
}

@end
