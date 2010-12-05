//
//  FBProgressSheetController.h
//  FrameByFrame
//
//  Created by Philipp Brendel on 24.11.10.
//  Copyright 2010 BrendCorp. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface FBProgressSheetController : NSObject
{
	IBOutlet NSWindow *progressSheet;
	IBOutlet NSProgressIndicator *progressBar;
	IBOutlet NSImageView *thumbnailView;
}

#pragma mark -
#pragma mark Showing the Progress Sheet
- (void) beginSheetModalForWindow: (NSWindow *) window
					indeterminate: (BOOL) indeterminate;

#pragma mark -
#pragma mark Hiding the Progress Sheet
- (void) endSheet;

#pragma mark -
#pragma mark Changing the Sheet's Appearance
@property NSInteger maxValue, value;
@property (setter = setIndeterminate:) BOOL isIndeterminate;
- (void) setThumbnail: (NSImage *) anImage;

@end
