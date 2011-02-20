//
//  FBFilterProviderDelegate.h
//  FrameByFrame
//
//  Created by Philipp Brendel on 20.02.11.
//  Copyright 2011 BrendCorp. All rights reserved.
//

#import <Foundation/Foundation.h>

@class FBFilterProvider;

@protocol FBFilterProviderDelegate <NSObject>

- (void) filterProviderDidEditFilter: (FBFilterProvider *) filterProvider;

@end
