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

#import <Cocoa/Cocoa.h>
#import <QTKit/QTKit.h>

@protocol ReportProgressDelegate
- (void) reportExportProgress: (double) progress;
- (void) reportExportRemainingSeconds: (NSUInteger) seconds;
@end

@interface QTMovie (QTMovieExtensions)

- (void)addImagesAsMPEG4:(NSArray *)imageFilesArray
		 framesPerSecond: (NSUInteger) fps
			  attributes: (NSDictionary *) codecAttributes
  reportProgressDelegate: (id<ReportProgressDelegate>) delegate;

- (BOOL)flattenToFilePath:(NSString *)filePath;

@end