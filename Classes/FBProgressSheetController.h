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

@property NSInteger maxValue, value;

- (void) beginSheetModalForWindow: (NSWindow *) window;

- (void) setThumbnail: (NSImage *) anImage;

@end
