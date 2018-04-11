#ifndef OverlayHeader_h
#define OverlayHeader_h

#import <UIKit/UIKit.h>
#import "AppState.h"

#define RECORD_LONG_TAP_DURATION 1
#define SHOW_ERROR_RECORDING_LABEL_DURATION 3

typedef void (^HotAction)(BOOL); // long

#define RECORD_SIZE 60.5
#define RECORD_OFFSET_X 25.5
#define RECORD_OFFSET_Y 25.5

#define MIC_SIZE_W 27.75
#define MIC_SIZE_H 27.75

#define TRACK_SIZE_W 256
#define TRACK_SIZE_H 62

#define DOT_SIZE 6
#define DOT_OFFSET_Y 9.5

#define RECORD_LABEL_OFFSET_X 4.5
#define RECORD_LABEL_WIDTH 80
#define RECORD_LABEL_HEIGHT 12

#define URL_BAR_HEIGHT 49
#define URL_BAR_ANIMATION_TIME_IN_SECONDS 0.2

#warning LOCALIZATION
#define HELP_TEXT     @"Tap for photo, hold for video"
#define ERROR_TEXT    @"Some error has occurred while capturing"
#define DISABLED_TEXT @"Сapturing is disabled now"
#define GRANT_TEXT    @"Tap to provide access to camera to make photos / videos"

#define HELP_LABEL_HEIGHT 16
#define HELP_LABEL_WIDTH 350



static inline CGRect recordFrameIn(CGRect viewRect)
{
    return CGRectMake(viewRect.size.width - RECORD_SIZE - RECORD_OFFSET_X,
                      viewRect.origin.y + (viewRect.size.height - viewRect.origin.y) / 2 - RECORD_SIZE / 2,
                      RECORD_SIZE,
                      RECORD_SIZE);
}

static inline CGRect micFrameIn(CGRect viewRect)
{
    return CGRectMake(viewRect.size.width - RECORD_SIZE - RECORD_OFFSET_X + (RECORD_SIZE - MIC_SIZE_W) / 2,
                      viewRect.origin.y + RECORD_OFFSET_Y,
                      MIC_SIZE_W,
                      MIC_SIZE_H);
}

static inline CGRect debugFrameIn(CGRect viewRect)
{
    return CGRectMake(RECORD_OFFSET_X,
                      viewRect.size.height - RECORD_OFFSET_Y - MIC_SIZE_H,
                      MIC_SIZE_W,
                      MIC_SIZE_H);
}

static inline CGRect showFrameIn(CGRect viewRect)
{
    return CGRectMake(viewRect.size.width - RECORD_OFFSET_X - MIC_SIZE_W,
                      viewRect.size.height - RECORD_OFFSET_Y - MIC_SIZE_H,
                      MIC_SIZE_W,
                      MIC_SIZE_H);
}

static inline CGRect trackFrameIn(CGRect viewRect)
{
    return CGRectMake(viewRect.size.width / 2 - TRACK_SIZE_W / 2,
                      viewRect.size.height - RECORD_OFFSET_Y - MIC_SIZE_H / 2 - TRACK_SIZE_H / 2,
                      TRACK_SIZE_W,
                      TRACK_SIZE_H);
}

static inline CGRect dotFrameIn(CGRect viewRect)
{
    return CGRectMake(viewRect.size.width / 2 - DOT_SIZE / 2,
                      viewRect.origin.y + DOT_OFFSET_Y,
                      DOT_SIZE,
                      DOT_SIZE);
}

static inline CGRect recordLabelFrameIn(CGRect viewRect)
{
    return CGRectMake(viewRect.size.width / 2 + DOT_SIZE / 2 + RECORD_LABEL_OFFSET_X,
                      viewRect.origin.y + DOT_OFFSET_Y - (RECORD_LABEL_HEIGHT - DOT_SIZE) / 2,
                      RECORD_LABEL_WIDTH,
                      RECORD_LABEL_HEIGHT);
}

static inline CGRect helperLabelFrameIn(CGRect viewRect)
{
    return CGRectMake(viewRect.size.width - HELP_LABEL_HEIGHT - 5, // rotate
                      viewRect.origin.y, // rotate
                      HELP_LABEL_HEIGHT, // rotate
                      viewRect.size.height - viewRect.origin.y); // rotate
}

static inline CGRect buildFrameIn(CGRect viewRect)
{
    return CGRectMake(viewRect.size.width / 2 - RECORD_LABEL_WIDTH / 2,
                      viewRect.size.height - RECORD_LABEL_HEIGHT - 4,
                      RECORD_LABEL_WIDTH,
                      RECORD_LABEL_HEIGHT);
}




#endif /* OverlayHeader_h */

