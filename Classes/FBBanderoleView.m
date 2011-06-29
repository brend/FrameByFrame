//
//  FBBanderoleView.m
//  FrameByFrame
//
//  Created by Philipp Brendel on 12.03.11.
//  Copyright 2011 BrendCorp. All rights reserved.
//

#import "FBBanderoleView.h"


@implementation FBBanderoleView

- (id) initWithFrame: (NSRect) frame
{
    self = [super initWithFrame:frame];
    if (self) {
		patternImage = [[NSImage imageNamed: @"ButtonBanderole.png"] retain];
    }
    
    return self;
}

- (void) dealloc
{
	[patternImage release];
	patternImage = nil;
	
    [super dealloc];
}

- (void) drawRect: (NSRect) dirtyRect
{
	NSSize patternSize = patternImage.size;
	NSInteger repetitions = ceilf(self.frame.size.width / patternSize.width);
	NSRect
		sourceRect = (NSRect) { .origin = NSZeroPoint, .size = patternSize },
		destRect = (NSRect) { .origin = NSZeroPoint, .size = patternSize };
	
	while (repetitions--) {
		[patternImage drawInRect: destRect fromRect: sourceRect operation: NSCompositeSourceOver fraction: 1];
		
		destRect.origin.x += patternSize.width;
	}
}

@end
