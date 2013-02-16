//
//  sqfzMenuBarController.m
//  KEXP Radio
//
//  Created by Brian Kennedy on 2/9/13.
//  Copyright (c) 2013 Brian Kennedy (@sasquatchfuzz)
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this software
//  and associated documentation files (the "Software"), to deal in the Software without restriction,
//  including without limitation the rights to use, copy, modify, merge, publish, distribute,
//  sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all copies or
//  substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING
//  BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
//  DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


//  MP3 (32k): http://live-mp3-32.kexp.org:8000/
//  MP3 (128k): http://live-mp3-128.kexp.org:8000/
//  http://kexp-mp3-2.cac.washington.edu:8000/

#import "sqfzMenuBarController.h"


@implementation sqfzMenuBarController
- (void) awakeFromNib{
    
    //Create the NSStatusBar and set its length
    statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength];
    
    // Init stream and UI states
    [self initStream];
    
    //Tells the NSStatusItem what menu to load
    [statusItem setMenu:statusMenu];
    [statusItem setHighlightMode:YES];
}

-(void) initStream{
    // Mark the stream not ready and disable the UI
    [self updateStatusIcon];
    [[statusMenu itemAtIndex:ePlayPause] setTitle:@"Initializing stream..."];
    [[statusMenu itemAtIndex:ePlayPause] setEnabled:NO];
    [[statusMenu itemAtIndex:eStop] setHidden:YES];
    
    // Initialize the stream
    NSURL *url = [[NSURL alloc] initWithString:@"http://live-mp3-128.kexp.org:8000/"];
    playerItem = [AVPlayerItem playerItemWithURL:url];
    [playerItem addObserver:self forKeyPath:@"status" options:0 context:nil];
    theAVPlayer = [AVPlayer playerWithPlayerItem:self->playerItem];
}

-(void)updateStatusIcon{
    if([theAVPlayer rate] == 1.0)
    {
        [statusItem setImage:[NSImage imageNamed:@"kexpOn"]];
        [statusItem setAlternateImage:[NSImage imageNamed:@"kexpOn"]];
    }
    else {
        [statusItem setImage:[NSImage imageNamed:@"kexpOff"]];
        [statusItem setAlternateImage:[NSImage imageNamed:@"kexpOff"]];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
                        change:(NSDictionary *)change context:(void *)context {
    if (object == playerItem && [keyPath isEqualToString:@"status"]) {
        if(playerItem.status == AVPlayerStatusReadyToPlay)
        {
            NSLog(@"Ready");
            [[statusMenu itemAtIndex:ePlayPause] setEnabled:YES];
            [[statusMenu itemAtIndex:ePlayPause] setTitle:@"Play"];
            [playerItem removeObserver:self forKeyPath:@"status"];
        }
        else if(playerItem.status == AVPlayerStatusFailed) {
            NSLog(@"%@" , self->playerItem.error.description);
            NSLog(@"PlayerStatusFailed");
        }
        else if(playerItem.status == AVPlayerStatusUnknown)
            NSLog(@"unknown");
    }

    [self updateStatusIcon];
}

-(IBAction)playPause:(id)sender{
    
    if([theAVPlayer rate] == 0.0)
    {
        NSLog(@"Play");
        [theAVPlayer play];
        [[statusMenu itemAtIndex:eStop] setHidden:FALSE];
        [[statusMenu itemAtIndex:ePlayPause] setTitle:@"Pause"];
        [self updateStatusIcon];
    }
    else
    {
        NSLog(@"Pause");
        [theAVPlayer pause];
        [[statusMenu itemAtIndex:ePlayPause] setTitle:@"Resume"];
        [self updateStatusIcon];
    }
}

-(IBAction)stopPlayback:(id)sender {
    NSLog(@"Stop");
    [theAVPlayer pause];
    theAVPlayer=nil;
    [self initStream];
};

-(IBAction)donate:(id)sender{
    NSLog(@"Donate");
    
    NSURL* donateUrl = [NSURL URLWithString: @"http://www.kexp.org/donate"];
    NSWorkspace* ws = [NSWorkspace sharedWorkspace];
    
    [ws openURL:donateUrl];
}

-(IBAction)preferences:(id)sender{
    NSLog(@"Preferences");
}
@end
