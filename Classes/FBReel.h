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
#pragma mark Saving the Reel
@property (retain) NSURL *documentURL;
- (BOOL) writeToURL: (NSURL *) url error: (NSError **) error;

#pragma mark -
#pragma mark Adding, Retrieving and Counting Images
- (NSInteger) count;
- (void) addCellWithImage: (CIImage *) picture;
- (void) addCell: (FBCell *) cell;
- (CIImage *) imageAtIndex: (NSInteger) i;
- (FBCell *) cellAtIndex: (NSInteger) i;
@property (readonly) FBCell *lastCell;

- (NSString *) createUniqueCellIdentifier;

@end
