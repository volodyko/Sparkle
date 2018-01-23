//
//  SUUpdateDriver.h
//  Sparkle
//
//  Created by Andy Matuschak on 5/7/08.
//  Copyright 2008 Andy Matuschak. All rights reserved.
//

#ifndef SUUPDATEDRIVER_H
#define SUUPDATEDRIVER_H

#import <Cocoa/Cocoa.h>

#ifdef FINISH_INSTALL_TOOL_NAME
// FINISH_INSTALL_TOOL_NAME expands to unquoted finish_install
#define QUOTE_NS_STRING2(str) @"" #str
#define QUOTE_NS_STRING1(str) QUOTE_NS_STRING2(str)
#define FINISH_INSTALL_TOOL_NAME_STRING QUOTE_NS_STRING1(FINISH_INSTALL_TOOL_NAME)
#else
#error FINISH_INSTALL_TOOL_NAME not defined
#endif


extern NSString * const SUUpdateDriverFinishedNotification;

@class SUHost, SUUpdater;
@interface SUUpdateDriver : NSObject<NSURLDownloadDelegate>
{
	SUHost *host;
	SUUpdater *updater;
	NSURL *appcastURL;
	
	BOOL finished;
	BOOL isInterruptible;
}
@property (retain) SUHost *host;

- initWithUpdater:(SUUpdater *)updater;
- (void)checkForUpdatesAtURL:(NSURL *)URL host:(SUHost *)host;
- (void)abortUpdate;
- (BOOL)isInterruptible;
- (BOOL)finished;

@end

#endif
