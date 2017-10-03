#ifndef Prefix_h
#define Prefix_h

#import <CocoaLumberjack/CocoaLumberjack.h>

#if DEBUG
static const DDLogLevel ddLogLevel = DDLogLevelVerbose;
#else
static const DDLogLevel ddLogLevel = DDLogLevelWarning;
#endif

#define PREFER_FPS 60

#endif /* Prefix_h */

