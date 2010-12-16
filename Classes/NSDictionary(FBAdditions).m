//
//  NSDictionary(FBAdditions).m
//  FrameByFrame
//
//  Created by Philipp Brendel on 27.11.10.
//  Copyright 2010 BrendCorp. All rights reserved.
//

#import "NSDictionary(FBAdditions).h"


@implementation NSDictionary (FBAdditions)

#pragma mark -
#pragma mark Movie Settings
+ (NSDictionary *) defaultMovieSettings
{
	return [NSDictionary dictionaryWithObjectsAndKeys:
			[NSNumber numberWithInteger: 640], FBHorizontalResolutionSettingName,
			[NSNumber numberWithInteger: 480], FBVerticalResolutionSettingName,
			[NSNumber numberWithInteger: 15], FBFramesPerSecondAttributeName,
			nil];
}

- (NSInteger) horizontalResolution
{
	return [[self objectForKey: FBHorizontalResolutionSettingName] integerValue];
}

- (NSInteger) verticalResolution
{
	return [[self objectForKey: FBVerticalResolutionSettingName] integerValue];
}

- (NSInteger) framesPerSecond
{
	return [[self objectForKey: FBFramesPerSecondAttributeName] integerValue];
}

@end
