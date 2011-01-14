//
//  FBReelNavigator(DragDrop).m
//  FrameByFrame
//
//  Created by Philipp Brendel on 19.12.10.
//  Copyright 2010 BrendCorp. All rights reserved.
//

#import "FBReelNavigator(DragDrop).h"

const NSInteger FFMinimumDragDistance =	6;

NSString *FFImagesPboardType = @"FFImagesPboardType", *FBIndexesPboardType = @"FBIndexesPboardType";


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
		NSImage *image = [self iconForDraggingWithCellAt: clickedCell numberOfImages: selectionCount];
		NSPoint location = [self convertPoint: [e locationInWindow] fromView: nil];
		NSSize imageSize = [image size];
		NSBitmapImageRep *rep = [[NSBitmapImageRep alloc] initWithCIImage: self.selectedImage];
		
		// Image position
		location = NSMakePoint(location.x - imageSize.width / 2, location.y);
		
		// Pasteboard
		NSPasteboard *pb = [NSPasteboard pasteboardWithName: NSDragPboard];
		NSArray *pathsOfSelectedFiles = [self.dragDropBuddy pathsOfFilesAtIndexes: self.selectedIndexes];
		
		[pb clearContents];
		[pb addTypes: [NSArray arrayWithObjects: FBIndexesPboardType, NSFilenamesPboardType, nil] owner: self];
		[pb setPropertyList: pathsOfSelectedFiles forType: FBIndexesPboardType];
		[pb setPropertyList: pathsOfSelectedFiles forType: NSFilenamesPboardType];
		
		[rep release];
		
		// Initiate drag operation
		[self dragImage: image
					 at: location
				 offset: NSZeroSize
				  event: e 
			 pasteboard: pb
				 source: self
			  slideBack: YES];
	}
}

#pragma mark -
#pragma mark Creating Drag and Drop Icons
- (NSImage *) dragImageForCell: (NSUInteger) cellIndex numberOfImages: (NSUInteger) numberOfImages
{
	NSAssert(cellIndex < [self count], @"Cell index must be smaller than total number of images in strip");
	
	NSRect destRect = NSMakeRect(0, 0, [self cellWidth], [self cellHeight]);
	NSImage *dragImage = [[NSImage alloc] initWithSize: destRect.size];
	CIImage *cellImage = [self.dataSource reelNavigator: self imageForCellAtIndex: cellIndex];
	CGSize cellImageSize = cellImage.extent.size;
	
	[dragImage lockFocus];
	// Draw the image of the cell being dragged
	[cellImage drawInRect: destRect fromRect: NSMakeRect(0, 0, cellImageSize.width, cellImageSize.height) operation: NSCompositeSourceOver fraction: 0.75];
	
	// Draw the number of images being dragged
	NSDictionary *textAttributes = [NSDictionary dictionaryWithObjectsAndKeys: [NSColor whiteColor], NSForegroundColorAttributeName, nil];
	NSString *text = [NSString stringWithFormat: @"%d", numberOfImages];
	NSSize textSize = [text sizeWithAttributes: textAttributes];
	float max = MAX(textSize.width, textSize.height);
	NSBezierPath *circle = [NSBezierPath bezierPathWithOvalInRect: NSMakeRect(destRect.size.width - 4 - max, 4, max, max)];
	
	[[NSColor redColor] setFill];
	[circle fill];
	
	[text drawAtPoint: NSMakePoint(destRect.size.width - 4 - (max + textSize.width) * 0.5, 4) withAttributes: textAttributes];
	
	[dragImage unlockFocus];
	
	return [dragImage autorelease];
}

#pragma mark Drag target
- (NSDragOperation) draggingEntered:(id < NSDraggingInfo >)sender
{
	NSPasteboard *pb = [sender draggingPasteboard];
	NSArray *types = [pb types];
	
	if ([types containsObject: NSTIFFPboardType] || [types containsObject: NSFilenamesPboardType] || [types containsObject: FBIndexesPboardType])
		return NSDragOperationMove;
	else
		return NSDragOperationNone;
}

- (NSDragOperation) draggingUpdated:(id < NSDraggingInfo >)sender
{
	NSPoint p = [self convertPoint: [sender draggingLocation] fromView: nil];
	NSUInteger cell = [self cellAtPoint: p];
	
	[self setInsertionMark: cell];
	
	return NSDragOperationMove;
}

- (void) draggingExited: (id < NSDraggingInfo >) sender
{
	[self setInsertionMark: -1];
}

- (BOOL) performDragOperation: (id < NSDraggingInfo >) sender
{	
	NSPasteboard *pb = [sender draggingPasteboard];
	NSString *type = [pb availableTypeFromArray: [NSArray arrayWithObjects: FBIndexesPboardType, NSFilenamesPboardType, NSTIFFPboardType, nil]];
	
	NSPoint p = [self convertPoint: [sender draggingLocation] fromView: nil];
	NSUInteger cell = [self cellAtPoint: p];
	
	[self setInsertionMark: -1];
	
	if ([type isEqualToString: NSFilenamesPboardType]) {
		NSArray *filenames = [pb propertyListForType: NSFilenamesPboardType];
		NSArray *importedImages = [FBReelNavigator loadImagesFromFiles: filenames];
		
		[self.dragDropBuddy insertImages: importedImages atIndex: cell];
	} else if ([type isEqualToString: FBIndexesPboardType]) {
		// Move the indexed images 
		// iff this navigator is the dragging source
		if ([sender draggingSource] == self) {			
			[self.dragDropBuddy moveCellsAtIndexes: self.selectedIndexes toIndex: cell];
		} else {
			// If the dragging source is another navigator,
			// obtain file data
			NSArray *filenames = [pb propertyListForType: FBIndexesPboardType];
			NSArray *importedImages = [FBReelNavigator loadImagesFromFiles: filenames];
			
			[self.dragDropBuddy insertImages: importedImages atIndex: cell];
		}
	} else if ([type isEqualToString: NSTIFFPboardType]) {
		NSData *tiffData = [pb dataForType: NSTIFFPboardType];
		
		if (tiffData) {
			CIImage *image = [CIImage imageWithData: tiffData];
			
			[self.dragDropBuddy insertImages: [NSArray arrayWithObject: image] atIndex: cell];
		}
	} else
		return NO;
	
	return YES;
}

#pragma mark -
#pragma mark Creating Drag and Drop Icons
- (NSImage *) iconForDraggingWithCellAt: (NSUInteger) cellIndex numberOfImages: (NSUInteger) numberOfImages
{
	NSAssert(cellIndex < [self count], @"Cell index must be smaller than total number of images in strip");
	
	NSRect destRect = NSMakeRect(0, 0, [self cellWidth], [self cellHeight]);
	NSImage *dragImage = [[NSImage alloc] initWithSize: destRect.size];
	NSImage *cellImage = [self.dataSource reelNavigator: self thumbnailForCellAtIndex: cellIndex];
	NSSize cellImageSize = cellImage.size;
	
	[dragImage lockFocus];
	// Draw the image of the cell being dragged
	[cellImage drawInRect: destRect fromRect: NSMakeRect(0, 0, cellImageSize.width, cellImageSize.height) operation: NSCompositeSourceOver fraction: 0.75];
	
	// Draw the number of images being dragged
	NSDictionary *textAttributes = [NSDictionary dictionaryWithObjectsAndKeys: [NSColor whiteColor], NSForegroundColorAttributeName, nil];
	NSString *text = [NSString stringWithFormat: @"%d", numberOfImages];
	NSSize textSize = [text sizeWithAttributes: textAttributes];
	float max = MAX(textSize.width, textSize.height);
	NSBezierPath *circle = [NSBezierPath bezierPathWithOvalInRect: NSMakeRect(destRect.size.width - 4 - max, 4, max, max)];
	
	[[NSColor redColor] setFill];
	[circle fill];
	
	[text drawAtPoint: NSMakePoint(destRect.size.width - 4 - (max + textSize.width) * 0.5, 4) withAttributes: textAttributes];
	
	[dragImage unlockFocus];
	
	return [dragImage autorelease];
}

@end
