#  Project WebXR Viewer: An AR Project by Mozilla

Help Mozilla Research by taking part in Project WebXR Viewer, an augmented reality viewer that lets you navigate to AR experiences just like websites, using Apple/iOS ARKit for it's AR capabilities.  

The master branch of this repository is built and availble in the iOS App Store as the [WebXR Viewer](https://itunes.apple.com/us/app/webxr-viewer/id1295998056?mt=8).

## WARNING: Experimental Exploration of the Future of WebXR

This experimental browser lets your navigate to websites written using [our non-standard, experimental version of the WebXR API](https://github.com/mozilla/webxr-polyfill/).  The version of WebXR implemented by this application (the javascript library) is based on a [proposed draft proposal for WebXR](https://github.com/mozilla/webxr-api) we created as a starting point for discussing WebXR in the fall of 2017, to explore what it might mean to expand WebVR to include AR/MR capabilities.

The WebVR community has shifted from WebVR to WebXR, and is now called the [Immersive Web Community Group](https://github.com/immersive-web/), with the WebVR specification becoming the [WebXR Device API](https://github.com/immersive-web/webxr). You should consider that spec as ground-truth for the future of WebXR, and it is what you will likely see appearing in browsers through the rest of 2018 and into 2019.

When the spec has settled and is more mature, we will shift this app and [our version of WebXR](https://github.com/mozilla/webxr-polyfill/) to align with it.  

To learn more about the WebXR Viewer and other ways Mozilla is working to bring augmented reality, virtual reality, and mixed reality to the web, visit our website at [mixedreality.mozilla.org](https://mixedreality.mozilla.org/).

## WARNING

This application is *not* intended to replace a fully featured web browser. It is meant only for experimenting with experimenting with WebXR applications on iOS.

## Building the app for iOS 11

Building this app requires XCode 9 (beta 6 or newer) and an iPhone or iPad running at least iOS 11.

Before opening XCode, update cocoapods by running:

	cd webxr-ios
	pod repo update
	pod install

Then use XCode to open webxr-ios/XRViewer.xcworkspace (not the project file) so that you get the cocoapods.

The app will only build if your build target is an iOS 11 *device*, not the simulator. The symptom of this is a missing `CVMetalTextureRef` reference.

For your development build, go to the project settings by clicking the project name in the "Project navigator" (usually the left most item in the left panel), selecting "Automatically manage signing" in the "Signing section", then choose your Team. You may need to add an account if you don't already have a team.

## Building your own WebXR apps

Our experimental [WebXR polyfill](https://github.com/mozilla/webxr-polyfill/) can be used to write apps that leverage ARKit in this application. You can include that in any web page and use the example code in the same repository to get started building your own XR web applications. 

If you build this app yourself, you can use Safari 11 or newer to connect developer tools via Safari's `Develop` menu.

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
