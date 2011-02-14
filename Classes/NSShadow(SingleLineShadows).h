//
//  NSShadow(SingleLineShadows).h
//  FrameByFrame
//
//  Created by Philipp Brendel on 13.02.11.
//  Copyright 2011 BrendCorp. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSShadow (SingleLineShadows)

+ (id) shadowWithOffset: (NSSize) offset
			 blurRadius: (CGFloat) radius
				  color: (NSColor *) shadowColor;

+ (void)setShadowWithOffset:(NSSize)offset 
				 blurRadius:(CGFloat)radius
					  color:(NSColor *)shadowColor;
+ (void)clearShadow;

@end
