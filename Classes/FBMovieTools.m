//
//  FBMovieTools.m
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


#import "FBMovieTools.h"
#import <QTKit/QTKit.h>
#import "QTMovieExtensions.h"


@implementation FBMovieTools

+ (void) saveMovieWithImages: (NSArray *) images 
					  toFile: (NSString *) filename
			 framesPerSecond: (NSUInteger) fps
					   codec: (CodecType) codecType
				 compression: (int) compression
	  reportProgressDelegate: (id) delegate
{
	QTMovie *mMovie = nil;
	DataHandler mDataHandlerRef;
	
    // Check first if the new QuickTime 7.2.1 initToWritableFile: method is available
    if ([[[[QTMovie alloc] init] autorelease] respondsToSelector:@selector(initToWritableFile:error:)] == YES)
    {
		NSString *tempName = filename;
		
        if (nil == tempName) goto bail;
        
        // Create a QTMovie with a writable data reference
        mMovie = [[QTMovie alloc] initToWritableFile:tempName error:NULL];
    }
    else    
    {    
        // The QuickTime 7.2.1 initToWritableFile: method is not available, so use the native 
        // QuickTime API CreateMovieStorage() to create a QuickTime movie with a writable 
        // data reference
		
        OSErr err;
        // create a native QuickTime movie
        Movie qtMovie = [self quicktimeMovieWithFilename: filename dataHandler:&mDataHandlerRef error:&err];
        if (nil == qtMovie) goto bail;
        
        // instantiate a QTMovie from our native QuickTime movie
        mMovie = [QTMovie movieWithQuickTimeMovie:qtMovie disposeWhenDone:YES error:nil];
        if (!mMovie || err) goto bail;
    }
	
	
	// mark the movie as editable
	[mMovie setAttribute:[NSNumber numberWithBool:YES] forKey:QTMovieEditableAttribute];
	
	// add all the images to our movie as MPEG-4 frames
	[mMovie addImagesAsMPEG4: images framesPerSecond: fps codec: codecType compression: compression reportProgressDelegate: delegate];
	[mMovie updateMovieFile];
	
bail:
	
	return;	
}

+ (Movie)quicktimeMovieWithFilename: (NSString *) filename dataHandler:(DataHandler *)outDataHandler error:(OSErr *)outErr
{
	*outErr = -1;
	
	// generate a name for our movie file
	//NSString *tempName = [NSString stringWithCString:tmpnam(nil) 
	//										encoding:[NSString defaultCStringEncoding]];
	NSString *tempName = filename;
	
	if (nil == tempName) goto nostring;
	
	Handle	dataRefH		= nil;
	OSType	dataRefType;
	
	// create a file data reference for our movie
	*outErr = QTNewDataReferenceFromFullPathCFString((CFStringRef)tempName,
													 kQTNativeDefaultPathStyle,
													 0,
													 &dataRefH,
													 &dataRefType);
	if (*outErr != noErr) goto nodataref;
	
	// create a QuickTime movie from our file data reference
	Movie	qtMovie	= nil;
	CreateMovieStorage (dataRefH,
						dataRefType,
						'TVOD',
						smSystemScript,
						newMovieActive, 
						outDataHandler,
						&qtMovie);
	*outErr = GetMoviesError();
	if (*outErr != noErr) goto cantcreatemovstorage;
	
	return qtMovie;
	
	// error handling
cantcreatemovstorage:
	DisposeHandle(dataRefH);
nodataref:
nostring:
	
	return nil;
}

@end
