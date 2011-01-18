//
//  FBPreviewController.h
//  FrameByFrame
//
//  Created by Philipp Brendel on 18.01.11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FBReel.h"

@interface FBPreviewController : NSObject 
{
	IBOutlet NSPanel *previewPanel;
	IBOutlet NSImageView *imageView;
	
	FBReel *reel;
	NSUInteger frameIndex;
	NSTimer *timer;
}

#pragma mark -
#pragma mark Playing Previews
- (void) startPreviewWithReel: (FBReel *) reel
			 fromImageAtIndex: (NSUInteger) startIndex
			  framesPerSecond: (NSUInteger) fps;

@end
