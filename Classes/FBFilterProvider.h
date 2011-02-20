//
//  FBFilterProvider.h
//  FrameByFrame
//
//  Created by Philipp Brendel on 17.02.11.
//  Copyright 2011 BrendCorp. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

#import "FBFilterProviderDelegate.h"

@interface FBFilterProvider : NSObject <NSTableViewDataSource, NSTableViewDelegate>
{
@private
	IBOutlet id<FBFilterProviderDelegate> delegate;
	IBOutlet NSTableView *filterAttributesView;
	
    NSArray *filterDescriptions;
	CIFilter *artisticFilter;
}

#pragma mark -
#pragma mark Delegate

@property (readonly) id<FBFilterProviderDelegate> delegate;

#pragma mark -
#pragma mark Filter Construction

+ (NSArray *) constructFilters;

#pragma mark -
#pragma mark Accessing Filter Descriptions

@property (readonly) NSArray *filterDescriptions;

#pragma -
#pragma mark Accessing the Currently Selected Filter

@property (retain) CIFilter *artisticFilter;
@property (readonly) NSDictionary *artisticFilterAttributes;

@end
