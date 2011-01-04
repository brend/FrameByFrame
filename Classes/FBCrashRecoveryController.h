//
//  FBCrashRecoveryController.h
//  FrameByFrame
//
//  Created by Philipp Brendel on 02.01.11.
//  Copyright 2011 BrendCorp. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface FBCrashRecoveryController : NSObject <NSTableViewDataSource>
{
	IBOutlet NSWindow *window;
	IBOutlet NSTableView *documentList;
	
	NSArray *temporaryDocumentPaths;
}

#pragma mark -
#pragma mark Discovering Unsaved Documents
@property (copy) NSArray *temporaryDocumentPaths;
@property (readonly) BOOL unsavedDocumentsExist;

#pragma mark -
#pragma mark Deleting Unsaved Documents
- (void) deleteTemporaryDocuments;

#pragma mark -
#pragma mark Table View Data Source
- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView;

#pragma mark -
#pragma Interface Builder Actions
- (IBAction) open: (id) sender;
- (IBAction) deleteAll: (id) sender;

@end
