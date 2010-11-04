//
//  FBCell.h
//  FrameByFrame
//
//  Created by Philipp Brendel on 30.10.10.
//  Copyright (c) 2010 BrendCorp. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>

@interface FBCell : NSObject <NSCoding>
{
@private
	NSURL *documentURL;
	NSString *identifier;
	CIImage *image;
}

#pragma mark -
#pragma mark Initialization
- (id) initWithIdentifier: (NSString *) identifier image: (CIImage *) image;
+ (id) cellWithIdentifier: (NSString *) identifier image: (CIImage *) image;
- (id) initWithCoder:(NSCoder *)aDecoder;

#pragma mark -
#pragma mark Accessing Cell Data
@property (copy) NSString *identifier;
@property (retain) CIImage *image;
@property (readonly) CIImage *thumbnail;

#pragma mark -
#pragma mark Saving the Cell
@property (retain) NSURL *documentURL;
- (BOOL) writeToFile: (NSString *) filename error: (NSError **) outError;

#pragma mark -
#pragma mark NSCoding Implementation
- (void) encodeWithCoder:(NSCoder *)aCoder;

@end
