//
//  NSDictionary(FBAdditions).h
//  FrameByFrame
//
//  Created by Philipp Brendel on 27.11.10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSDictionary (FBAdditions)

#pragma mark -
#pragma mark Movie Settings
+ (NSDictionary *) defaultMovieSettings;
- (NSInteger) horizontalResolution;
- (NSInteger) verticalResolution;
- (NSInteger) framesPerSecond;

@end
