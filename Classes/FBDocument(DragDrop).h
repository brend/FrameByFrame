//
//  FBDocument(DragDrop).h
//  FrameByFrame
//
//  Created by Philipp Brendel on 19.12.10.
//  Copyright 2010 BrendCorp. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "FBDocument.h"

@interface FBDocument (DragDrop)

- (NSArray *) namesOfFilesAtIndexes: (NSIndexSet *) indexes forDestination: (NSURL *) destination;
- (void) insertImages: (NSArray *) images atIndex: (NSUInteger) index;

@end
