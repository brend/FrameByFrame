//
//  FBFilterProvider.m
//  FrameByFrame
//
//  Created by Philipp Brendel on 17.02.11.
//  Copyright 2011 BrendCorp. All rights reserved.
//

#import "FBFilterProvider.h"
#import <QuartzCore/QuartzCore.h>

@implementation FBFilterProvider

- (id)init
{
    self = [super init];
    if (self) {
		NSMutableArray *a = [NSMutableArray array];
		
		CIFilter *filter = [CIFilter filterWithName: @"CIGloom"];
		
		[filter setValue: [NSNumber numberWithFloat: 5] forKey: @"inputRadius"];
		[filter setValue: [NSNumber numberWithFloat: 1] forKey: @"inputIntensity"];
		
		// Localize filter name
		NSString *className = [[filter class] description];
		NSString *name = [CIFilter localizedNameForFilterName: className];
			
		NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:
									filter, @"filter",
									name, @"name",
									nil];
		
		[a addObject: attributes];
		
		filterAttributes = [[NSArray alloc] initWithArray: a];
    }
    
    return self;
}

- (void)dealloc
{
	[filterAttributes release];
	filterAttributes = nil;
	
    [super dealloc];
}

@synthesize filterAttributes;

@end
