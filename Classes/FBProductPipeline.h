//
//  FBProductPipeline.h
//  FrameByFrame
//
//  Created by Philipp Brendel on 16.02.11.
//  Copyright 2011 BrendCorp. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface FBProductPipeline : NSObject 
{
@private
    CIFilter *filter;
	NSAffineTransform *transform;
}

#pragma mark -
#pragma mark Initialization
- (id) initWithArtisticFilter: (CIFilter *) aFilter;

#pragma mark -
#pragma mark Filter Properties
@property (copy) NSAffineTransform *transform;

#pragma mark -
#pragma mark Sending Images Through the Pipeline
- (CIImage *) pipeImage: (CIImage *) inputImage;

@end
