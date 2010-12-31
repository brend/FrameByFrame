//
//  FBReel.h
//  FrameByFrame
//
//  Created by Philipp Brendel on 30.10.10.
//  Copyright (c) 2010 BrendCorp. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "FBCell.h"

@interface FBReel : NSObject <NSCoding>
{
@private
	NSMutableArray *cells;
	NSURL *documentURL;
	
	NSUInteger recentImageIndex;
}

#pragma mark -
#pragma mark Reel Creation
+ (id) reel;
+ (id) reelWithContentsOfURL: (NSURL *) url error: (NSError **) error;
+ (id) reelWithContentsOfDirectory: (NSURL *) directoryURL error: (NSError **) error;

#pragma mark -
#pragma mark Reel Sanity
+ (NSArray *) systemFilenames;
+ (NSArray *) readableMagics;
+ (BOOL) saneFile: (NSString *) filename atPath: (NSString *) path;

#pragma mark -
#pragma mark Replacing Reel Contents
- (BOOL) readContentsOfURL: (NSURL *) url error: (NSError **) error;

#pragma mark -
#pragma mark Saving the Reel
@property (retain) NSURL *documentURL;
- (BOOL) writeToURL: (NSURL *) url error: (NSError **) error;

#pragma mark -
#pragma mark Querying the Reel
- (NSUInteger) count;
- (NSArray *) urlsForImagesAtIndexes: (NSIndexSet *) indexes;

#pragma mark -
#pragma mark Adding and Retrieving Cells
- (void) addCell: (FBCell *) cell;
- (void) insertCell: (FBCell *) cell
			atIndex: (NSUInteger) i;
- (void) insertCells: (NSArray *) someCells
		   atIndexes: (NSIndexSet *) indexes;
- (void) insertCells: (NSArray *) someCells
			 atIndex: (NSUInteger) index;
- (FBCell *) cellAtIndex: (NSUInteger) i;
- (NSArray *) cellsAtIndexes: (NSIndexSet *) indexes;
- (FBCell *) lastCell;

#pragma mark -
#pragma mark Rearranging Cells
- (NSUInteger) moveCellsAtIndexes: (NSIndexSet *) indexes toIndex: (NSUInteger) destinationIndex;
- (void) moveCellsAtIndexes: (NSIndexSet *) indexes toIndexes: (NSIndexSet *) destinationIndexex;

#pragma mark -
#pragma mark Removing Cells
- (void) removeCellsAtIndexes: (NSIndexSet *) indexes;

#pragma mark -
#pragma mark Adding and Retrieving Images
- (void) addCellWithImage: (CIImage *) picture;
- (void) insertCellWithImage: (CIImage *) image
					 atIndex: (NSUInteger) i;
- (void) insertCellsWithImages: (NSArray *) images
					 atIndexes: (NSIndexSet *) indexes;
- (CIImage *) imageAtIndex: (NSUInteger) i;
- (NSArray *) imagesAtIndexes: (NSIndexSet *) indexes;
- (NSArray *) NSImagesAtIndexes: (NSIndexSet *) indexes;

#pragma mark -
#pragma mark Removing Images
- (void) removeImagesAtIndexes: (NSIndexSet *) indexes;

#pragma mark -
#pragma mark Creating Cell Identifiers
- (NSString *) createUniqueCellIdentifier;

@end
