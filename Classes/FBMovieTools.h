//
//  FBMovieTools.h
//  FrameByFrame
//
//  Created by Philipp Brendel on 29.12.07.
//  Copyright 2009 Philipp Brendel. All rights reserved.
//
/*
 This file is part of FrameByFrame.
 
 FrameByFrame is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.
 
 FrameByFrame is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with FrameByFrame.  If not, see <http://www.gnu.org/licenses/>.
 */


#import <Cocoa/Cocoa.h>
#import <QTKit/QTKit.h>

@interface FBMovieTools : NSObject {

}

+ (void) saveMovieWithImages: (NSArray *) images 
					  toFile: (NSString *) filename
			 framesPerSecond: (NSUInteger) fps
					   codec: (CodecType) codecType
				 compression: (int) compression
	  reportProgressDelegate: (id) delegate;

+ (Movie)quicktimeMovieWithFilename: (NSString *) filename dataHandler:(DataHandler *)outDataHandler error:(OSErr *)outErr;

+ (NSString *) nameForCodec: (CodecType) codec;

@end
