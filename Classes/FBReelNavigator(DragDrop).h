//
//  FBReelNavigator(DragDrop).h
//  FrameByFrame
//
//  Created by Philipp Brendel on 19.12.10.
//  Copyright 2010 BrendCorp. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "FBReelNavigator.h"

@interface FBReelNavigator (DragDrop)

#pragma mark -
#pragma mark Drag Source
- (void) mouseDragged: (NSEvent *) e;

#pragma mark -
#pragma mark Creating Drag and Drop Icons
- (NSImage *) iconForDraggingWithCellAt: (NSUInteger) cellIndex numberOfImages: (NSUInteger) numberOfImages;

@end
