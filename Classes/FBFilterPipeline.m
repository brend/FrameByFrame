//
//  FBFilterPipeline.m
//  FrameByFrame
//
//  Created by Philipp Brendel on 15.11.10.
//  Copyright 2010 BrendCorp. All rights reserved.
//

#import "FBFilterPipeline.h"

#pragma mark -
#pragma mark FBFilterPipeline Private Interface
@interface FBFilterPipeline ()
@property (retain) CIFilter *filter;
@property (copy) NSArray *parameterNames;
- (void) generateFilterWithSkinCount: (NSInteger) skinCount;
- (void) buildFilter: (NSUInteger) skinCount;
@end

#pragma mark -
#pragma mark FBFilterPipeline Implementation
@implementation FBFilterPipeline

#pragma mark -
#pragma mark Initialization and Deallocation
- (id) initWithSkinCount: (NSInteger) skinCount
{
	if ((self = [super init])) {
		self.opacity = 0.5f;
		[self generateFilterWithSkinCount: skinCount];
	}
	
	return self;
}

+ (id) filterPipelineWithSkinCount: (NSInteger) skinCount
{
	return [[[FBFilterPipeline alloc] initWithSkinCount: skinCount] autorelease];
}

- (void) dealloc
{
	self.filter = nil;
	self.parameterNames = nil;
	[super dealloc];
}

#pragma mark -
#pragma mark Querying the Underlying Core Image Filter
@synthesize filter;

#pragma mark -
#pragma mark Controlling Translucency
@synthesize opacity;

#pragma mark -
#pragma mark Creating the Core Image Filter
- (void) generateFilterWithSkinCount: (NSInteger) skinCount
{
	self.filter = nil;
	self.parameterNames = nil;
	
	if (skinCount > 0)
		[self buildFilter: skinCount];
}

- (void) buildFilter: (NSUInteger) skinCount
{
	if (skinCount == 0)
		return;
	
	CIFilterGenerator *generator = [CIFilterGenerator filterGenerator];
	NSMutableArray *params = [NSMutableArray arrayWithCapacity: skinCount];
	
	// Opacity of the onion skin images
	float alpha = 1.0f / (float) skinCount;
	
	// Step 0
	CIFilter *firstBlend = [CIFilter filterWithName: @"CISourceOverCompositing"];
	
	[firstBlend setDefaults];
	[generator exportKey: @"inputBackgroundImage" fromObject: firstBlend withName: @"inputImage0"];
	
	[params addObject: @"inputImage0"];
	
	// Step 1 through (skinCount - 1)
	CIFilter *formerBlend = firstBlend;
	
	for (NSInteger i = 1; i < skinCount; ++i) {
		NSString *exportedInput = [NSString stringWithFormat: @"inputImage%d", i];
		CIFilter *fade = [CIFilter filterWithName: @"CIColorMatrix"];
		CIFilter *blend = [CIFilter filterWithName: @"CISourceOverCompositing"];

		[fade setDefaults];
		[fade setValue: [CIVector vectorWithX: 0.0f Y: 0.0f Z: 0.0f W: alpha] forKey: @"inputAVector"];

		[blend setDefaults];
		
		[generator exportKey: @"inputImage" fromObject: fade withName: exportedInput];
		[generator connectObject: fade withKey: @"outputImage" toObject: formerBlend withKey: @"inputImage"];
		[generator connectObject: formerBlend withKey: @"outputImage" toObject: blend withKey: @"inputBackgroundImage"];
		
		[params addObject: exportedInput];
		formerBlend = blend;
	}
	
	// Final step: Put the video image through a fader and hook it up
	// Export the fader's alpha vector as well as the final output image
	CIFilter *videoFade = [CIFilter filterWithName: @"CIColorMatrix"];
	
	[videoFade setDefaults];
	[generator exportKey: @"inputAVector" fromObject: videoFade withName: @"inputAVector"];	
	
	[generator exportKey: @"inputImage" fromObject: videoFade withName: @"videoImage"];
	[generator connectObject: videoFade withKey: @"outputImage" toObject: formerBlend withKey: @"inputImage"];
	
	[generator exportKey: @"outputImage" fromObject: formerBlend withName: @"outputImage"];
	
	self.filter = [generator filter];
	self.parameterNames = params;
	
	// So wird gespeichert
	//	[generator setClassAttributes: [NSDictionary dictionary]];
	//	[generator writeToURL: [NSURL fileURLWithPath: @"/Users/brph0000/Desktop/Threeway.plist"] atomically: YES];
}

#pragma mark -
#pragma mark Retrieving Pipeline Information
@synthesize parameterNames;

- (NSUInteger) skinCount
{
	return parameterNames.count;
}

#pragma mark -
#pragma mark Piping Images Through the Pipeline
- (CIImage *) pipeVideoImage: (CIImage *) videoImage
				  skinImages: (NSArray *) skinImages
{
	if (skinImages.count != self.skinCount)
		return nil;
	
	[self.filter setDefaults];
	
	for (NSInteger i = 0; i < skinImages.count; ++i) {
		CIImage *picture = [skinImages objectAtIndex: i];
		
		[self.filter setValue: picture forKey: [self.parameterNames objectAtIndex: i]];
	}
	
	[self.filter setValue: videoImage forKey: @"videoImage"];
	[self.filter setValue: [CIVector vectorWithX: 0.0f Y: 0.0f Z: 0.0f W: self.opacity] forKey: @"inputAVector"];
	
	return [self.filter valueForKey: @"outputImage"];
}

@end
