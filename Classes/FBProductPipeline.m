//
//  FBProductPipeline.m
//  FrameByFrame
//
//  Created by Philipp Brendel on 16.02.11.
//  Copyright 2011 BrendCorp. All rights reserved.
//

#import "FBProductPipeline.h"
#import <QuartzCore/QuartzCore.h>

@interface FBProductPipeline ()
@property (retain) CIFilter *filter;
- (void) createFilter;
@end

@implementation FBProductPipeline

- (id)init
{
    self = [super init];
    if (self) {
		self.transform = [NSAffineTransform transform];
		
        [self createFilter];
    }
    
    return self;
}

- (void)dealloc
{
	self.transform = nil;
	self.filter = nil;
    [super dealloc];
}

@synthesize filter;

@synthesize transform;

- (void) createFilter
{
	CIFilterGenerator *generator = [CIFilterGenerator filterGenerator];
	CIFilter *transformFilter = [CIFilter filterWithName: @"CIAffineTransform"];
	
	[transformFilter setDefaults];

	[generator exportKey: @"inputImage" fromObject: transformFilter withName: @"inputImage"];
	[generator exportKey: @"inputTransform" fromObject: transformFilter withName: @"inputTransform"];
	[generator exportKey: @"outputImage" fromObject: transformFilter withName: @"outputImage"];
	
	self.filter = [generator filter];
}

- (CIImage *) pipeImage: (CIImage *) inputImage
{
	[self.filter setValue: self.transform forKey: @"inputTransform"];
	[self.filter setValue: inputImage forKey: @"inputImage"];
	
	CIImage *result = [self.filter valueForKey: @"outputImage"];
	
	return result;
}

@end
