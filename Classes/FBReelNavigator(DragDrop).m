//
//  FBReelNavigator(DragDrop).m
//  FrameByFrame
//
//  Created by Philipp Brendel on 19.12.10.
//  Copyright 2010 BrendCorp. All rights reserved.
//

#import "FBReelNavigator(DragDrop).h"

const NSInteger FFMinimumDragDistance =	6;

NSString *FFIndicesPboardType = @"FFIndicesPboardType", *FFImagesPboardType = @"FFImagesPboardType";


@implementation FBReelNavigator (DragDrop)

#pragma mark -
#pragma mark Initializing Drag and Drop
- (void) mouseDragged: (NSEvent *) e
{
	NSPoint p = [self convertPoint: [e locationInWindow] fromView: nil];
	NSUInteger clickedCell = mouseDownCell;
	
	if (MAX(ABS(p.x - mouseDownPosition.x), ABS(p.y - mouseDownPosition.y)) < FFMinimumDragDistance)
		return;
	
	if (clickedCell < [self count]) {
		NSUInteger selectionCount = [[self selectedIndexes] count];
		NSImage *image = [self dragImageForCell: clickedCell numberOfImages: selectionCount];
		NSPoint location = [self convertPoint: [e locationInWindow] fromView: nil];
		NSSize imageSize = image.size;
		
		// Image position
		location = NSMakePoint(location.x - imageSize.width / 2, location.y);
		
		[self dragPromisedFilesOfTypes: [NSArray arrayWithObject: @"tiff"] fromRect: NSMakeRect(location.x - 16, location.y - 16, 32, 32) source: self slideBack: YES event: e];
	}
}

#pragma mark -
#pragma mark Drag Source
- (void) dragImage: (NSImage *) oldImage at: (NSPoint) location offset: (NSSize) size event: (NSEvent *) e pasteboard: (NSPasteboard *) pb source: (id) source slideBack: (BOOL) slideBack
{
	NSPoint p = [self convertPoint: [e locationInWindow] fromView: nil];
	NSUInteger clickedCell = (NSUInteger) floor(p.x / [self cellWidth]);
	
	if (clickedCell < [self count]) {
		NSUInteger selectionCount = [[self selectedIndexes] count];
		NSImage *image = [self dragImageForCell: clickedCell numberOfImages: selectionCount];
		NSPoint location = [self convertPoint: [e locationInWindow] fromView: nil];
		NSSize imageSize = [image size];
		NSBitmapImageRep *rep = [[NSBitmapImageRep alloc] initWithCIImage: self.selectedImage];
		
		// Image position
		location = NSMakePoint(location.x - imageSize.width / 2, location.y);
		
		// Pasteboard
		[pb addTypes: [NSArray arrayWithObjects: 
					   NSTIFFPboardType, NSStringPboardType,
					   FFIndicesPboardType, nil] owner: self];
		[pb setData: [rep TIFFRepresentation] forType: NSTIFFPboardType];
		[pb setData: [NSData data] forType: FFIndicesPboardType];
		
		[rep release];
		
		[super dragImage: image at: location offset: NSZeroSize event: e pasteboard: pb source: self slideBack: YES];
	}
}

@end
