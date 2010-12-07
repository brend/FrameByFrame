/*
 *  FBMovieSettingsControllerDelegate.h
 *  FrameByFrame
 *
 *  Created by Philipp Brendel on 27.11.10.
 *  Copyright 2010 BrendCorp. All rights reserved.
 *
 */

@class FBMovieSettingsController;

@protocol FBMovieSettingsControllerDelegate <NSObject>

- (void) movieSettingsController: (FBMovieSettingsController *) controller
				 didSaveSettings: (NSDictionary *) settings;
- (void) movieSettingsControllerDidCancel: (FBMovieSettingsController *) controller;

@end
