//
//  NSDictionary(FBAdditions).m
//  FrameByFrame
//
//  Created by Philipp Brendel on 27.11.10.
//  Copyright 2010 BrendCorp. All rights reserved.
//

#import "NSDictionary(FBAdditions).h"


@implementation NSDictionary (FBAdditions)

- (NSInteger) horizontalResolution
{
	return [[self objectForKey: FBHorizontalResolutionSettingName] integerValue];
}

- (NSInteger) verticalResolution
{
	return [[self objectForKey: FBVerticalResolutionSettingName] integerValue];
}

@end
