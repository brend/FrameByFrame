//
//  FBProgressSheetController.m
//  FrameByFrame
//
//  Created by Philipp Brendel on 24.11.10.
//  Copyright 2010 BrendCorp. All rights reserved.
//

#import "FBProgressSheetController.h"


@implementation FBProgressSheetController
@dynamic maxValue, value;

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

- (void) beginSheetModalForWindow: (NSWindow *) window
{
	[NSApp beginSheet: progressSheet modalForWindow: window modalDelegate: nil didEndSelector: nil contextInfo: nil];
}

@end