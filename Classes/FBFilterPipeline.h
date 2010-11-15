//
//  FBFilterPipeline.h
//  FrameByFrame
//
//  Created by Philipp Brendel on 15.11.10.
//  Copyright 2010 BrendCorp. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

@interface FBFilterPipeline : NSObject
{
	CIFilter *filter;
	NSArray *parameterNames;
}

#pragma mark -
#pragma mark Initialization
- (id) initWithSkinCount: (NSInteger) skinCount;
+ (id) filterPipelineWithSkinCount: (NSInteger) skinCount;

#pragma mark -
#pragma mark Retrieving Pipeline Information
@property (readonly) NSUInteger skinCount;
@property (readonly, copy) NSArray *parameterNames;

#pragma mark -
#pragma mark Piping Images Through the Pipeline
- (CIImage *) pipeVideoImage: (CIImage *) videoImage
				  skinImages: (NSArray *) skinImages;

#pragma mark -
#pragma mark Retrieving the Underlying Core Image Filter
@property (readonly, retain) CIFilter *filter;

@end
