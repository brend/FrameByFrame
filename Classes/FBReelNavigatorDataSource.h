//
//  FBReelNavigatorDataSource.h
//  FrameByFrame
//
//  Created by Philipp Brendel on 17.11.10.
//  Copyright 2010 BrendCorp. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>

@class FBReelNavigator;

@protocol FBReelNavigatorDataSource <NSObject>

- (NSInteger) numberOfCellsForReelNavigator: (FBReelNavigator *) navigator;
- (NSImage *) reelNavigator: (FBReelNavigator *) navigator
	thumbnailForCellAtIndex: (NSInteger) index;
- (CIImage *) reelNavigator: (FBReelNavigator *) navigator
		imageForCellAtIndex: (NSInteger) index;

@end
