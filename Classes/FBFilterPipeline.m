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
- (void) generateFilterForSinglePicture;
- (void) generateFilterForMultiplePictures: (NSInteger) skinCount;
@end

#pragma mark -
#pragma mark FBFilterPipeline Implementation
@implementation FBFilterPipeline

#pragma mark -
#pragma mark Initialization and Deallocation
- (id) initWithSkinCount: (NSInteger) skinCount
{
	if ((self = [super init])) {
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
#pragma mark Creating the Core Image Filter
- (void) generateFilterWithSkinCount: (NSInteger) skinCount
{
	self.filter = nil;
	self.parameterNames = nil;
	
	switch (skinCount) {
		case 0:
			return;
		case 1:
			[self generateFilterForSinglePicture];
			break;
		default:
			[self generateFilterForMultiplePictures: skinCount];
			break;
	}
	
	// [self.filter setDefaults];
}

- (void) generateFilterForSinglePicture
{
	CIFilterGenerator *generator = [CIFilterGenerator filterGenerator];
	CIFilter
		*fade = [CIFilter filterWithName: @"CIColorMatrix"],
		*blend = [CIFilter filterWithName: @"CISourceOverCompositing"];
	
	[fade setDefaults];
	[fade setValue: [CIVector vectorWithX: 0.0f Y: 0.0f Z: 0.0f W: 0.5f] forKey: @"inputAVector"];
	
	[blend setDefaults];
	
	[generator connectObject: fade withKey: @"outputImage" toObject: blend withKey: @"inputImage"];
	[generator exportKey: @"inputImage" fromObject: fade withName: @"inputImage0"];
	[generator exportKey: @"inputBackgroundImage" fromObject: blend withName: @"videoImage"];
	[generator exportKey: @"outputImage" fromObject: blend withName: @"outputImage"];
	
	self.filter = [generator filter];
	self.parameterNames = [NSArray arrayWithObject: @"inputImage0"];
}

- (void) generateFilterForMultiplePictures: (NSInteger) skinCount
{
	CIFilterGenerator *generator = [CIFilterGenerator filterGenerator];
	CIFilter *penultimateBlend = nil;
	NSMutableArray *params = [NSMutableArray arrayWithCapacity: skinCount];
	
	NSAssert(skinCount > 1, @"This method expects a skin count of at least 2");
	
	for (NSInteger i = 0; i < skinCount; ++i) {
		CIFilter *fade = [CIFilter filterWithName: @"CIColorMatrix"];
		CIFilter *blend = [CIFilter filterWithName: @"CISourceOverCompositing"];
		float alpha = 1.0f / (float) skinCount;
		//		float alpha = 0.5f;
		
		[fade setDefaults];
		[fade setValue: [CIVector vectorWithX: 0.0f Y: 0.0f Z: 0.0f W: alpha] forKey: @"inputAVector"];
		
		[blend setDefaults];
		
		NSString *exportedInput = [NSString stringWithFormat: @"inputImage%d", i];
		
		if (i == 0) {
			[generator connectObject: fade withKey: @"outputImage" toObject: blend withKey: @"inputImage"];
		} else {
			[generator connectObject: fade withKey: @"outputImage" toObject: blend withKey: @"inputBackgroundImage"];
			[generator connectObject: penultimateBlend withKey: @"outputImage" toObject: blend withKey: @"inputImage"];
		}
		
		[generator exportKey: @"inputImage" fromObject: fade withName: exportedInput];
		[params addObject: exportedInput];
		
		penultimateBlend = blend;
	}
	
	NSAssert(penultimateBlend != nil, @"There must be at least one picture thingy");
	
	CIFilter *finalBlend = [CIFilter filterWithName: @"CISourceOverCompositing"];
	
	[finalBlend setDefaults];
	[generator connectObject: penultimateBlend withKey: @"outputImage" toObject: finalBlend withKey: @"inputImage"];
	[generator exportKey: @"inputBackgroundImage" fromObject: finalBlend withName: @"videoImage"];
	[generator exportKey: @"outputImage" fromObject: finalBlend withName: @"outputImage"];
	
	// So wird gespeichert
	//	[generator setClassAttributes: [NSDictionary dictionary]];
	//	[generator writeToURL: [NSURL fileURLWithPath: @"/Users/brph0000/Desktop/Threeway.plist"] atomically: YES];
	
	self.filter = [generator filter];
	self.parameterNames = params;
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
		@throw [NSException exceptionWithName: NSInvalidArgumentException reason: @"Number of skin images doesn't match skin count" userInfo: nil];
	
	[self.filter setDefaults];
	
	for (NSInteger i = 0; i < skinImages.count; ++i) {
		CIImage *picture = [skinImages objectAtIndex: i];
		
		[self.filter setValue: picture forKey: [self.parameterNames objectAtIndex: i]];
	}
	
	[self.filter setValue: videoImage forKey: @"videoImage"];	
	
	return [self.filter valueForKey: @"outputImage"];
}

@end
