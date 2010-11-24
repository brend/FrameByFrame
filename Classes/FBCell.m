//
//  FBCell.m
//  FrameByFrame
//
//  Created by Philipp Brendel on 30.10.10.
//  Copyright (c) 2010 BrendCorp. All rights reserved.
//

#import "FBCell.h"

@implementation FBCell

#pragma mark -
#pragma mark Initialization and Deallocation
- (id) initWithIdentifier: (NSString *) aString
					image: (CIImage *) anImage
{
	if ((self = [super init])) {
		self.identifier = aString;
		self.image = anImage;
	}
	
	return self;
}

- (id)init 
{
    if ((self = [super init])) {
    }
    
    return self;
}

- (id) initWithCoder:(NSCoder *)aDecoder
{
	if ((self = [super init])) {
		self.identifier = [aDecoder decodeObjectForKey: @"identifier"];
		
		NSAssert(self.identifier, @"Identifier must not be nil");
	}
	
	return self;
}

+ (id) cellWithIdentifier: (NSString *) identifier
					image: (CIImage *) image
{
	return [[[FBCell alloc] initWithIdentifier: identifier image: image] autorelease];
}

- (void)dealloc 
{
	self.identifier = nil;
	self.image = nil;
	
	[thumbnail release];
	thumbnail = nil;
	
    [super dealloc];
}

#pragma mark -
#pragma mark Accessing Cell Data
@synthesize identifier;

- (CIImage *) image
{
	if (image == nil) {
		NSString *filename = [self.documentURL.path stringByAppendingPathComponent: self.identifier];
		NSData *data = [NSData dataWithContentsOfFile: filename];
		
		image = [[CIImage imageWithData: data] retain];
	}
	
	return image;
}

- (void) setImage:(CIImage *) anImage
{
	[image autorelease];
	image = [anImage retain];
}

- (NSImage *) thumbnail
{
	if (thumbnail == nil) {
		NSString *fullsizedImageFilename = [self.documentURL.path stringByAppendingPathComponent: self.identifier];
		NSImage *fullsizedImage = [[NSImage alloc] initWithContentsOfFile: fullsizedImageFilename];
		NSSize thumbnailSize = NSMakeSize(64, 64);
		NSImage *thumb = [[NSImage alloc] initWithSize: thumbnailSize];
		
		[thumb lockFocus];
		[[NSColor redColor] setFill];
		NSRectFill(NSMakeRect(0, 0, thumbnailSize.width, thumbnailSize.height));
		[fullsizedImage drawInRect: NSMakeRect(0, 0, thumbnailSize.width, thumbnailSize.height)
						  fromRect: NSMakeRect(0, 0, fullsizedImage.size.width, fullsizedImage.size.height)
						 operation: NSCompositeSourceOver fraction: 1.0f];
		[thumb unlockFocus];
		[fullsizedImage release];
				
		thumbnail = thumb;
	}
	
	return thumbnail;
}

#pragma mark -
#pragma mark Saving the Cell
@synthesize documentURL;

- (BOOL) writeToFile: (NSString *) path error: (NSError **) outError
{
	NSBitmapImageRep *imageRep = [[NSBitmapImageRep alloc] initWithCIImage: self.image];
	NSData *data = [imageRep TIFFRepresentation];
	NSError *error = nil;
	
	[imageRep release];
	
	if ([data writeToFile: path options: 0 error: &error])
		return YES;
	else {
		NSLog(@"Could not write cell to %@ due to error: %@", path, error);
		
		if (outError)
			*outError = error;
		
		return NO;
	}

}

#pragma mark -
#pragma mark NSCoding Implementation
- (void) encodeWithCoder:(NSCoder *)aCoder
{
	[aCoder encodeObject: self.identifier forKey: @"identifier"];
}

@end
