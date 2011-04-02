//
//  FBProgressSheetController.m
//  FrameByFrame
//
//  Created by Philipp Brendel on 24.11.10.
//  Copyright 2010 BrendCorp. All rights reserved.
//

#import "FBProgressSheetController.h"


@implementation FBProgressSheetController

#pragma mark -
#pragma mark Changing the Sheet's Appearance
- (NSInteger) maxValue
{
	return (NSInteger) [progressBar maxValue];
}

- (void) setMaxValue: (NSInteger) m
{
	[progressBar setMaxValue: m];
}

- (NSInteger) value
{
	return (NSInteger) [progressBar doubleValue];
}

- (void) setValue: (NSInteger) v
{
	[progressBar setDoubleValue: v];
}

- (void) setThumbnail: (NSImage *) anImage
{
	thumbnailView.image = anImage;
}

- (BOOL) isIndeterminate
{
	return progressBar.isIndeterminate;
}

- (void) setIndeterminate: (BOOL) flag
{
	[progressBar setIndeterminate: flag];
}

#pragma mark -
#pragma mark Showing the Progress Sheet
- (void) beginSheetModalForWindow: (NSWindow *) window
					indeterminate: (BOOL) indeterminate
{
	[progressBar setIndeterminate: indeterminate];
	[self setThumbnail: indeterminate ? [NSImage imageNamed: @"Button-OpenDocument"] : nil];
	
	[NSApp beginSheet: progressSheet modalForWindow: window modalDelegate: nil didEndSelector: nil contextInfo: nil];
	
	if (indeterminate)
		[progressBar startAnimation: self];
}

- (void) beginDeterminateSheetModalForWindow: (NSWindow *) window
{
	[self beginSheetModalForWindow: window indeterminate: NO];
}

- (void) beginIndeterminateSheetModalForWindow: (NSWindow *) window
{
	[self beginSheetModalForWindow: window indeterminate: YES];
}

#pragma mark -
#pragma mark Hiding the Progress Sheet
- (void) endSheet
{
	[NSApp endSheet: progressSheet];
	[progressSheet orderOut: self];
}

@end
