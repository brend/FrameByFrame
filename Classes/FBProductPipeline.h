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

- (id) initWithArtisticFilter: (CIFilter *) aFilter;

@property (copy) NSAffineTransform *transform;

- (CIImage *) pipeImage: (CIImage *) inputImage;

@end
