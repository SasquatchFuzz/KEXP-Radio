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
#import <syslog.h>
#import <sys/socket.h>
#import <netinet/in.h>
#import <SystemConfiguration/SystemConfiguration.h>
#import "sqfzMenuBarController.h"

#define StringFromBOOL(b) ((b) ? @"YES" : @"NO")

@implementation sqfzMenuBarController

- (void) awakeFromNib{
    
    statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength];
    
    // init UI elements in statusMenu
    [self updateStatusIcon];
    [self updateMenuItems];
    
    [statusItem setMenu:statusMenu];
    [statusItem setHighlightMode:YES];
    
    [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver: self
                                                           selector: @selector(receiveSleepNote:)
                                                               name: NSWorkspaceWillSleepNotification object: NULL];

    [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver: self
                                                           selector: @selector(receiveWakeNote:)
                                                               name: NSWorkspaceDidWakeNotification object: NULL];
}

- (void)menuNeedsUpdate:(NSMenu *)menu {
    
    // Checks to make sure connectivity hasn't changed when the menu is shown.
    // This will be done differently(improved) in the future but works for now...
    if([self hasConnectivity])
    {
        // If we have connectivity but theAVPlayer is nil we lost connectivity
        // and it needs been restored
        if(theAVPlayer==nil)
        {
            //[self initStream];
        }
    }
    else
    {
        // There's no connectivity now - Make sure the player's stopped/removed
        [theAVPlayer pause];
        [self deinitStream];
    }
    
    for ( AVMetadataItem* item in playerItem.timedMetadata ) {
        NSString *key = [item commonKey];
        NSString *value = [item stringValue];
        NSLog(@"timedMetadata: key = %@, value = %@", key, value);
    }
    
    NSArray *metadata = [playerItem.asset commonMetadata];
    for ( AVMetadataItem* item in metadata ) {
        NSString *key = [item commonKey];
        NSString *value = [item stringValue];
        NSLog(@"commonMetadata: key = %@, value = %@", key, value);
    }
    
    for ( AVPlayerItemTrack* item in playerItem.tracks ) {

        NSArray *formats = [[item assetTrack] availableMetadataFormats];
        for ( NSString* item in formats ) {
            NSLog(@"availableMetadataFormats: item = %@", item);
        }
        
        NSArray *meta = [[item assetTrack]metadataForFormat:AVMetadataFormatiTunesMetadata];
        for ( AVMetadataItem* item in meta ) {
            id key = [item key];
            NSString *value = [item stringValue];
            NSLog(@"AVMetadataFormatiTunesMetadata: key = %@, value = %@", key, value);
        }
        
    }
    
    [self updateStatusIcon];
    [self updateMenuItems];
}

#pragma mark Stream

-(void)initStream{
    playerItem = [AVPlayerItem playerItemWithURL:[[NSURL alloc] initWithString:@"http://live-mp3-128.kexp.org:8000/"]];
    [playerItem addObserver:self forKeyPath:@"status" options:0 context:nil];
    [playerItem addObserver:self forKeyPath:@"playbackBufferEmpty" options:NSKeyValueObservingOptionNew context:nil];
    [playerItem addObserver:self forKeyPath:@"playbackLikelyToKeepUp" options:NSKeyValueObservingOptionNew context:nil];
    [playerItem addObserver:self forKeyPath:@"timedMetadata" options:NSKeyValueObservingOptionNew context:nil];
    theAVPlayer = [AVPlayer playerWithPlayerItem:self->playerItem];
    streamState=eStreamInitialized;
}

-(void)deinitStream{
    [playerItem removeObserver:self forKeyPath:@"status"];
    [playerItem removeObserver:self forKeyPath:@"playbackBufferEmpty"];
    [playerItem removeObserver:self forKeyPath:@"playbackLikelyToKeepUp"];
    [playerItem removeObserver:self forKeyPath:@"timedMetadata"];
    theAVPlayer=nil;
    playerItem=nil;
    streamState=eStreamUninitialized;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
                        change:(NSDictionary *)change context:(void *)context {
    if (object == playerItem && [keyPath isEqualToString:@"status"])
    {
        if(playerItem.status == AVPlayerStatusReadyToPlay)
        {
            [theAVPlayer play];
            streamState=eStreamPlaying;
            NSLog(@"AVPlayerStatusReadyToPlay");
        }
        else if(playerItem.status == AVPlayerStatusFailed) {
            NSLog(@"AVPlayerStatusFailed:%@" , self->playerItem.error.description);
            [self deinitStream];
            
            //Let's diplay this error for now
            NSAlert *alert = [[NSAlert alloc] init];
            [alert setMessageText:self->playerItem.error.description];
            [alert runModal];
        }
        else if(playerItem.status == AVPlayerStatusUnknown){
            NSLog(@"AVPlayerStatusUnknown");
        }
    }
    else if (object == playerItem && [keyPath isEqualToString:@"playbackBufferEmpty"])
    {
        NSLog(@"playbackBufferEmpty %@", StringFromBOOL(playerItem.playbackLikelyToKeepUp));
        if (playerItem.playbackBufferEmpty) {
            [theAVPlayer pause];
            [self deinitStream];
            [self initStream];
        }
    }
    else if (object == playerItem && [keyPath isEqualToString:@"playbackLikelyToKeepUp"])
    {
        NSLog(@"playbackLikelyToKeepUp: %@", StringFromBOOL(playerItem.playbackLikelyToKeepUp));
    }
    else if (object == playerItem && [keyPath isEqualToString:@"timedMetadata"])
    {
        for ( AVMetadataItem* item in playerItem.timedMetadata )
        {
            NSString *key = [item commonKey];
            NSString *value = [item stringValue];
            NSLog(@"key = %@, value = %@", key, value);
            if([key isEqual:@"title"])
            {
                NSFont* font = [NSFont menuFontOfSize:14] ;
                NSDictionary* fontAttribute = [NSDictionary dictionaryWithObjectsAndKeys:font, NSFontAttributeName, nil] ;
                NSString *nowPlaying = [NSString stringWithFormat:@"Now Playing: \n   %@", value];

                nowPlaying= [nowPlaying stringByReplacingOccurrencesOfString:@" by " withString:@"\n   " options:NSCaseInsensitiveSearch range:NSMakeRange(0,nowPlaying.length)];
                nowPlaying= [nowPlaying stringByReplacingOccurrencesOfString:@" from " withString:@"\n   " options:NSBackwardsSearch range:NSMakeRange(0,nowPlaying.length)];
                NSMutableAttributedString *title = [[NSMutableAttributedString alloc] initWithString:nowPlaying  attributes:fontAttribute];
                [[statusMenu itemAtIndex:eNowPlaying] setAttributedTitle:title];
            }
        }

    }
    
    [self updateStatusIcon];
    [self updateMenuItems];
}

#pragma mark Sleep

-(void)receiveSleepNote:(NSNotification*)note
{
    NSLog(@"receiveSleepNote: %@", [note name]);
    if(theAVPlayer != nil) // Are we already playing?
    {
        [theAVPlayer pause];
        [self deinitStream];
    }
    [self updateStatusIcon];
    [self updateMenuItems];
}

-(void)receiveWakeNote:(NSNotification*)note
{
    NSLog(@"receiveWakeNote: %@", [note name]);
    [self updateStatusIcon];
    [self updateMenuItems];
}

#pragma mark Connectivity

-(BOOL)hasConnectivity {
    struct sockaddr_in zeroAddress;
    bzero(&zeroAddress, sizeof(zeroAddress));
    zeroAddress.sin_len = sizeof(zeroAddress);
    zeroAddress.sin_family = AF_INET;
    
    SCNetworkReachabilityRef reachability = SCNetworkReachabilityCreateWithAddress(kCFAllocatorDefault, (const struct sockaddr*)&zeroAddress);
    if(reachability != NULL)
    {
        //NetworkStatus retVal = NotReachable;
        SCNetworkReachabilityFlags flags;
        if (SCNetworkReachabilityGetFlags(reachability, &flags))
        {
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

#pragma mark User Interface

-(void)updateStatusIcon{
    
    if( theAVPlayer != nil)
    {
        [statusItem setImage:[NSImage imageNamed:@"kexpOn"]];
        [statusItem setAlternateImage:[NSImage imageNamed:@"kexpOn"]];
    }
    else {
        [statusItem setImage:[NSImage imageNamed:@"kexpOff"]];
        [statusItem setAlternateImage:[NSImage imageNamed:@"kexpOff"]];
    }
}

-(void)updateMenuItems{

    if([self hasConnectivity])
    {
        if(theAVPlayer == nil)
        {
            [[statusMenu itemAtIndex:eStopPlay] setTitle:@"Play"];
            [[statusMenu itemAtIndex:eStopPlay] setEnabled:YES];
            // better to hide the item entirely unless it's playing, but until then...
            [[statusMenu itemAtIndex:eNowPlaying] setAttributedTitle:[[NSMutableAttributedString alloc] initWithString:@" "]];
        }
        else if(streamState==eStreamInitialized)
        {
            [[statusMenu itemAtIndex:eStopPlay] setTitle:@"Initializing stream..."];
            [[statusMenu itemAtIndex:eStopPlay] setEnabled:NO];
            // better to hide the item entirely unless it's playing, but until then...
            [[statusMenu itemAtIndex:eNowPlaying] setAttributedTitle:[[NSMutableAttributedString alloc] initWithString:@" "]];
        }
        else
        {
            // The stream's playing
            [[statusMenu itemAtIndex:eStopPlay] setTitle:@"Stop"];
            [[statusMenu itemAtIndex:eStopPlay] setEnabled:YES];

        }
        // Make sure donation option is enabled
        [[statusMenu itemAtIndex:eDonate] setEnabled:YES];
    }
    else
    {
        [[statusMenu itemAtIndex:eStopPlay] setTitle:@"No internet connection"];
        [[statusMenu itemAtIndex:eStopPlay] setEnabled:NO];
        [[statusMenu itemAtIndex:eDonate] setEnabled:NO];
    }
}

#pragma mark User Input Handlers

-(IBAction)stopPlay:(id)sender{
    
    if(theAVPlayer != nil) // Are we already playing?
    {
        [theAVPlayer pause];
        [self deinitStream];
    }
    else
    {
        [self initStream];
    }
    
    [self updateStatusIcon];
    [self updateMenuItems];
}

-(IBAction)donate:(id)sender{
    NSWorkspace* ws = [NSWorkspace sharedWorkspace];
    [ws openURL:[NSURL URLWithString: @"http://www.kexp.org/donate"]];
}

-(IBAction)preferences:(id)sender{
    //NSLog(@"Preferences");
}
@end
