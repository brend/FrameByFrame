//
//  FBDocument(DragDrop).m
//  FrameByFrame
//
//  Created by Philipp Brendel on 19.12.10.
//  Copyright 2010 BrendCorp. All rights reserved.
//

#import "FBDocument(DragDrop).h"


@implementation FBDocument (DragDrop)

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
	
	
	NSArray *sourceURLs = [self urlsForImagesAtIndexes: self.reelNavigator.selectedIndexes];
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

#pragma mark -
#pragma mark Drag target
- (NSDragOperation) draggingEntered:(id<NSDraggingInfo>)sender
{
	return [self.reelNavigator draggingEntered: sender];
}

- (NSDragOperation) draggingUpdated:(id<NSDraggingInfo>)sender
{
	return [self.reelNavigator draggingUpdated: sender];
}

- (void) draggingExited: (id<NSDraggingInfo>) sender
{
	return [self.reelNavigator draggingExited: sender];
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
	
	// TODO: Navigator
	NSPoint p = [self.reelNavigator convertPoint: [sender draggingLocation] fromView: nil];
	NSUInteger cell = [self.reelNavigator cellAtPoint: p];
	
	[self.reelNavigator setInsertionMark: -1];
	
	if ([type isEqualToString: NSFilenamesPboardType]) {
		NSArray *filenames = [pb propertyListForType: NSFilenamesPboardType];
		NSArray *importedImages = [FBReelNavigator loadImagesFromFiles: filenames];
		
		for (NSInteger i = 0; i < importedImages.count; ++i) {
			CIImage *ciImage = [importedImages objectAtIndex: importedImages.count - (i + 1)];
			
			[self.reel insertCellWithImage: ciImage atIndex: cell];
		}
	} else if ([type isEqualToString: NSTIFFPboardType]) {
		// TODO: Is this not implemented?
	} else
		return NO;
	
	return YES;
}

/*
 - (void) concludeDragOperation: (id < NSDraggingInfo >) sender
 {
 }
 */

@end
