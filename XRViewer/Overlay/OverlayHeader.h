#ifndef OverlayHeader_h
#define OverlayHeader_h

#import <UIKit/UIKit.h>
#import "AppState.h"

#define RECORD_LONG_TAP_DURATION 1
#define SHOW_ERROR_RECORDING_LABEL_DURATION 3
#define ANIMATION_DURATION 0.5

typedef void (^HotAction)(BOOL); // long

#define screenKoef 2
// RECORD BTN
#define FULL_SIZE       126.0/screenKoef
#define NORMAL_SIZE     99.0/screenKoef
#define SELECTED_SIZE   54.0/screenKoef
#define SELECTED_RADIUS 10.0/screenKoef
#define RING_WIDTH      10.0/screenKoef


#define RECORD_SIZE FULL_SIZE
#define RECORD_OFFSET 45.0/screenKoef

#define MIC_SIZE 74/screenKoef
#define MIC_OFFSET 25/screenKoef
#define MIC_RING_WIDTH 4/screenKoef
#define MIC_INNER_OFFSET 15/screenKoef

#define RECORD_LABEL_OFFSET 30/screenKoef
#define RECORD_LABEL_WIDTH 246/screenKoef
#define RECORD_LABEL_HEIGHT 45/screenKoef


#define RECORD_OFFSET_Y 25.5

#define TRACK_SIZE_W 78
#define TRACK_SIZE_H 22

#define DOT_SIZE 12
#define DOT_OFFSET_Y 9.5

#define RECORD_LABEL_OFFSET_X 4.5

#define URL_BAR_HEIGHT 49

#warning LOCALIZATION
#define HELP_TEXT(application) (application == Graffiti ? nil : @"Tap for photo, hold for video")
#define ERROR_TEXT    @"Some error has occurred while capturing"
#define DISABLED_TEXT @"Сapturing is disabled now"
#define GRANT_TEXT    @"Provide access to camera to make photos / videos"

#define HELP_LABEL_HEIGHT 16
#define HELP_LABEL_WIDTH 350



static inline CGRect recordFrameIn(CGRect viewRect, Application app)
{
    if (app == Graffiti)
    {
        return CGRectMake(viewRect.size.width - RECORD_SIZE - RECORD_OFFSET,
                          viewRect.size.height / 2 - RECORD_SIZE / 2,
                          RECORD_SIZE,
                          RECORD_SIZE);
    }
    
    return CGRectMake(viewRect.size.width - RECORD_SIZE - RECORD_OFFSET,
                      viewRect.origin.y + (viewRect.size.height - viewRect.origin.y) / 2 - RECORD_SIZE / 2,
                      RECORD_SIZE,
                      RECORD_SIZE);
}

static inline CGRect micFrameIn(CGRect viewRect, Application app)
{
    if (app == Graffiti)
    {
        return CGRectMake(MIC_OFFSET,
                          viewRect.size.height - MIC_OFFSET - MIC_SIZE,
                          MIC_SIZE,
                          MIC_SIZE);
    }
    
    return CGRectMake(viewRect.size.width - RECORD_SIZE - RECORD_OFFSET + (RECORD_SIZE - MIC_SIZE) / 2,
                      viewRect.origin.y + RECORD_OFFSET_Y,
                      MIC_SIZE,
                      MIC_SIZE);
}

static inline CGRect recordLabelFrameIn(CGRect viewRect, Application app)
{
    return CGRectMake(viewRect.size.width / 2 - RECORD_LABEL_WIDTH / 2,
                      RECORD_LABEL_OFFSET,
                      RECORD_LABEL_WIDTH,
                      RECORD_LABEL_HEIGHT);
}

static inline CGRect helperLabelFrameIn(CGRect viewRect, Application app)
{
    return CGRectMake(viewRect.size.width - HELP_LABEL_HEIGHT - 2, // rotate
                      viewRect.origin.y, // rotate
                      HELP_LABEL_HEIGHT, // rotate
                      viewRect.size.height - viewRect.origin.y); // rotate
}

static inline CGRect debugFrameIn(CGRect viewRect, Application app)
{
    if (app == Graffiti)
    {
        return CGRectZero;
    }
    
    return CGRectMake(RECORD_OFFSET,
                      viewRect.size.height - RECORD_OFFSET_Y - MIC_SIZE,
                      MIC_SIZE,
                      MIC_SIZE);
}

static inline CGRect showFrameIn(CGRect viewRect, Application app)
{
    if (app == Graffiti)
    {
        return CGRectZero;
    }
    
    return CGRectMake(viewRect.size.width - RECORD_OFFSET - MIC_SIZE,
                      viewRect.size.height - RECORD_OFFSET_Y - MIC_SIZE,
                      MIC_SIZE,
                      MIC_SIZE);
}

static inline CGRect trackFrameIn(CGRect viewRect, Application app)
{
    if (app == Graffiti)
    {
        return CGRectZero;
    }
    
    return CGRectMake(viewRect.size.width / 2 - TRACK_SIZE_W / 2,
                      viewRect.size.height - RECORD_OFFSET_Y - MIC_SIZE / 2 - TRACK_SIZE_H / 2,
                      TRACK_SIZE_W,
                      TRACK_SIZE_H);
}

static inline CGRect buildFrameIn(CGRect viewRect, Application app)
{
    if (app == Graffiti)
    {
        return CGRectZero;
    }
    
    return CGRectMake(viewRect.size.width / 2 - RECORD_LABEL_WIDTH / 2,
                      viewRect.size.height - RECORD_LABEL_HEIGHT - 4,
                      RECORD_LABEL_WIDTH,
                      RECORD_LABEL_HEIGHT);
}




#endif /* OverlayHeader_h */

