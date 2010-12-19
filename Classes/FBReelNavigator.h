//
//  FBReelNavigator.h
//  TestApp-MyImageView
//
//  Created by Philipp Brendel on 08.01.08.
//  Copyright 2009 Philipp Brendel. All rights reserved.
//
/*
 This file is part of FrameByFrame.
 
 FrameByFrame is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.
 
 FrameByFrame is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with FrameByFrame.  If not, see <http://www.gnu.org/licenses/>.
 */

#import <Cocoa/Cocoa.h>
#import "FBReel.h"
#import "FBReelNavigatorDelegate.h"
#import "FBReelNavigatorDataSource.h"

extern NSString *FFIndicesPboardType, *FFImagesPboardType;

#pragma mark -
#pragma mark FBReelNavigator Interface
@interface FBReelNavigator : NSView 
{
	IBOutlet NSScrollView *scrollView;
	IBOutlet id<FBReelNavigatorDelegate> delegate;
	IBOutlet id<FBReelNavigatorDataSource> dataSource;
		
	NSMutableIndexSet *selectedIndexes;
	
	CIImage *currentImage;
	
	NSColor *highlightColor, *selectionColor;
	NSUInteger framesPerSecond;
	
	NSPoint mouseDownPosition;
	NSUInteger mouseDownCell;
	NSInteger insertionMark;
}

//@property (readonly) FBReel *reel;
@property(readonly) NSInteger count;
@property(copy) NSMutableIndexSet *selectedIndexes;
@property(readonly) NSUInteger selectedIndex, framesPerSecond;
@property(readonly) CIImage *selectedImage;
@property(retain) CIImage *currentImage;
@property(retain) NSColor *highlightColor, *selectionColor;

#pragma mark Delegate and Data Source
@property (readonly) id<FBReelNavigatorDelegate> delegate;
@property (readonly) id<FBReelNavigatorDataSource> dataSource;

#pragma mark Adding Representations to Images
+ (NSArray *) addTIFFRepresentations: (NSArray *) images;

#pragma mark Adding and Removing Images
- (void) addObject: (CIImage *) image;
- (void) insertObject: (CIImage *) image atIndex: (NSUInteger) index;
- (void) insertObjects: (NSArray *) images atIndex: (NSUInteger) index;
- (void) insertObjects: (NSArray *) images atIndexes: (NSIndexSet *) indexes;
- (void) removeObjectsAtIndexes: (NSIndexSet *) indexes;

#pragma mark Retrieving Images
//- (CIImage *) objectAtIndex: (NSUInteger) index;
- (NSArray *) imagesAtIndexes: (NSIndexSet *) indexes;

#pragma mark Cell Measures
- (float) cellWidth;
- (float) cellInteriorWidth;
- (float) cellBorderWidth;
- (float) cellHeight;
- (float) cellInteriorHeight;
- (float) cellBorderHeight;

#pragma mark Resize to fit Images
- (void) resizeToFitImages;

#pragma mark IB Add, Remove
- (IBAction) add: (id) sender;
- (IBAction) remove: (id) sender;

#pragma mark Handling Selection
@property (readonly) NSArray *selectedImages;
@property NSInteger insertionMark;
- (void) shiftSelectionToRight;
- (void) shiftSelectionToLeft;
- (void) shiftSelectionToBeginning;
- (void) shiftSelectionToEnd;
- (NSInteger) cellAtPoint: (NSPoint) p;

#pragma mark Scrolling
- (void) scrollToImage: (NSUInteger) index;
- (BOOL) imageVisible: (NSUInteger) index;

#pragma mark Loading Images from Files
+ (NSArray *) loadImagesFromFiles: (NSArray *) filenames;

#pragma mark Making Snapshots
- (void) requestSnapshot;

#pragma mark Handling Resolution Issues
+ (void) adaptImageSizeToResolution: (NSArray *) images;

#pragma mark Take Action Whenever the Reel Changes
- (void) reelHasChanged;

@end
