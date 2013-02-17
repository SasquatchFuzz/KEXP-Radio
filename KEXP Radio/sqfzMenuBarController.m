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

#import <sys/socket.h>
#import <netinet/in.h>
#import <SystemConfiguration/SystemConfiguration.h>
#import "sqfzMenuBarController.h"

@implementation sqfzMenuBarController
- (void) awakeFromNib{
    
    //Create the NSStatusBar and set its length
    statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength];
    
    // Init stream and UI states
    if([self hasConnectivity])
        [self initStream];
    else
    {
        [[statusMenu itemAtIndex:ePlayPause] setTitle:@"No Internet Connection"];
        [[statusMenu itemAtIndex:ePlayPause] setEnabled:NO];
        [[statusMenu itemAtIndex:eDonate] setEnabled:NO];
        [[statusMenu itemAtIndex:eStop] setHidden:YES];
        [self updateStatusIcon];
    }
    
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
    [playerItem addObserver:self forKeyPath:@"playbackBufferEmpty" options:NSKeyValueObservingOptionNew context:nil];
    [playerItem addObserver:self forKeyPath:@"status" options:0 context:nil];
    theAVPlayer = [AVPlayer playerWithPlayerItem:self->playerItem];
}

-(BOOL)hasConnectivity {
    struct sockaddr_in zeroAddress;
    bzero(&zeroAddress, sizeof(zeroAddress));
    zeroAddress.sin_len = sizeof(zeroAddress);
    zeroAddress.sin_family = AF_INET;
    
    SCNetworkReachabilityRef reachability = SCNetworkReachabilityCreateWithAddress(kCFAllocatorDefault, (const struct sockaddr*)&zeroAddress);
    if(reachability != NULL) {
        //NetworkStatus retVal = NotReachable;
        SCNetworkReachabilityFlags flags;
        if (SCNetworkReachabilityGetFlags(reachability, &flags)) {
            if ((flags & kSCNetworkReachabilityFlagsReachable) == 0)
            {
                // if target host is not reachable
                return NO;
            }
            
            if ((flags & kSCNetworkReachabilityFlagsConnectionRequired) == 0)
            {
                // if target host is reachable and no connection is required
                //  then we'll assume (for now) that your on Wi-Fi
                return YES;
            }
            
            
            if ((((flags & kSCNetworkReachabilityFlagsConnectionOnDemand ) != 0) ||
                 (flags & kSCNetworkReachabilityFlagsConnectionOnTraffic) != 0))
            {
                // ... and the connection is on-demand (or on-traffic) if the
                //     calling application is using the CFSocketStream or higher APIs
                
                if ((flags & kSCNetworkReachabilityFlagsInterventionRequired) == 0)
                {
                    // ... and no [user] intervention is needed
                    return YES;
                }
            }
            
            if ((flags & kSCNetworkReachabilityFlagsIsDirect) == kSCNetworkReachabilityFlagsIsDirect)
            {
                // ... but WWAN connections are OK if the calling application
                //     is using the CFNetwork (CFSocketStream?) APIs.
                return YES;
            }
        }
    }
    
    return NO;
}


- (void)menuNeedsUpdate:(NSMenu *)menu {

    if([self hasConnectivity])
    {
        if(theAVPlayer==Nil)
        {
            [self initStream];
        }
        
        // Make sure donation option is enabled
        [[statusMenu itemAtIndex:eDonate] setEnabled:YES];
    }
    else
    {
        // Make sure the players stopped
        [theAVPlayer pause];
        theAVPlayer=nil;
        
        //and then update the menu items
        [[statusMenu itemAtIndex:ePlayPause] setTitle:@"No Internet Connection"];
        [[statusMenu itemAtIndex:ePlayPause] setEnabled:NO];
        [[statusMenu itemAtIndex:eDonate] setEnabled:NO];
        [[statusMenu itemAtIndex:eStop] setHidden:YES];
    }
    
    //update the icon
    [self updateStatusIcon];
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
            //NSLog(@"Ready");
            [[statusMenu itemAtIndex:ePlayPause] setEnabled:YES];
            [[statusMenu itemAtIndex:ePlayPause] setTitle:@"Play"];
            [playerItem removeObserver:self forKeyPath:@"status"];
        }
        else if(playerItem.status == AVPlayerStatusFailed) {
            //NSLog(@"%@" , self->playerItem.error.description);
            //NSLog(@"PlayerStatusFailed");
        }
        else if(playerItem.status == AVPlayerStatusUnknown){
            //NSLog(@"unknown");
        }
    }

    [self updateStatusIcon];
}

-(IBAction)playPause:(id)sender{
    
    if([theAVPlayer rate] == 0.0)
    {
        [theAVPlayer play];
        [[statusMenu itemAtIndex:eStop] setHidden:FALSE];
        [[statusMenu itemAtIndex:ePlayPause] setTitle:@"Pause"];
        [self updateStatusIcon];
    }
    else
    {
        [theAVPlayer pause];
        [[statusMenu itemAtIndex:ePlayPause] setTitle:@"Resume"];
        [self updateStatusIcon];
    }
}

-(IBAction)stopPlayback:(id)sender {
    [theAVPlayer pause];
    theAVPlayer=nil;
    [self initStream];
};

-(IBAction)donate:(id)sender{
    NSURL* donateUrl = [NSURL URLWithString: @"http://www.kexp.org/donate"];
    NSWorkspace* ws = [NSWorkspace sharedWorkspace];
    
    [ws openURL:donateUrl];
}

-(IBAction)preferences:(id)sender{
    //NSLog(@"Preferences");
}
@end
