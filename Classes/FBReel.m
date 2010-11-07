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
@end

#pragma mark -
#pragma mark FBReel Implementation
@implementation FBReel
@synthesize cells;

#pragma mark -
#pragma mark Initialization and Deallocation
- (id)init 
{
    if ((self = [super init])) {
		self.cells = [NSMutableArray arrayWithCapacity: 1024];
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
	}
	
	return self;
}

+ (id) reel
{
	return [[[FBReel alloc] init] autorelease];
}

+ (id) reelWithContentsOfURL: (NSURL *) url error: (NSError **) error
{
	NSError *intermediateError = nil;
	NSString *path = [[url path] stringByAppendingPathComponent: @"reel"];
	NSData *data = [NSData dataWithContentsOfFile: path options: 0 error: &intermediateError];
	
	if (data == nil) {
		if (error)
			*error = intermediateError;
		
		return nil;
	}
	
	FBReel *reel = [NSKeyedUnarchiver unarchiveObjectWithData: data];
	
	return reel;
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
		// TODO Parallelize
		
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
	
	return cell.image;
}

- (NSArray *) imagesAtIndexes:(NSIndexSet *)indexes
{
	NSLog(@"DEBUG Denk dran, dass -imagesAtIndexes: ein Array aus CIImage liefert");
	NSArray *addressedCells = [self.cells objectsAtIndexes: indexes];
	NSMutableArray *images = [NSMutableArray arrayWithCapacity: indexes.count];
	
	for (FBCell *cell in addressedCells)
		[images addObject: cell.image];
	
	return images;
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
