//
//  FBFileInfo.h
//  FrameByFrame
//
//  Created by Philipp Brendel on 06.02.11.
//  Copyright 2011 BrendCorp. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface FBFileInfo : NSObject
{
@private
    
}

+ (NSArray *) systemFilenames;
+ (NSArray *) readableMagics;

- (BOOL) readableImageFile: (NSString *) path;

@end
