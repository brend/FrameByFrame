//
//  FBApplicationDelegate.m
//  FrameByFrame
//
//  Created by Philipp Brendel on 28.10.10.
//  Copyright (c) 2010 BrendCorp. All rights reserved.
//

#import "FBApplicationDelegate.h"


@implementation FBApplicationDelegate

- (id)init 
{
    if ((self = [super init])) {
    }
    
    return self;
}

- (void)dealloc 
{
    [super dealloc];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	[self registerInitialUserDefaults];
	[self showCrashRecoveryWindowIfNecessary];
	
	applicationHasStarted = YES;
}

- (BOOL)applicationShouldOpenUntitledFile:(NSApplication *)sender
{
    if (!applicationHasStarted)
    {
        // Get the recent documents
        NSDocumentController *controller = [NSDocumentController sharedDocumentController];
        NSArray *documents = [controller recentDocumentURLs];
        
        // If there is a recent document, try to open it.
        if ([documents count] > 0)
        {
            NSError *error = nil;
			
			[controller openDocumentWithContentsOfURL: [documents objectAtIndex:0]
											  display: YES
												error: &error];
            
            // If there was no error, then prevent untitled from appearing.
            if (error == nil)
            {
                return NO;
            }
        }
    }
    
    return YES;
}

#pragma mark -
#pragma mark Registering User Defaults
- (void) registerInitialUserDefaults
{
	NSString *defaultsPath = [[NSBundle mainBundle] pathForResource: @"InitialUserDefaults" ofType: @"plist"];
	NSDictionary *defaults = [NSDictionary dictionaryWithContentsOfFile: defaultsPath];
	[[NSUserDefaults standardUserDefaults] registerDefaults: defaults];
	[[NSUserDefaultsController sharedUserDefaultsController] setInitialValues: defaults];
}

#pragma mark -
#pragma mark Recovering Unsaved Documents
- (void) showCrashRecoveryWindowIfNecessary
{
	if (crashRecoveryController.unsavedDocumentsExist) {
		[crashRecoveryWindow makeKeyAndOrderFront: self];
	}
}	

@end
