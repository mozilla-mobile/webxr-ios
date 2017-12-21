> **NOTE:** If there is anything in this document that is not clear, is incorrect, or that requires more detail, please file an issue on this repository. Also feel free to submit corrections or additional information via a pull request.

The WebXR Viewer for iOS uses Mozilla's own Telemetry service (developed for Firefox and Focus) for anonymous insight into usage of various app features. This event tracking is turned on by default for the WebXR Viewer for iOS (opt-out).

The app uses Mozilla's own framework linked into the WebXR Viewer and a [data collection service](https://wiki.mozilla.org/Telemetry) run by Mozilla. The framework is open source and MPL 2.0 licensed. It is hosted at [https://github.com/mozilla-mobile/telemetry-ios](https://github.com/mozilla-mobile/telemetry-ios). The WebXR Viewer pulls in an unmodified copy of the framework via [CocoaPods](https://cocoapods.org).

## Telemetry Pings

The Telemetry framework collects and sends two types of pings to Mozilla's Telemetry backend:

* A *Core Ping* with basic system info and usage times.
* An *Event Ping* with details about user preferences and UI actions with timestamps relative to the app start time.

The messages are also documented below in more detail of what is sent in each HTTP request. All messages are posted to a secure endpoint at `https://incoming.telemetry.mozilla.org`. They are all `application/json` HTTP `POST` requests. Details about the HTTP edge server can be found at [https://wiki.mozilla.org/CloudServices/DataPipeline/HTTPEdgeServerSpecification](https://wiki.mozilla.org/CloudServices/DataPipeline/HTTPEdgeServerSpecification).

### Core Ping

#### Request

```
tz:                 -240
sessions:           1
durations:          1
searches:
  suggestion.google: 13
  listitem.google:   7
  actionbar.google:  4
clientId:           610A1520-4D47-498E-B20F-F3B46216372B
profileDate:        17326
v:                  7
device:             iPad
defaultSearch:      unknown
locale:             en-US
seq:                1
os:                 iOS
osversion:          11.1
created:            2017-12-12
arch:               arm64
```

These parameters are documented at [https://firefox-source-docs.mozilla.org/toolkit/components/telemetry/telemetry/data/core-ping.html](https://firefox-source-docs.mozilla.org/toolkit/components/telemetry/telemetry/data/core-ping.html).

#### Response

If the ping was received successfully, the server responds with an HTTP `200` status code.

### Event Ping

#### Request

```
tz:            -240
seq:           1
os:            iOS
created:       1497026730320
clientId:      2AF1A5A8-29B3-44B0-9653-346B67811E99
osversion:     11.2
settings: {},
v:             1
events:
  [ 2147, action, app, foreground   ]
  [ 2213, action, app, background   ]
locale:        en-US
```

These parameters are documented at [https://firefox-source-docs.mozilla.org/toolkit/components/telemetry/telemetry/collection/events.html](https://firefox-source-docs.mozilla.org/toolkit/components/telemetry/telemetry/collection/events.html).

You can find the full list of Event Pings sent by Focus [here](https://github.com/mozilla-mobile/focus-ios/blob/master/Blockzilla/TelemetryIntegration.swift).

You can find the full list of Event Pings sent by Firefox for iOS [here](https://github.com/mozilla-mobile/firefox-ios/blob/master/Client/Telemetry/UnifiedTelemetry.swift).

#### Response

If the ping was received successfully, the server responds with an HTTP `200` status code.

## Events

The event ping contains a list of events ([see event format on readthedocs.io](https://firefox-source-docs.mozilla.org/toolkit/components/telemetry/telemetry/collection/events.html)) for the following actions:

### App Lifecycle

| Event                               | category | method     | object | value  |
|-------------------------------------|----------|------------|--------|--------|
| App is foregrounded (session start) | action   | foreground | app    |        |
| App is backgrounded (session end)   | action   | background | app    |        |

### WebXR

| Event                          | category | method    | object                  | value | extras               |
|--------------------------------|----------|-----------|-------------------------|-------|----------------------|
| Web page initialized WebXR API (ARKit initialized) | api | WebXR | init     |   |     | 

### Video and Photo

| Event                                                       | category | method     | object | value  |
|-------------------------------------------------------------|----------|------------|--------|--------|
| User started a video recording by holding the record button | action   | record_video_button | app    |        |
| User took a picture by tapping the record button            | action   | record_picture_button | app    |        |
| User ended a video recording by releasing the record button | action   | release_video_button | app    |        |


## Limits

* An event ping will not be sent until at least 3 events are recorded
* An event ping will contain up to but no more than 500 events
* No more than 40 pings per type (core/event) are stored on disk for upload at a later time
* No more than 100 pings are sent per day
