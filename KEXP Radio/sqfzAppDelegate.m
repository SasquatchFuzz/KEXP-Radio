//
//  sqfzAppDelegate.m
//  KEXP Radio
//
//  Created by Brian Kennedy on 2/9/13.
//  Copyright (c) 2013 Brian Kennedy. All rights reserved.
//

#import "sqfzAppDelegate.h"

@implementation sqfzAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    if ([[NSRunningApplication runningApplicationsWithBundleIdentifier:[[NSBundle mainBundle] bundleIdentifier]] count] > 1) {
            [[NSAlert alertWithMessageText:[NSString stringWithFormat:@"Another copy of %@ is already running.", [[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString *)kCFBundleNameKey]]
                             defaultButton:nil alternateButton:nil otherButton:nil informativeTextWithFormat:@"This copy will now quit."] runModal];
            
            [NSApp terminate:nil];
    }
}

@end
