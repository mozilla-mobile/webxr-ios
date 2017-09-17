#  Project WebXR Viewer: A VR and AR Project by Mozilla

Help Mozilla Research by taking part in Project WebXR Viewer, an augmented reality and virtual reality viewer that lets you navigate to XR experiences just like websites.

## In this initial release, you can:

Browse to websites written using [WebXR](https://github.com/mozilla/webxr-polyfill/), a proposal for extending WebVR with AR support that will work across all XR devices.

Record and share videos taken of your web content in the real world.

To learn more about Project WebXR Viewer and other ways Mozilla is working to bring augmented reality, virtual reality, and mixed reality to the web, visit our website at [mixedreality.mozilla.com](https://mixedreality.mozilla.com/).

## WARNING

This application is *not* intended to replace a fully featured web browser. It is meant only for experimenting with building WebXR applications.

## Building the app for iOS 11

Building this app requires XCode 9 (beta 6 or newer) and an iPhone or iPad running at least iOS 11.

You do not need to run `pod install` as the cocoapods are currently checked into the repo.

The app will only build if your build target is an iOS 11 *device*, not the simulator. The symptom of this is a missing `CVMetalTextureRef` reference.

For your development build, go to the project settings by clicking the project name in the "Project navigator" (usually the left most item in the left panel), selecting "Automatically manage signing" in the "Signing section", then choose your Team. You may need to add an account if you don't already have a team.

## Building your own WebXR apps

We have started a [WebXR polyfill](https://github.com/mozilla/webxr-polyfill/) that can use the ARKit to Javascript bridge exposed in this application. You can include that in any web page and use the example code in the same repository to get started building your own XR web applications. 

While your iOS device is cabled to your development machine, you can use Safari 11 or newer to connect developer tools via Safari's `Develop` menu.

It can be handy to change the default URL loaded by the app by changing the `WEB_URL` string in WebARKHeader.h to the URL of your local web server. 

