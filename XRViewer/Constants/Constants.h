//
//  Constants.h
//  XRViewer
//
//  Created by Roberto Garrido on 20/12/17.
//  Copyright © 2017 Mozilla. All rights reserved.
//

#ifndef Constants_h
#define Constants_h

#import <Foundation/Foundation.h>

/// The NSUserDefaults key for the boolean that tells us whether
/// the permissions UI was already shown
FOUNDATION_EXPORT NSString *const permissionsUIAlreadyShownKey;
/// The NSUserDefaults key for the boolean that tells us whether
/// the AnalyticsManager should be used
FOUNDATION_EXPORT NSString *const useAnalyticsKey;
/// The NSUserDefaults key for the string of the default home url
FOUNDATION_EXPORT NSString *const homeURLKey;
/// The NSUserDefaults key for the NSNumber telling us the seconds
/// the app should be in background before pausing the session
FOUNDATION_EXPORT NSString *const secondsInBackgroundKey;
/// The default time in seconds that the app waits after leaving a
/// XR site before pausing the session
FOUNDATION_EXPORT int const sessionInBackgroundDefaultTimeInSeconds;
/// The NSUserDefaults key for the NSNumber telling us the minimum
/// distance at which the anchors should be in order to be removed
/// on a page refresh
FOUNDATION_EXPORT NSString *const distantAnchorsDistanceKey;
/// The dfeault distance at which the anchors should be in order to be
/// removed on a page refresh
FOUNDATION_EXPORT float const distantAnchorsDefaultDistanceInMeters;
/// The NSUserDefaults key for the Date telling us when the app was
/// backgrounded or the session paused
FOUNDATION_EXPORT NSString *const backgroundOrPausedDateKey;
/// The default time the session must be paused in order to remove the
/// anchors on the next session run
FOUNDATION_EXPORT double const pauseTimeInSecondsToRemoveAnchors;

#endif /* Constants_h */
