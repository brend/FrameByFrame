//
//  FBMiscConstants.h
//  FrameByFrame
//
//  Created by Philipp Brendel on 01.01.11.
//  Copyright 2011 BrendCorp. All rights reserved.
//

#import <Cocoa/Cocoa.h>

extern char *FBTemporaryFilenamePattern;

// The values of FBMirrorImageMode correspond to the
// indexes of the "mirror image" segmented control
typedef enum 
{
	FBMirrorImageNone		= 0,
	FBMirrorImageHorizontal = 1,
	FBMirrorImageVertical	= 2, 
	FBMirrorImageBoth		= 3
} FBMirrorImageMode;
