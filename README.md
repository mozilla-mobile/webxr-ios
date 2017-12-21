#  Project WebXR Viewer: A VR and AR Project by Mozilla

Help Mozilla Research by taking part in Project WebXR Viewer, an augmented reality and virtual reality viewer that lets you navigate to XR experiences just like websites.

## In this initial release, you can:

Browse to websites written using [WebXR](https://github.com/mozilla/webxr-polyfill/), a proposal for extending WebVR with AR support that will work across all XR devices.

Record and share videos taken of your web content in the real world.

To learn more about Project WebXR Viewer and other ways Mozilla is working to bring augmented reality, virtual reality, and mixed reality to the web, visit our website at [mixedreality.mozilla.org](https://mixedreality.mozilla.org/).

## WARNING

This application is *not* intended to replace a fully featured web browser. It is meant only for experimenting with building WebXR applications.

## Building the app for iOS 11

Building this app requires XCode 9 (beta 6 or newer) and an iPhone or iPad running at least iOS 11.

Be sure to open the XRViewer.xcworkspace (not the project file) so that you get the cocoapods. You do not need to run `pod install` as the cocoapods are currently checked into the repo.

The app will only build if your build target is an iOS 11 *device*, not the simulator. The symptom of this is a missing `CVMetalTextureRef` reference.

For your development build, go to the project settings by clicking the project name in the "Project navigator" (usually the left most item in the left panel), selecting "Automatically manage signing" in the "Signing section", then choose your Team. You may need to add an account if you don't already have a team.

## Building your own WebXR apps

We have started a [WebXR polyfill](https://github.com/mozilla/webxr-polyfill/) that can use the ARKit to Javascript bridge exposed in this application. You can include that in any web page and use the example code in the same repository to get started building your own XR web applications. 

While your iOS device is cabled to your development machine, you can use Safari 11 or newer to connect developer tools via Safari's `Develop` menu.

It can be handy to change the default URL loaded by the app by changing the `WEB_URL` string in WebARKHeader.h to the URL of your local web server. 

## Telemetry and Data Collection

The WebXR Viewer for iOS uses Mozilla's own Telemetry service (developed for Firefox and Focus) for anonymous insight into usage of various app features. This event tracking is turned on by default for the WebXR Viewer for iOS (opt-out).

You can read more about how we use the Telemetry service [here](Telemetry.md).

## Getting involved

We encourage you to participate in this open source project. We love Pull Requests, Bug Reports, ideas, (security) code reviews or any kind of positive contribution. Please read the [Community Participation Guidelines](https://www.mozilla.org/en-US/about/governance/policies/participation/).

* Issues: [https://github.com/mozilla-mobile/webxr-ios/issues](https://github.com/mozilla-mobile/webxr-ios/issues)

* Slack: We are on the AFrame and WebVR slacks

## License

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/