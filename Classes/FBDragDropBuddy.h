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
- (void) insertImages: (NSArray *) images atIndex: (NSUInteger) index;

@end

