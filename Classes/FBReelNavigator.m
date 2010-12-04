//
//  FBReelNavigator.m
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


#import "FBReelNavigator.h"

#define FFMinimumDragDistance	6

NSString *FFIndicesPboardType = @"FFIndicesPboardType", *FFImagesPboardType = @"FFImagesPboardType";

// Declaration of private FBReelNavigator methods
@interface FBReelNavigator ( private )
- (NSArray *) selectedImages;
- (NSInteger) cellAtPoint: (NSPoint) p;
- (NSImage *) dragImageForCell: (NSUInteger) cellIndex numberOfImages: (NSUInteger) images;
@end

// FBReelNavigator implementation
@implementation FBReelNavigator

@synthesize currentImage, selectionColor, highlightColor;
//@synthesize reel;
@synthesize dataSource, delegate;
@dynamic count, selectedIndexes, selectedIndex, selectedImage, framesPerSecond;

#pragma mark Key-Value Coding
+ (NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)key
{
	if ([key isEqualToString: @"selectedImage"])
		return [NSSet setWithObject: @"selectedIndexes"];
	else
		return [NSSet set];
}

#pragma mark Adding Representations to Images
+ (NSArray *) addTIFFRepresentations: (NSArray *) images
{
	for (NSImage *image in images) {
		NSData *tiff = [image TIFFRepresentation];
		NSBitmapImageRep *rep = [NSBitmapImageRep imageRepWithData: tiff];
		
		[image addRepresentation: rep];
	}
	
	return images;
}

#pragma mark Initialization and Deallocation
- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
		selectedIndexes = [[NSMutableIndexSet alloc] init];
		
		selectionColor = [[[NSColor blueColor] colorWithAlphaComponent: 0.3] retain];
		highlightColor = [[NSColor colorWithDeviceRed: 0.6 green: 0.86 blue: 1 alpha: 0.3] retain];
		
		insertionMark = -1;
    }
    return self;
}

- (void) dealloc
{
	// NOTE "reel" is an Interface Builder Outlet; do not release
//	reel = nil;
	[currentImage release];
	currentImage = nil;
	delegate = nil; // Delegate will not be retained upon assignment
	[super dealloc];
}

- (void) awakeFromNib
{
	[self registerForDraggedTypes: [NSArray arrayWithObjects: NSTIFFPboardType, NSFilenamesPboardType, FFIndicesPboardType, nil]];
}

- (NSInteger) count
{
//	return self.reel.count;
	return [self.dataSource numberOfCellsForReelNavigator: self];
}

#pragma mark Drawing
- (void)drawRect:(NSRect)rect 
{
	float spf = 1.0f / (float) [self framesPerSecond];
	NSString *secondUnitName = NSLocalizedString(@"FFSecondUnitName", @"sec.");
	NSUInteger i;
	
	NSDictionary *textAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
													[NSColor orangeColor], NSForegroundColorAttributeName,
													nil];
	
	// Draw the images
	for (i = 0; i < [self count]; ++i) {
		NSRect cellExterior = NSMakeRect(i * [self cellWidth], 0, [self cellWidth], [self cellHeight]);
		NSRect dest = 
			// NSMakeRect(cellExterior.origin.x + [self cellBorderWidth], [self cellBorderHeight], [self cellInteriorWidth], [self cellInteriorHeight]);
			NSMakeRect(cellExterior.origin.x + [self cellBorderWidth], [self cellBorderHeight], [self cellInteriorWidth], [self cellInteriorHeight]);
		
		if (NSIntersectsRect(rect, dest)) {
			NSImage *image = [self.dataSource reelNavigator: self thumbnailForCellAtIndex: i];
			NSSize imageSize = image.size;
			
			// Draw image
			[image drawInRect: dest fromRect: NSMakeRect(0, 0, imageSize.width, imageSize.height) operation: NSCompositeSourceOver fraction: 1];
			
			// Draw selection/highlight
			if ([selectedIndexes containsIndex: i]) {
				[(i == [self selectedIndex] ? selectionColor : highlightColor) setFill];
				[NSBezierPath fillRect: dest];
			}
			
			// Draw time indicator
			float second = i * spf;
			NSString *timeFormat = [NSString stringWithFormat: @"%.1f %@", second, secondUnitName];
			
			[timeFormat drawWithRect: NSMakeRect(dest.origin.x + 2, dest.origin.y + 1, dest.size.width - 4, dest.size.height - 2) options: 0 attributes: textAttributes];
			
			// Draw frame indicator
			NSString *frameFormat = [NSString stringWithFormat: @"%d", i + 1];
			NSRect frameFormatBounds = [frameFormat boundingRectWithSize: NSMakeSize(dest.size.width - 4, dest.size.height - 16) options: 0 attributes: textAttributes];
			
			[frameFormat drawWithRect: NSMakeRect(dest.origin.x + 2, dest.origin.y + dest.size.height - (1 + frameFormatBounds.size.height), dest.size.width - 4, dest.size.height - 2 * (1 + frameFormatBounds.size.height)) options: 0 attributes: textAttributes];
		}
	}
	
	// Draw the insertion mark
	if (insertionMark >= 0) {
		NSBezierPath *markPath = [NSBezierPath bezierPathWithRect: NSMakeRect(insertionMark * [self cellWidth] - [self cellBorderWidth], 0, 2 * [self cellBorderWidth], [self cellHeight])];
		
		[[NSColor blueColor] setFill];
		[markPath fill];
	}
}

#pragma mark First Responder
- (BOOL) acceptsFirstResponder
{
	return YES;
}

#pragma mark Mouse Events
- (void) mouseDown: (NSEvent *) e
{
	NSPoint p = [self convertPoint: [e locationInWindow] fromView: nil];
	NSUInteger clickedCell = (NSUInteger) floor(p.x / [self cellWidth]);
	
	// Save position and cell for later use in the mouseDragged: event
	mouseDownPosition = p;
	mouseDownCell = clickedCell;
	
	if (clickedCell < [self count]) {
		if ([e modifierFlags] & NSCommandKeyMask) {
			[self willChangeValueForKey: @"selectedIndexes"];
			if ([selectedIndexes containsIndex: clickedCell])
				[selectedIndexes removeIndex: clickedCell];
			else
				[selectedIndexes addIndex: clickedCell];
			
			[self didChangeValueForKey: @"selectedIndexes"];
			[self setNeedsDisplay: YES];
		} else {
			if (![selectedIndexes containsIndex: clickedCell]) {
				[self willChangeValueForKey: @"selectedIndexes"];
				[self setSelectedIndexes: [NSIndexSet indexSetWithIndex: clickedCell]];
				[self didChangeValueForKey: @"selectedIndexes"];
				[self setNeedsDisplay: YES];
			}
		}
	}
}

#pragma mark Key Events
- (void) keyDown: (NSEvent *) theEvent
{
	NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
	unichar
		key = [[theEvent characters] characterAtIndex: 0],
		snapshotKey = [ud integerForKey: FFUserDefaultSnapshotKey],
		nextPictureKey = [ud integerForKey: FFUserDefaultNextPictureKey],
		previousPictureKey = [ud integerForKey: FFUserDefaultPreviousPictureKey],
		firstPictureKey = [ud integerForKey: FFUserDefaultFirstPictureKey],
		lastPictureKey = [ud integerForKey: FFUserDefaultLastPictureKey];
	
	if (key == snapshotKey)
		[self requestSnapshot];
	else if (key == nextPictureKey)
		[self shiftSelectionToRight];
	else if (key == previousPictureKey)
		[self shiftSelectionToLeft];
	else if (key == firstPictureKey)
		[self shiftSelectionToBeginning];
	else if (key == lastPictureKey)
		[self shiftSelectionToEnd];
	else if (key == NSDeleteCharacter)
		[self remove: self];
}

#pragma mark Cell Dimensions
- (float) cellWidth
{
	return [self cellHeight] * 1.333;
}

- (float) cellInteriorWidth
{
	return [self cellWidth] - 2 * [self cellBorderWidth];
}

- (float) cellHeight
{
	return MAX([self frame].size.height, 0);
}

- (float) cellInteriorHeight
{
	return [self cellHeight] - 2 * [self cellBorderHeight];
}

- (float) cellBorderWidth
{
	return 2;
}

- (float) cellBorderHeight
{
	return 2;
}

#pragma mark Scrolling
- (void) scrollToImage: (NSUInteger) index
{
	NSAssert2(index >= 0 && index < [self count], @"Index out of range: %d (count = %d)", index, self.count);
	
	NSInteger cells = floor([[scrollView contentView] bounds].size.width / [self cellWidth]);
	NSInteger i = MAX(0, (int) index - cells / 2);
	
	[[scrollView contentView] scrollToPoint: NSMakePoint(i * [self cellWidth], 0)];
	[scrollView reflectScrolledClipView: [scrollView contentView]];
}

- (BOOL) imageVisible: (NSUInteger) index
{
	if (index >= self.count)
		return NO;
	
	NSRect visibleArea = [scrollView documentVisibleRect];
	float imageWidth = self.cellWidth;
	float imageLeft = index * imageWidth;
	
	return imageLeft >= visibleArea.origin.x && imageLeft + imageWidth <= visibleArea.origin.x + visibleArea.size.width;
}

#pragma mark Resize to fit Images
- (void) resizeToFitImages
{
	[self setFrameSize: NSMakeSize([self cellWidth] * ([self count] + 1), [self frame].size.height)];
	if ([self count] > 0)
		[self scrollToImage: [self count] - 1];
}

#pragma mark Adding and Removing Images
- (void) addObject: (CIImage *) image
{
	@throw [NSException exceptionWithName: @"NotImplemented" reason: nil userInfo: nil];
}
- (void) insertObject: (CIImage *) image atIndex: (NSUInteger) index
{
	@throw [NSException exceptionWithName: @"NotImplemented" reason: nil userInfo: nil];
}
- (void) insertObjects: (NSArray *) images atIndex: (NSUInteger) index
{
	@throw [NSException exceptionWithName: @"NotImplemented" reason: nil userInfo: nil];
}
- (void) insertObjects: (NSArray *) images atIndexes: (NSIndexSet *) indexes
{
	@throw [NSException exceptionWithName: @"NotImplemented" reason: nil userInfo: nil];
}
- (void) removeObjectsAtIndexes: (NSIndexSet *) indexes
{
	@throw [NSException exceptionWithName: @"NotImplemented" reason: nil userInfo: nil];
}


//- (void) addObject: (CIImage *) image
//{
//	NSAssert(image, @"Image is nil");
//	
//	[self willChangeValueForKey: @"images"];
//	
//	[FBReelNavigator adaptImageSizeToResolution: [NSArray arrayWithObject: image]];
//	
//	// Add the image
//	[self.reel addCellWithImage: image];
//	
//	// Set up undo information
//	[self.window.undoManager registerUndoWithTarget: self selector: @selector(removeObjectsAtIndexes:) object: [NSIndexSet indexSetWithIndex: [self count] - 1]];
//	
//	// When resizing, allow for some extra space for drag and drop
//	[self resizeToFitImages];
//	[self didChangeValueForKey: @"images"];
//	[self setNeedsDisplay: YES];
//}
//
//- (void) insertObject: (CIImage *) image atIndex: (NSUInteger) index
//{
//	[self willChangeValueForKey: @"images"];
//	
//	[FBReelNavigator adaptImageSizeToResolution: [NSArray arrayWithObject: image]];
//	
//	// Insert the image
//	[self.reel insertCellWithImage: image atIndex: index];
//	[selectedIndexes shiftIndexesStartingAtIndex: index by: 1];
//	
//	// Resize the frame to make it visible
//	[self resizeToFitImages];
//	
//	// Set up undo information
//	[self.window.undoManager registerUndoWithTarget: self selector: @selector(removeObjectsAtIndexes:) object: [NSIndexSet indexSetWithIndex: index]];
//	
//	[self didChangeValueForKey: @"images"];
//	[self setSelectedIndexes: [NSMutableIndexSet indexSetWithIndex: index]];
//	[self setNeedsDisplay: YES];
//}
//
//- (void) insertObjects: (NSArray *) newImages atIndex: (NSUInteger) index
//{
//	[self willChangeValueForKey: @"images"];
//	
//	[FBReelNavigator adaptImageSizeToResolution: newImages];
//	
//	// Insert the images
//	NSIndexSet *indexes = [NSIndexSet indexSetWithIndexesInRange: NSMakeRange(index, [newImages count])];
//
//	[self.reel insertCellsWithImages: newImages atIndexes: indexes];
//	
//	// Resize the frame to make them visible
//	[self resizeToFitImages];
//	
//	// Set up undo information
//	[self.window.undoManager registerUndoWithTarget: self selector: @selector(removeObjectsAtIndexes:) object: indexes];
//	
//	[self didChangeValueForKey: @"images"];
//	if ([self count] > 0)
//		[self setSelectedIndexes: [NSMutableIndexSet indexSetWithIndex: MAX(0, (NSInteger) (index + [newImages count]) - 1)]];
//	[self setNeedsDisplay: YES];
//}
//
//- (void) insertObjects: (NSArray *) newImages atIndexes: (NSIndexSet *) indexes
//{
//	[self willChangeValueForKey: @"images"];
//	[self willChangeValueForKey: @"selectedIndexes"];
//	
//	[FBReelNavigator adaptImageSizeToResolution: newImages];
//	
//	// Insert the images
//	[self.reel insertCellsWithImages: newImages atIndexes: indexes];
//	[selectedIndexes removeIndexesInRange: NSMakeRange(MIN(1, self.reel.count), MAX(0, (int) self.reel.count - 1))];
//	
//	// Resize the frame to make them visible
//	[self resizeToFitImages];
//	
//	// Set up undo information
//	[self.window.undoManager registerUndoWithTarget: self selector: @selector(removeObjectsAtIndexes:) object: indexes];
//	
//	[self didChangeValueForKey: @"images"];
//	[self didChangeValueForKey: @"selectedIndexes"];
//	[self setNeedsDisplay: YES];
//}
//
//- (void) removeObjectsAtIndexes: (NSIndexSet *) indexes
//{
//	[self willChangeValueForKey: @"images"];
//	
//	// Remove the images
//	NSInteger desiredIndex = (NSInteger) [selectedIndexes firstIndex] - 1;
//	NSArray *removedImages = [self.reel imagesAtIndexes: indexes];
//	
//	[self.reel removeImagesAtIndexes: indexes];
//	
//	// Resize the frame to make them visible
//	[self resizeToFitImages];	
//
//	// Set up undo information
//	[[self.window.undoManager prepareWithInvocationTarget: self] insertObjects: removedImages atIndexes: indexes];
//	
//	[self didChangeValueForKey: @"images"];
//	if (desiredIndex >= 0 && desiredIndex < [self count])
//		[self setSelectedIndexes: [NSMutableIndexSet indexSetWithIndex: desiredIndex]];
//	[self setNeedsDisplay: YES];
//}
//
#pragma mark Retrieving Images
//- (CIImage *) objectAtIndex: (NSUInteger) index
//{
//	return [self.reel imageAtIndex: index];
//}

- (NSArray *) imagesAtIndexes: (NSIndexSet *) indexes
{
	NSMutableArray *a = [NSMutableArray arrayWithCapacity: indexes.count];
	
	[indexes enumerateIndexesUsingBlock:
	 ^(NSUInteger i, BOOL *stop) {
		 [a addObject: [self.dataSource reelNavigator: self imageForCellAtIndex: i]];
	 }];
	
	return a;
}

#pragma mark IB Add, Remove
- (IBAction) add: (id) sender
{
	@throw [NSException exceptionWithName: @"NotImplemented" reason: nil userInfo: nil];
//	if (currentImage) {
//		NSUInteger insertionIndex = [self selectedIndex];
//		
//		if (insertionIndex == NSNotFound)
//			[self.reel addCellWithImage: self.currentImage];
//		else
//			[self.reel insertCellWithImage: self.currentImage atIndex: insertionIndex + 1];
//	}
}

- (IBAction) remove: (id) sender
{
	@throw [NSException exceptionWithName: @"NotImplemented" reason: nil userInfo: nil];
//	[self removeObjectsAtIndexes: selectedIndexes];
}

#pragma mark Selection Indices and Selected Images
- (void) setSelectedIndexes: (NSMutableIndexSet *) s
{
	[self willChangeValueForKey: @"selectedIndexes"];
	[selectedIndexes autorelease];
	selectedIndexes = [[NSMutableIndexSet alloc] initWithIndexSet: s];
	
	// Ensure visibility of the last selected image
	if ([selectedIndexes count] > 0 && ![self imageVisible: selectedIndexes.lastIndex])
		[self scrollToImage: selectedIndexes.lastIndex];
	
	[self didChangeValueForKey: @"selectedIndexes"];
	[self setNeedsDisplay: YES];
}

- (NSMutableIndexSet *) selectedIndexes
{
	return selectedIndexes;
}

- (NSUInteger) selectedIndex
{
	return [selectedIndexes lastIndex];
}

- (CIImage *) selectedImage
{
	NSUInteger selectedIndex = [self selectedIndex];
	
	// return selectedIndex == NSNotFound ? nil : [self.reel imageAtIndex: selectedIndex];
	return selectedIndex == NSNotFound ? nil : [self.dataSource reelNavigator: self imageForCellAtIndex: selectedIndex];
}

- (NSArray *) selectedImages
{
	return [self imagesAtIndexes: [self selectedIndexes]];
}

- (void) shiftSelectionToRight
{
	if ([self count] > 0) {
		if ([[self selectedIndexes] count] == 0)
			[self setSelectedIndexes: [NSMutableIndexSet indexSetWithIndex: 0]];
		else {
			NSUInteger lastIndex = [[self selectedIndexes] lastIndex];
			
			if (lastIndex < [self count] - 1 && lastIndex < NSUIntegerMax)
				[self setSelectedIndexes: [NSMutableIndexSet indexSetWithIndex: lastIndex + 1]];
		}
	}
}

- (void) shiftSelectionToLeft
{
	if ([self count] > 0) {
		if ([[self selectedIndexes] count] == 0)
			[self setSelectedIndexes: [NSMutableIndexSet indexSetWithIndex: [self count] - 1]];
		else {
			NSUInteger firstIndex = [[self selectedIndexes] firstIndex];
			
			if (firstIndex > 0)
				[self setSelectedIndexes: [NSMutableIndexSet indexSetWithIndex: firstIndex - 1]];
		}
	}
}

- (void) shiftSelectionToBeginning
{
	if ([self count] > 0)
		[self setSelectedIndexes: [NSMutableIndexSet indexSetWithIndex: 0]];
}

- (void) shiftSelectionToEnd
{
	if ([self count] > 0)
		[self setSelectedIndexes: [NSMutableIndexSet indexSetWithIndex: [self count] - 1]];
}

#pragma mark Frames per Second
- (NSUInteger) framesPerSecond
{
	return framesPerSecond;
}

- (void) setFramesPerSecond: (NSUInteger) fps
{
	framesPerSecond = fps;
	[self setNeedsDisplay: YES];
}

#pragma mark Cut, Copy, Paste and Delete Menu Items
+ (NSArray *) pasteTypes
{
	return [NSArray arrayWithObjects: FFImagesPboardType, NSFilenamesPboardType, NSURLPboardType, NSTIFFPboardType, nil];
}

- (BOOL) validateMenuItem: (NSMenuItem *) menuItem
{
	SEL action = [menuItem action];
	
	if (action == @selector(copy:) 
		|| action == @selector(cut:)
		|| action == @selector(delete:))
		return [selectedIndexes count] > 0;
	else if (action == @selector(paste:))
		return [[NSPasteboard generalPasteboard] availableTypeFromArray: [FBReelNavigator pasteTypes]] != nil;
	else
		return NO;
}

- (IBAction) copy: (id) sender
{
	NSArray *types = [NSArray arrayWithObjects: FFImagesPboardType, NSTIFFPboardType, nil];
	NSArray *a = [FBReelNavigator addTIFFRepresentations: [self selectedImages]];
	NSPasteboard *pb = [NSPasteboard generalPasteboard];
	NSBitmapImageRep *rep = [[NSBitmapImageRep alloc] initWithCIImage: self.selectedImage];
	
	[pb declareTypes: types owner: self];
	
	[pb setData: [NSArchiver archivedDataWithRootObject: a] forType: FFImagesPboardType];
	[pb setData: [rep TIFFRepresentation] forType: NSTIFFPboardType];
	
	[rep release];
}

- (IBAction) paste: (id) sender
{
	NSPasteboard *pb = [NSPasteboard generalPasteboard];
	NSString *bestType = [pb availableTypeFromArray: [FBReelNavigator pasteTypes]];
	NSUInteger index = [self selectedIndex] == NSNotFound ? 0 : [self selectedIndex];
	
	if (bestType != nil) {
		if ([bestType isEqualToString: FFImagesPboardType]) {
			NSArray *pastedImages = [NSUnarchiver unarchiveObjectWithData: [pb dataForType: FFImagesPboardType]];
			
			if (pastedImages != nil)
				[self insertObjects: pastedImages atIndex: index];
		} else if ([bestType isEqualToString: NSTIFFPboardType]) {
			CIImage *pastedImage = [[CIImage alloc] initWithData: [pb dataForType: NSTIFFPboardType]];
			
			if (pastedImage != nil) {
				[self insertObject: pastedImage atIndex: index];
				[pastedImage release];
			}
		} else if ([bestType isEqualToString: NSFilenamesPboardType]) {
			NSArray *filenames = [pb propertyListForType: NSFilenamesPboardType];
			NSMutableArray *pastedImages = [NSMutableArray arrayWithCapacity: [filenames count]];
			
			for (NSString *filename in filenames) {
				NSData *data = [NSData dataWithContentsOfFile: filename];
				CIImage *image = [[CIImage alloc] initWithData: data];
				
				if (image != nil) {
					[pastedImages addObject: image];
					[image release];
				}
			}
			
			[self insertObjects: pastedImages atIndex: index];
		} else if ([bestType isEqualToString: NSURLPboardType]) {
			NSURL *url = [NSURL URLFromPasteboard: pb];
			
			if (url != nil) {
				NSData *data = [NSData dataWithContentsOfURL: url];
				CIImage *pastedImage = [[CIImage alloc] initWithData: data];
				
				if (pastedImage != nil) {
					[self insertObject: pastedImage atIndex: index];
					[pastedImage release];
				}
			}
		}
	}
}

- (IBAction) delete: (id) sender
{
	[self remove: nil];
}

- (IBAction) cut: (id) sender
{
	[self copy: nil];
	[self delete: nil];
}

#pragma mark Drag source
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
	NSArray *selectedImages = [self selectedImages];
	NSMutableArray *names = [NSMutableArray arrayWithCapacity: [selectedImages count]];
	int i;
	
	for (i = 0; i < [selectedImages count]; ++i) {
		NSImage *image = [selectedImages objectAtIndex: i];
		NSString *filename = [NSString stringWithFormat: @"FF%05d.tiff", i + 1];
		NSURL *fileURL = [NSURL URLWithString: filename relativeToURL: dropDestination];
		
		[[image TIFFRepresentation] writeToURL: fileURL atomically: YES];
		[names addObject: filename];
	}
	
	return names;
}

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

#pragma mark Loading Images from Files
+ (NSArray *) loadImagesFromFiles: (NSArray *) filenames
{
	NSMutableArray *images = [NSMutableArray arrayWithCapacity: [filenames count]], *errors = [NSMutableArray array];
	NSEnumerator *e = [filenames objectEnumerator];
	NSString *filename;
	
	while ((filename = [e nextObject])) {
		CIImage *image = [CIImage imageWithData: [NSData dataWithContentsOfFile: filename]];
		
		if (image == nil)
			[errors addObject: filename];
		else
			[images addObject: image];
	}
	
	if ([errors count] > 0) {
		NSRunAlertPanel(@"Error loading image files", [errors componentsJoinedByString: @"\n"], @"OK", nil, nil);
	}
	
	return images;
}

#pragma mark Making Snapshots
- (void) requestSnapshot
{
	if ([delegate respondsToSelector: @selector(imageStripRequestsSnapshot:)])
		[delegate reelNavigatorRequestsSnapshot: self];
	else
		[self add: self];
}

#pragma mark Handling Resolution Issues
+ (void) adaptImageSizeToResolution: (NSArray *) images
{
	NSLog(@"TODO Figure out if -adaptImageSizeToResolution: is still needed - right now, it does nothing (still works with NSImage, so careful!)");
//	// Adapt image size to help QuickTime work correctly 
//	// with images of resolutions different from 72 dpi
//	for (NSImage *anImage in images) {
//		NSBitmapImageRep *r = (NSBitmapImageRep *) [anImage bestRepresentationForDevice: nil];
//		
//		if (([r pixelsWide] != (int) (double) round(((NSSize) [r size]).width))) {
//			[anImage setScalesWhenResized: YES];
//			[anImage setSize: NSMakeSize([r pixelsWide], [r pixelsHigh])];
//		}
//	}	
}

- (void) reelHasChanged
{
	[self resizeToFitImages];
	[self setNeedsDisplay: YES];	
}

@end
