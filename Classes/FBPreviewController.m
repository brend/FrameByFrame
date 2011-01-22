//
//  FBPreviewController.m
//  FrameByFrame
//
//  Created by Philipp Brendel on 18.01.11.
//  Copyright 2011 BrendCorp. All rights reserved.
//

#import "FBPreviewController.h"


@implementation FBPreviewController
@synthesize timer;

- (id)init {
    if ((self = [super init])) {
        // Initialization code here.
    }
    
    return self;
}

- (void)dealloc 
{
    [self.timer invalidate];
	self.timer = nil;
    
    [super dealloc];
}

#pragma mark -
#pragma mark Playing Previews
- (BOOL) isPreviewPlaying
{
	return self.timer != nil;
}

- (void) startPreviewWithReel: (FBReel *) aReel
			 fromImageAtIndex: (NSUInteger) startIndex
			  framesPerSecond: (NSUInteger) fps
{
	[self stopPreview];
	
	reel = aReel;
	frameIndex = startIndex;
	self.timer = [NSTimer scheduledTimerWithTimeInterval: 1.0 / (float) fps target: self selector: @selector(nextFrame:) userInfo: nil repeats: YES];
}

- (void) nextFrame: (id) sender
{
	if (frameIndex < reel.count) {
		// NOTE Don't query cells, but images
		// This way, the reel can release unused images
		NSBitmapImageRep *rep = [[NSBitmapImageRep alloc] initWithCIImage: [reel imageAtIndex: frameIndex]];
		NSImage *image = [[NSImage alloc] init];
		
		[image addRepresentation: rep];
		[imageView setImage: image];
		[image release];
		[rep release];
		
		++frameIndex;
	} else
		[self stopPreview];
}

- (void) stopPreview
{
	[self.timer invalidate];
	self.timer = nil;
}

@end
