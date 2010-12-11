//
//  NSValue(FBAdditions).m
//  FrameByFrame
//
//  Created by Philipp Brendel on 11.12.10.
//  Copyright 2010 BrendCorp. All rights reserved.
//

#import "NSValue(FBAdditions).h"


@implementation NSValue (FBAdditions)

- (NSString *) resolutionDescription
{
	NSSize size = [self sizeValue];
	
	return [NSString stringWithFormat: @"%dx%d", (NSInteger) size.width, (NSInteger) size.height];
}

@end
