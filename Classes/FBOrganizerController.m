//
//  FBOrganizerController.m
//  FrameByFrame
//
//  Created by Philipp Brendel on 22.01.11.
//  Copyright 2011 BrendCorp. All rights reserved.
//

#import "FBOrganizerController.h"
#import "FBDocument.h"

#pragma mark -
#pragma mark Private FBOrganizerController Interface
@interface FBOrganizerController ()
- (void) loadRecentDocuments;
@end

#pragma mark -
#pragma mark FBOrganizerController Implementation
@implementation FBOrganizerController

- (id)init 
{
    if ((self = [super init])) {
		// Make default resolutions available
		self.availableResolutions = 
		[NSArray arrayWithObjects:
		 [NSValue valueWithSize: NSMakeSize(640, 480)],
		 [NSValue valueWithSize: NSMakeSize(800, 450)],
		 [NSValue valueWithSize: NSMakeSize(800, 600)],
		 nil];
		if (self.availableResolutions.count > 0)
			self.selectedPredefinedResolution = [self.availableResolutions objectAtIndex: 0];
		self.customHorizontalResolution = 640;
		self.customVerticalResolution = 480;
		
		// Find recently used documents
		[self loadRecentDocuments];
    }
    
    return self;
}

- (void) windowDidBecomeKey: (NSNotification *) n
{
	[self loadRecentDocuments];
	[recentDocumentsView reloadData];
}

- (void) awakeFromNib
{
	// Register for notification on change of key window
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(windowDidBecomeKey:) name: NSWindowDidBecomeKeyNotification object: window];
	
	// Hook up the double-tap, er, click
	[recentDocumentsView setDoubleAction: @selector(openRecent:)];
	
	// Pre-select first toolbar item (should be "New Movie")
	if (organizerBar.items.count) {
		[organizerBar setSelectedItemIdentifier: [[organizerBar.items objectAtIndex: 0] itemIdentifier]];
		[self toolbarNewDocument: organizerBar];
	}
}

- (void)dealloc 
{
	[[NSNotificationCenter defaultCenter] removeObserver: self name: NSWindowDidBecomeKeyNotification object: window];
	
//	delegate = nil;
	[availableResolutions release];
	availableResolutions = nil;
	
	[recentDocuments release];
	recentDocuments = nil;
	
	[recentDocumentsSelection release];
	recentDocumentsSelection = nil;
    
    [super dealloc];
}

#pragma mark -
#pragma mark Creating a New Movie
@synthesize selectedPredefinedResolution, availableResolutions;
@synthesize useCustomResolution, customHorizontalResolution, customVerticalResolution;

- (BOOL) settingsOK
{
	NSSize resolution = NSZeroSize;
	
	if (self.useCustomResolution) {
		resolution = NSMakeSize(self.customHorizontalResolution, self.customVerticalResolution);
	} else {
		resolution = [self.selectedPredefinedResolution sizeValue];
	}
	
	return resolution.width > 0 && resolution.height > 0;
}

- (NSDictionary *) composeMovieSettings
{
	if (![self settingsOK])
		return nil;
	
	NSSize resolution = NSZeroSize;
	
	if (self.useCustomResolution) {
		resolution = NSMakeSize(self.customHorizontalResolution, self.customVerticalResolution);
	} else {
		resolution = [self.selectedPredefinedResolution sizeValue];
	}	
	
	NSAssert(resolution.width > 0 && resolution.height > 0, @"Invalid resolution");
	
	NSMutableDictionary *settings = [NSMutableDictionary dictionaryWithDictionary: [NSDictionary defaultMovieSettings]];
	NSDictionary *localSettings =
	[NSDictionary dictionaryWithObjectsAndKeys:
	 [NSNumber numberWithInteger: resolution.width], FBHorizontalResolutionSettingName,
	 [NSNumber numberWithInteger: resolution.height], FBVerticalResolutionSettingName,
	 nil];
	
	[settings addEntriesFromDictionary: localSettings];
	
	return settings;
}

- (IBAction) newMovie: (id) sender
{
	if ([self settingsOK]) {
		NSDictionary *movieSettings = [self composeMovieSettings];
        NSDocumentController *controller = [NSDocumentController sharedDocumentController];
		NSError *error = nil;
		FBDocument *document = [controller makeUntitledDocumentOfType: @"FrameByFrame Movie" error: &error];
		
		if (document) {
			// TODO: Do I *really* have to do this manually?
			[document makeWindowControllers];
			[document showWindows];
			
			document.movieSettings = [NSMutableDictionary dictionaryWithDictionary: movieSettings];
			
			// Close window when done
			[window close];
		} else
			NSLog(@"Error creating untitled document: %@", error);
	} else {
		NSRunAlertPanel(@"Bad resolution", @"Please select a resolution that is suitable to your camera", @"OK", nil, nil);
	}
}

#pragma mark -
#pragma mark Opening a Recently Used Movie
- (IBAction) openRecent: (id) sender
{
	if (self.recentDocumentsSelection.count > 0) {
		NSURL *documentURL = [self.recentDocuments objectAtIndex: self.recentDocumentsSelection.firstIndex];
		
		if (![[NSFileManager defaultManager] fileExistsAtPath: documentURL.path]) {
			NSString *message = [NSString stringWithFormat: @"The movie %@ does no longer exist.", documentURL.path];
			
			NSRunAlertPanel(@"Movie doesn't exist", message, @"OK", nil, nil);
			
			return;
		}
		
		NSError *error = nil;
		NSDocumentController *controller = [NSDocumentController sharedDocumentController];
		NSDocument *document = 
			[controller openDocumentWithContentsOfURL: documentURL
											  display: YES
												error: &error];
		
		if (document) {
			// Close window when done
			[window close];
		} else
			NSLog(@"Couldn't open movie at %@ because of error: %@", documentURL, error);
		
	}
}

- (void) loadRecentDocuments
{
	self.recentDocuments = [[NSDocumentController sharedDocumentController] recentDocumentURLs];
}

@synthesize recentDocuments, recentDocumentsSelection;


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

#pragma mark -
#pragma mark Handling Unsaved Movies
- (IBAction) openUnsaved: (id) sender
{
	[crashRecovery open: self];
	
	// Close window when done
	[window close];
}

- (IBAction) deleteUnsaved: (id) sender
{
	[crashRecovery deleteAll: self];
}

#pragma mark -
#pragma mark Toolbar Actions
- (IBAction) toolbarNewDocument: (id) sender
{
	[organizerTabs selectTabViewItemWithIdentifier: @"NewDocument"];
	[self setFrameSize: NSMakeSize(480, 240) resizable: NO];
}

- (IBAction) toolbarOpenDocument: (id) sender
{
	[organizerTabs selectTabViewItemWithIdentifier: @"OpenDocument"];
	[self setFrameSize: NSMakeSize(480, 408) resizable: YES];
}

- (IBAction) toolbarRecoverDocument: (id) sender
{
	[organizerTabs selectTabViewItemWithIdentifier: @"RecoverDocument"];
	[self setFrameSize: NSMakeSize(480, 408) resizable: YES];
}

#pragma mark -
#pragma mark Resizing the Window
- (void) setFrameSize: (NSSize) newSize resizable: (BOOL) resize
{
	NSRect oldFrame = window.frame;
	NSRect newFrame = NSMakeRect(oldFrame.origin.x, oldFrame.origin.y + (oldFrame.size.height - newSize.height), newSize.width, newSize.height);
	
	[window setFrame: newFrame
			 display: YES 
			 animate: YES];
	[window setShowsResizeIndicator: resize];
}

#pragma mark -
#pragma mark Window Delegate
- (NSSize)windowWillResize:(NSWindow *)sender toSize:(NSSize)frameSize
{
	return sender.showsResizeIndicator ? frameSize : sender.frame.size;
}

#pragma mark -
#pragma mark Table View Data Source
- (NSInteger) numberOfRowsInTableView: (NSTableView *) tableView
{
	return tableView == recentDocumentsView ? self.recentDocuments.count : 0;
}

- (id) tableView: (NSTableView *) tableView objectValueForTableColumn: (NSTableColumn *) tableColumn row: (NSInteger) row
{
	if (tableView == recentDocumentsView) {
		if ([tableColumn.identifier isEqualToString: @"OpenPathColumn"]) {
			NSURL *url = [self.recentDocuments objectAtIndex: row];
			NSString *file = [[url lastPathComponent] stringByDeletingPathExtension];
			
			return [NSString stringWithFormat: @"%@\n%@", file, url.path];
		} else if ([tableColumn.identifier isEqualToString: @"OpenThumbnailColumn"]) {
			return [self thumbnailForDocumentAtURL: [self.recentDocuments objectAtIndex: row]];
		} else
			return nil;
	} else
		return nil;
}

#pragma mark -
#pragma mark Table View Delegate
- (CGFloat) tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row
{
	return 64;
}

#pragma mark -
#pragma mark Auxiliary Actions
- (IBAction) noOp: (id) sender
{
	// No action.
	// This method's only purpose is to set the target 
	// for the table view's doubleAction
}

@end
