//
//  FBCrashRecoveryController.m
//  FrameByFrame
//
//  Created by Philipp Brendel on 02.01.11.
//  Copyright 2011 BrendCorp. All rights reserved.
//

#import "FBCrashRecoveryController.h"

#import "FBDocument.h"

#pragma mark -
#pragma mark FBCrashRecoveryController Private Interface
@interface FBCrashRecoveryController ()
@property (copy) NSArray *temporaryDocumentPaths;
- (void) loadTemporaryDocuments;
@end

#pragma mark -
#pragma mark FBCrashRecoveryController Implementation
@implementation FBCrashRecoveryController
@synthesize temporaryDocumentPaths;

- (id) init
{
	self = [super init];
	if (self != nil) {
		[self loadTemporaryDocuments];
	}
	return self;
}

- (void) dealloc
{
	self.temporaryDocumentPaths = nil;
	[super dealloc];
}

- (BOOL) unsavedDocumentsExist
{
	return self.temporaryDocumentPaths.count > 0;
}

- (void) loadTemporaryDocuments
{
	NSMutableArray *temporaryDocuments = [NSMutableArray array];
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSString *tempDirectory = @"/tmp";
	BOOL isDirectory = NO;
	
	for (NSString *filename in [fileManager contentsOfDirectoryAtPath: tempDirectory error: NULL]) {
		NSString *path = [tempDirectory stringByAppendingPathComponent: filename];
		
		if ([filename hasPrefix: @"fbf."] 
			&& [fileManager fileExistsAtPath: path isDirectory: &isDirectory]
			&& isDirectory)
		{
			NSArray *documentItems = [fileManager contentsOfDirectoryAtPath: path error: NULL];
			
			if (documentItems.count > 0)
				[temporaryDocuments addObject: path];
		}
	}
	
	self.temporaryDocumentPaths = temporaryDocuments;
}

#pragma mark -
#pragma mark Table View Data Source
- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
	return self.temporaryDocumentPaths.count;
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
	NSString *identifier = aTableColumn.identifier;
	
	if ([identifier isEqualToString: @"PathColumn"]) {
		return [self.temporaryDocumentPaths objectAtIndex: rowIndex];
	} else if ([identifier isEqualToString: @"ItemsColumn"]) {
		NSString *path = [self.temporaryDocumentPaths objectAtIndex: rowIndex];
		NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath: path error: NULL];
		
		return [NSNumber numberWithUnsignedInteger: files.count];
	} else if ([identifier isEqualToString: @"DateColumn"]) {
		NSString *path = [self.temporaryDocumentPaths objectAtIndex: rowIndex];
		NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath: path error: NULL];
		
		return [attributes fileModificationDate];
	} else if ([identifier isEqualToString: @"ThumbnailColumn"]) {
		NSURL *url = [NSURL fileURLWithPath: [self.temporaryDocumentPaths objectAtIndex: rowIndex]];
		
		return [self thumbnailForDocumentAtURL: url];
	} else
		return nil;
}

#pragma mark -
#pragma mark Table View Delegate
- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row
{
	return 64;
}

#pragma mark -
#pragma mark Deleting Unsaved Documents
- (void) deleteTemporaryDocuments
{
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSError *error = nil;
	
	for (NSString *path in self.temporaryDocumentPaths) {
		if (![fileManager removeItemAtPath: path error: &error]) {
			NSLog(@"Cannot delete file at path %@ due to error: %@", path, error);
		}
	}
	
//	self.temporaryDocumentPaths = [NSArray array];
}

#pragma mark -
#pragma Interface Builder Actions
- (IBAction) open: (id) sender
{
	NSInteger selectedRow = documentList.selectedRow;
	
	if (selectedRow >= 0) {
		NSURL *source = [NSURL fileURLWithPath: [self.temporaryDocumentPaths objectAtIndex: selectedRow]];
		
		NSSavePanel *savePanel = [NSSavePanel savePanel];
		
		savePanel.allowedFileTypes = [NSArray arrayWithObject: @"ffm"];
		
		if ([savePanel runModal] == NSOKButton) {
			NSURL *destination = savePanel.URL;
			NSError *error = nil;
			
			if ([[NSFileManager defaultManager] copyItemAtURL: source toURL: destination error: &error]) {
				FBDocument *document = [[FBDocument alloc] initWithContentsOfURL: destination ofType: @"ffm" error: &error];
				
				if (document) {
					[document makeWindowControllers];
					[document showWindows];
					[document release];
				} else {
					NSRunAlertPanel(@"An error has occurred", [error description], @"OK", nil, nil);
				}
			} else {
				NSRunAlertPanel(@"An error has occurred", [error description], @"OK", nil, nil);
			}
		}
	}
}

- (IBAction) deleteAll: (id) sender
{
	NSString *message = @"Do you really want to delete all remaining unsaved documents? This process can't be reversed.";
	
	NSBeginAlertSheet(@"Delete unsaved documents", @"OK", @"Cancel", nil, window, self, @selector(sheetDidEnd:returnCode:contextInfo:), nil, nil, message);
}

#pragma mark -
#pragma mark Sheet Delegate
- (void) sheetDidEnd: (NSWindow *) sheet
		  returnCode: (int) returnCode
		 contextInfo: (void *) context
{
	if (returnCode == 1) {
		[self deleteTemporaryDocuments];
		[self loadTemporaryDocuments];
		[documentList reloadData];
	}
}

#pragma mark -
#pragma mark Thumbnails
- (NSImage *) thumbnailForDocumentAtURL: (NSURL *) url
{
	NSFileManager *fileManager = [NSFileManager defaultManager];
	BOOL isDirectory = NO;
	
	if ([fileManager fileExistsAtPath: url.path isDirectory: &isDirectory] && isDirectory) {
		NSArray *files = [fileManager contentsOfDirectoryAtPath: url.path error: NULL];
		NSString *imageFile = nil;
		
		if (files == nil)
			return nil;
		
		for (NSString *file in files) {
			if ([file hasPrefix: @"."] || [file isEqualToString: @"QuickLook"] || [file isEqualToString: @"reel"] || [file isEqualToString: @"movieSettings"])
				continue;
			
			imageFile = file;
			break;
		}
		
		if (imageFile) {
			NSImage *image = [[NSImage alloc] initWithContentsOfFile: [url.path stringByAppendingPathComponent: imageFile]];
			
			[image setSize: NSMakeSize(48, 48)];
			
			return [image autorelease];
		} else
			return nil;
	} else
		return nil;
}

@end
