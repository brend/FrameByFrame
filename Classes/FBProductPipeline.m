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
- (void) createFilterWithArtisticFilter: (CIFilter *) aFilter;
@end

@implementation FBProductPipeline

- (id) initWithArtisticFilter: (CIFilter *) aFilter
{
    self = [super init];
    if (self) {
		self.transform = [NSAffineTransform transform];
		
        [self createFilterWithArtisticFilter: aFilter];
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

- (void) createFilterWithArtisticFilter: (CIFilter *) artisticFilter
{
	CIFilterGenerator *generator = [CIFilterGenerator filterGenerator];
	CIFilter *transformFilter = [CIFilter filterWithName: @"CIAffineTransform"];
	
	[transformFilter setDefaults];

	[generator exportKey: @"inputImage" fromObject: transformFilter withName: @"inputImage"];
	[generator exportKey: @"inputTransform" fromObject: transformFilter withName: @"inputTransform"];
	
	if (artisticFilter) {
		// NOTE Give the generator its own copy of the filter
		// in order to rule out external influences
		CIFilter *filterCopy = [artisticFilter copy];
		
		[generator connectObject: transformFilter withKey: @"outputImage" toObject: filterCopy withKey: @"inputImage"];
		[generator exportKey: @"outputImage" fromObject: filterCopy withName: @"outputImage"];
		[filterCopy release];
	} else
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
