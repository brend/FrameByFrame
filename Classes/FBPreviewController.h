//
//  FBPreviewController.h
//  FrameByFrame
//
//  Created by Philipp Brendel on 18.01.11.
//  Copyright 2011 BrendCorp. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FBReel.h"

@interface FBPreviewController : NSObject 
{
	IBOutlet NSPanel *previewPanel;
	IBOutlet NSImageView *imageView;
	IBOutlet NSButton *playButton;
	
	FBReel *reel;
	NSUInteger startFrame, frameIndex, framesPerSecond;
	NSTimer *timer;
}

#pragma mark -
#pragma mark Playing Previews
@property (readonly) BOOL isPreviewPlaying;
@property NSUInteger framesPerSecond;

- (void) setupPreviewWithReel: (FBReel *) reel
			 fromImageAtIndex: (NSUInteger) startIndex
			  framesPerSecond: (NSUInteger) fps;
- (void) stopPreview;
- (void) togglePreview;
- (void) rewindPreview;

#pragma mark Interface Builder Actions
- (IBAction) togglePreview: (id) sender;
- (IBAction) rewindPreview: (id) sender;

@end
