//
//  FBFileInfo.m
//  FrameByFrame
//
//  Created by Philipp Brendel on 06.02.11.
//  Copyright 2011 BrendCorp. All rights reserved.
//

#import "FBFileInfo.h"

@implementation FBFileInfo

static NSArray 
	*FBSystemFilenames = nil, 
	*FBReadableMagics = nil;

+ (void) initialize
{
	FBSystemFilenames = [[NSArray alloc] initWithObjects: @"QuickLook", @"reel", @"settings", nil];
	
	// Magic numbers are as follows (not all are in use)
	// BMP	0x424D
	// JPG	0xFFD8FFE0
	// PNG	0x89504E47
	// TIFF	0x4D4D002A
	NSArray *magicNumbers = [NSArray arrayWithObjects: @"MM", @"BM", nil];
	NSMutableArray *magicData = [NSMutableArray array];
	
	for (NSString *mn in magicNumbers)
		[magicData addObject: [mn dataUsingEncoding: NSASCIIStringEncoding]];
	
	FBReadableMagics = [[NSArray alloc] initWithArray: magicData];
}

- (id)init 
{
    if ((self = [super init])) {
        // Initialization code here.
    }
    
    return self;
}

- (void)dealloc 
{
    // Clean-up code here.
    
    [super dealloc];
}

+ (NSArray *) systemFilenames
{
	return FBSystemFilenames;
}

+ (NSArray *) readableMagics
{
	return FBReadableMagics;
}

// + (BOOL) saneFile: (NSString *) filename atPath: (NSString *) path
- (BOOL) readableImageFile: (NSString *) path
{
	NSString *file = path.lastPathComponent;
	
	if ([[FBFileInfo systemFilenames] containsObject: file]
		|| [file hasPrefix: @"."])
		return NO;
	
	NSFileHandle *fileHandle = [NSFileHandle fileHandleForReadingAtPath: path];
	
	if (fileHandle == nil)
		return NO;
	
	NSData *magic = [fileHandle readDataOfLength: 2];
	
	return [[FBFileInfo readableMagics] containsObject: magic];
}

@end
