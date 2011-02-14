//
//  NSShadow(SingleLineShadows).m
//  FrameByFrame
//
//  Created by Philipp Brendel on 13.02.11.
//  Copyright 2011 BrendCorp. All rights reserved.
//

#import "NSShadow(SingleLineShadows).h"


@implementation NSShadow (SingleLineShadows)

+ (id) shadowWithOffset: (NSSize) offset
			 blurRadius: (CGFloat) radius
				  color: (NSColor *) shadowColor
{
	NSShadow *aShadow = [[NSShadow alloc] init];
    
	[aShadow setShadowOffset:offset];
    [aShadow setShadowBlurRadius:radius];
    [aShadow setShadowColor:shadowColor];
	
	return [aShadow autorelease];
}


+ (void)setShadowWithOffset:(NSSize)offset
				 blurRadius:(CGFloat)radius
					  color:(NSColor *)shadowColor
{
	[[NSShadow shadowWithOffset: offset blurRadius: radius color: shadowColor] set];
}

+ (void)clearShadow
{
    NSShadow *aShadow = [[[self alloc] init] autorelease];
	
    [aShadow set];
}

@end
