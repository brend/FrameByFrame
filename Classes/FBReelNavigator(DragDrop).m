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
#pragma mark Drag Source
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

- (NSArray *)namesOfPromisedFilesDroppedAtDestination:(NSURL *)dropDestination
{
	//NSArray *selectedImages = [self selectedImages];
//	NSMutableArray *names = [NSMutableArray arrayWithCapacity: [selectedImages count]];
//	int i;
//	
//	for (i = 0; i < [selectedImages count]; ++i) {
//		NSImage *image = [selectedImages objectAtIndex: i];
//		NSString *filename = [NSString stringWithFormat: @"FF%05d.tiff", i + 1];
//		NSURL *fileURL = [NSURL URLWithString: filename relativeToURL: dropDestination];
//		
//		[[image TIFFRepresentation] writeToURL: fileURL atomically: YES];
//		[names addObject: filename];
//	}
//	
//	return names;
//	
	
	
	NSArray *sourceURLs = [self.dataSource urlsForImagesAtIndexes: self.selectedIndexes];
	NSMutableArray *names = [NSMutableArray arrayWithCapacity: sourceURLs.count];
	NSFileManager *fileManager = [NSFileManager defaultManager];

	for (NSURL *source in sourceURLs) {
		NSError *error = nil;
		NSString *name = source.lastPathComponent;
		NSURL *destination = [dropDestination URLByAppendingPathComponent: name];
		
		if ([fileManager copyItemAtURL: source toURL: destination error: &error]) {
			[names addObject: name];
		}
		else {
			NSLog(@"Error copying file from %@ to %@ : %@", source, destination, error);
		}
	}
	
	return names;
}

- (NSImage *) dragImageForCell: (NSUInteger) cellIndex numberOfImages: (NSUInteger) numberOfImages
{
	NSAssert(cellIndex < [self count], @"Cell index must be smaller than total number of images in strip");
	
	NSRect destRect = NSMakeRect(0, 0, [self cellWidth], [self cellHeight]);
	NSImage *dragImage = [[NSImage alloc] initWithSize: destRect.size];
	
	CIImage *ciImage = [self.dataSource reelNavigator: self imageForCellAtIndex: cellIndex];
	NSBitmapImageRep *ciImageRep = [[NSBitmapImageRep alloc] initWithCIImage: ciImage];
	NSImage *cellImage = [[NSImage alloc] init];
	NSSize cellImageSize = cellImage.size;
	
	[cellImage addRepresentation: ciImageRep];
	[ciImageRep release];
	
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
	[cellImage release];
	
	return [dragImage autorelease];
}

#pragma mark -
#pragma mark Drag target
- (NSDragOperation) draggingEntered:(id < NSDraggingInfo >)sender
{
	NSPasteboard *pb = [sender draggingPasteboard];
	NSArray *types = [pb types];
	
	if ([types containsObject: NSTIFFPboardType] 
		|| [types containsObject: NSFilenamesPboardType] 
		|| [types containsObject: FFIndicesPboardType]) {
		
		return NSDragOperationMove;
	} else
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

/*
 - (BOOL) prepareForDragOperation: (id < NSDraggingInfo >) sender
 {
 NSLog(@"Preparing");
 return YES;
 }
 */

- (BOOL) performDragOperation: (id < NSDraggingInfo >) sender
{	
	NSPasteboard *pb = [sender draggingPasteboard];
	NSString *type = [pb availableTypeFromArray: [NSArray arrayWithObjects: FFIndicesPboardType, NSFilenamesPboardType, NSTIFFPboardType, nil]];
	NSPoint p = [self convertPoint: [sender draggingLocation] fromView: nil];
	NSUInteger cell = [self cellAtPoint: p];
	
	[self setInsertionMark: -1];
	
	if ([type isEqualToString: FFIndicesPboardType]) {
		BOOL imageArrayData = YES;
		if (imageArrayData) {
			NSArray *pastedImages = [(FBReelNavigator *) [sender draggingSource] selectedImages];
			
			if (pastedImages) {
				if ([sender draggingSource] == self) {
					NSIndexSet *sourceIndices = [self selectedIndexes];
					int finalDestination = cell - [sourceIndices countOfIndexesInRange: NSMakeRange(0, cell)];
					
					[self removeObjectsAtIndexes: sourceIndices];
					[self insertObjects: pastedImages atIndex: finalDestination];
				} else
					[self insertObjects: pastedImages atIndex: cell];
			} else {
				NSLog(@"Could not unarchive pasteboard data for type %@", FFIndicesPboardType);
				return NO;
			}
		} else {
			NSLog(@"No data in pasteboard for type %@", FFIndicesPboardType);
			return NO;
		}
	} else if ([type isEqualToString: NSFilenamesPboardType]) {
		NSArray *filenames = [pb propertyListForType: NSFilenamesPboardType];
		NSArray *importedImages = [FBReelNavigator loadImagesFromFiles: filenames];
		
		[self insertObjects: importedImages atIndex: cell];
	} else if ([type isEqualToString: NSTIFFPboardType]) {
	} else
		return NO;
	
	return YES;
}

/*
 - (void) concludeDragOperation: (id < NSDraggingInfo >) sender
 {
 }
 */

- (NSInteger) cellAtPoint: (NSPoint) p
{
	return (NSUInteger) MIN(round(p.x / [self cellWidth]), [self count]);
}

#pragma mark -
#pragma mark Insertion mark
- (NSInteger) insertionMark
{
	return insertionMark;
}

- (void) setInsertionMark: (NSInteger) index
{
	if (index < -1 || index > [self count] + 1)
		NSLog(@"Suspicious insertion mark index: %d (strip has %d elements)", index, [self count]);
	
	insertionMark = index;
	[self setNeedsDisplay: YES];
}

@end
