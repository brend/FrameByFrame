//
//  FBQuickTimeExporter.h
//  FrameByFrame
//
//  Created by Philipp Brendel on 27.11.10.
//  Copyright 2010 BrendCorp. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QTKit/QTKit.h>
#import "FBReel.h"

@interface FBQuickTimeExporter : NSObject 
{
	FBReel *reel;
	NSDictionary *movieAttributes, *exportAttributes;
	QTMovie *movie;
}

#pragma mark -
#pragma mark Initialization
- (id) initWithReel: (FBReel *) reel
		destination: (NSString *) filename
		 attributes: (NSDictionary *) exportAttributes;

#pragma mark -
#pragma mark Attributes
@property (retain, readonly) FBReel *reel;
@property (retain, readonly) NSDictionary *movieAttributes, *exportAttributes;

#pragma mark -
#pragma mark Adding Images to the Movie
- (void) exportImagesWithIndexes: (NSIndexSet *) indexes;

@end
