/*
 *  FBDragDropBuddy.h
 *  FrameByFrame
 *
 *  Created by Philipp Brendel on 19.12.10.
 *  Copyright 2010 BrendCorp. All rights reserved.
 *
 */

@protocol FBDragDropBuddy <NSObject>

- (NSArray *) namesOfFilesAtIndexes: (NSIndexSet *) indexes forDestination: (NSURL *) destination;
- (NSArray *) pathsOfFilesAtIndexes: (NSIndexSet *) indexes;

- (void) insertImages: (NSArray *) images atIndex: (NSUInteger) index;
- (void) insertImages: (NSArray *) images atIndexes: (NSIndexSet *) indexes;
- (void) moveCellsAtIndexes: (NSIndexSet *) sourceIndexes toIndex: (NSUInteger) destinationIndex;
- (void) moveCellsAtIndexes: (NSIndexSet *) sourceIndexes toIndexes: (NSIndexSet *) destinationIndexes;
- (void) removeImagesAtIndexes: (NSIndexSet *) indexes;

@end
