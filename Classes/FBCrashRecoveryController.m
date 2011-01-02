//
//  FBCrashRecoveryController.m
//  FrameByFrame
//
//  Created by Philipp Brendel on 02.01.11.
//  Copyright 2011 BrendCorp. All rights reserved.
//

#import "FBCrashRecoveryController.h"


@implementation FBCrashRecoveryController
@synthesize temporaryDocumentPaths;

- (id) init
{
	self = [super init];
	if (self != nil) {
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
				[temporaryDocuments addObject: path];
			}
		}
		
		self.temporaryDocumentPaths = temporaryDocuments;		
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
	} else
		return nil;
}

#pragma mark -
#pragma Interface Builder Actions
- (IBAction) open: (id) sender
{
	NSLog(@"TODO: Implement");
}

- (IBAction) deleteAll: (id) sender
{
	NSLog(@"TODO: Implement");
}

@end
