//
//  NSDictionary(CIFilterAttributes).m
//  DynamicControls
//
//  Created by Philipp Brendel on 18.02.11.
//  Copyright 2011 BrendCorp. All rights reserved.
//

#import "NSDictionary(CIFilterAttributes).h"


@implementation NSDictionary (CIFilterAttributes)

- (NSString *) CIAttributeClass
{
	return [self objectForKey: @"CIAttributeClass"];
}

@end
