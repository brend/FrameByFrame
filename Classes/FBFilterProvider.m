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

#pragma mark Initialization and Deallocation

- (id)init
{
    self = [super init];
    if (self) {
		NSArray *filters = [FBFilterProvider constructFilters];
		
		// Create filter attribute dictionaries (filter + name)
		NSMutableArray *attributeDictionaries = [NSMutableArray arrayWithCapacity: filters.count];
		
		for (CIFilter *filter in filters) {
			NSString *className = [[filter class] description];
			NSString *name = [CIFilter localizedNameForFilterName: className];
			
			NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:
										filter, @"filter",
										name, @"name",
										nil];
			
			[attributeDictionaries addObject: attributes];
		}
		
		filterAttributes = [[NSArray alloc] initWithArray: attributeDictionaries];
    }
    
    return self;
}

- (void)dealloc
{
	[filterAttributes release];
	filterAttributes = nil;
	
    [super dealloc];
}

#pragma mark -
#pragma mark Accessing Filter Attributes

@synthesize filterAttributes;

#pragma mark -
#pragma mark Filter Construction

+ (NSArray *) constructFilters
{
	NSMutableArray *filters = [NSMutableArray array];
	
	CIFilter *filter = nil;
	
	filter = [CIFilter filterWithName: @"CIGloom"];
	[filter setValue: [NSNumber numberWithFloat: 5] forKey: @"inputRadius"];
	[filter setValue: [NSNumber numberWithFloat: 1] forKey: @"inputIntensity"];
	
	[filters addObject: filter];
	
	return filters;
}

@end
