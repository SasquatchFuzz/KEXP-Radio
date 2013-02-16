//
//  sqfzMenuBarController.h
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

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#import <QTKit/QTKit.h>
#import <AVFoundation/AVFoundation.h>

typedef enum {
    ePlayPause=0,
    eStop,
    eDonate,
    ePreferences,
    eQuit,
} MenuItemType;

@interface sqfzMenuBarController : NSObject {
    /* Our outlets which allow us to access the interface */
    IBOutlet NSMenu *statusMenu;

    NSStatusItem *statusItem;
    AVPlayerItem *playerItem;
    AVPlayer *theAVPlayer;
    boolean_t bStreamReady;
}

-(void)initStream;
-(void)updateStatusIcon;
-(IBAction)playPause:(id)sender;
-(IBAction)stopPlayback:(id)sender;
-(IBAction)donate:(id)sender;
-(IBAction)preferences:(id)sender;
@end
