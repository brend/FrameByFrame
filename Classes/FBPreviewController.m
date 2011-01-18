//
//  FBPreviewController.m
//  FrameByFrame
//
//  Created by Philipp Brendel on 18.01.11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "FBPreviewController.h"


@implementation FBPreviewController

- (id)init {
    if ((self = [super init])) {
        // Initialization code here.
    }
    
    return self;
}

- (void)dealloc {
    // Clean-up code here.
    
    [super dealloc];
}

#pragma mark -
#pragma mark Playing Previews
- (void) startPreviewFromImageAtIndex: (NSUInteger) startIndex
					  framesPerSecond: (NSUInteger) fps
{
	NSLog(@"I'ma playin' mah preview");
}

@end
