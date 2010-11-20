// Copyright 2009 Philipp Brendel.
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


#import "QTMovieExtensions.h"

@implementation QTMovie (QTMovieExtensions)

//
// addImagesAsMPEG4
//
// given an array of image file paths (NSString objects), add each
// image to the movie as a new MPEG4 movie frame
//
// Inputs
//		imageFilesArray - an array of image file paths (NSString objects)
//
// Outputs
//		images specified in imageFilesArray are added to movie
//      as new movie frames
//

- (void)addImagesAsMPEG4: (NSArray *) images 
		 framesPerSecond: (NSUInteger) fps
			  attributes: (NSDictionary *) codecAttributes
  reportProgressDelegate: (id<ReportProgressDelegate>) delegate
{
	if (images == nil) @throw [NSException exceptionWithName: NSInvalidArgumentException reason: @"images is nil" userInfo: nil];
	if (codecAttributes == nil) @throw [NSException exceptionWithName: NSInvalidArgumentException reason: @"codecAttributes is nil" userInfo: nil];
	
    // create a QTTime value to be used as a duration when adding 
    // the image to the movie
	long timeScale      = 1000;
	long long timeValue = (long long) ceil((double) timeScale / (double) fps);
	QTTime duration     = QTMakeTime(timeValue, timeScale);

	// iterate over all the images in the array and add
	// them to our movie one-by-one
	NSUInteger imageCount = [images count], imagesProcessed = 0, lastReportedTime = 0;
	NSDate *startTime = [NSDate date];
	
	for (NSImage *anImage in images)
	{
        if (anImage)
        {
            // Adds an image for the specified duration to the QTMovie
            [self addImage:anImage 
                    forDuration:duration
                    withAttributes: codecAttributes];
        }
		
		[delegate reportExportProgress: (double) (++imagesProcessed) / (double) imageCount];
		
		NSUInteger time = (NSUInteger) ceil((imageCount - imagesProcessed) * (-[startTime timeIntervalSinceNow] / (double) imagesProcessed));
		
		if (time != lastReportedTime)
			[delegate reportExportRemainingSeconds: lastReportedTime = time];
	}
}

//
// flattenToFilePath
//
// flatten the movie to the specified path
//
// Inputs
//		filePath - destination file path for flattened movie
//
// Outputs
//		movie is flattened to a self-contained movie file
//      specified by the filePath input parameter
//
	
- (BOOL)flattenToFilePath:(NSString *)filePath
{
	BOOL success = NO;

	if (!filePath) 
		goto bail;

	// create a dict. with the movie flatten attribute (QTMovieFlatten)
	// which we'll use to flatten the movie to a file below
	
	// specify a 'YES' in the dictionary to flatten to a new movie file
	
	// specify a 'NO' in the dictionary to only create a reference movie
	NSDictionary	*dict = nil;
	dict = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] 
				forKey:QTMovieFlatten];
	if (dict)
	{
		// create a new movie file and flatten the movie to the file
		
		// passing the QTMovieFlatten attribute here means the movie
		// will be flattened
		success = [self writeToFile:filePath withAttributes:dict];
	}

bail:
	return success;
}


@end
