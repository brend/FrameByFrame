//
//  FBFilterProvider.h
//  FrameByFrame
//
//  Created by Philipp Brendel on 17.02.11.
//  Copyright 2011 BrendCorp. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface FBFilterProvider : NSObject 
{
@private
    NSArray *filterAttributes;
}

@property (readonly) NSArray *filterAttributes;

@end
