//
//  FBPreviewController.h
//  FrameByFrame
//
//  Created by Philipp Brendel on 18.01.11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface FBPreviewController : NSObject 
{
	IBOutlet NSPanel *previewPanel;
}

#pragma mark -
#pragma mark Playing Previews
- (void) startPreviewFromImageAtIndex: (NSUInteger) startIndex
					  framesPerSecond: (NSUInteger) fps;

@end
