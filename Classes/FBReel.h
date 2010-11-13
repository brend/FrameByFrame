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
}

#pragma mark -
#pragma mark Reel Creation
+ (id) reel;
+ (id) reelWithContentsOfURL: (NSURL *) url error: (NSError **) error;

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

#pragma mark -
#pragma mark Adding and Retrieving Cells

- (void) addCell: (FBCell *) cell;
- (void) insertCell: (FBCell *) cell
			atIndex: (NSUInteger) i;
- (void) insertCells: (NSArray *) someCells
		   atIndexes: (NSIndexSet *) indexes;
- (FBCell *) cellAtIndex: (NSUInteger) i;
- (FBCell *) lastCell;

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

#pragma mark -
#pragma mark Removing Images
- (void) removeImagesAtIndexes: (NSIndexSet *) indexes;

#pragma mark -
#pragma mark Creating Cell Identifiers
- (NSString *) createUniqueCellIdentifier;

@end