//
//  FBReelNavigatorDataSource.h
//  FrameByFrame
//
//  Created by Philipp Brendel on 17.11.10.
//  Copyright 2010 BrendCorp. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class FBReelNavigator;

@protocol FBReelNavigatorDataSource <NSObject>

- (NSImage *) reelNavigator: (FBReelNavigator *) navigator
	thumbnailForCellAtIndex: (NSInteger) index;

@end
