//
//  NSDictionary(FBAdditions).m
//  FrameByFrame
//
//  Created by Philipp Brendel on 27.11.10.
//  Copyright 2010 BrendCorp. All rights reserved.
//

#import "NSDictionary(FBAdditions).h"


@implementation NSDictionary (FBAdditions)

- (NSSize) resolution
{
	return [[self objectForKey: FBResolutionSettingName] sizeValue];
}

@end
