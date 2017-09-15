#  Project WebXR Viewer: A VR and AR Project by Mozilla

Help Mozilla Research by taking part in Project WebXR Viewer, an augmented reality and virtual reality (together what we call "XR") viewer that lets you navigate to XR experiences just like websites.

## In this initial release, you can:

Browse to websites written using [WebXR](https://github.com/mozilla/webxr-polyfill/), a proposal for extending WebVR with AR support that will work across all XR devices.

Record and share videos taken of your web content in the real world.

To learn more about Project WebXR Viewer and other ways Mozilla is working to bring augmented reality, virtual reality, and mixed reality to the web, visit our website at [mixedreality.mozilla.com](https://mixedreality.mozilla.com/).

## Building the app for iOS 11

Building this app requires XCode 9 (beta 6 or newer) and an iPhone or iPad running at least iOS 11.

You do not need to run `pod install` as the cocoapods are currently checked into the repo.

The app will only build if your build target is an iOS 11 *device*, not the simulator. The symptom of this is a missing `CVMetalTextureRef` reference.

## Building your own WebXR apps

While your iOS device is cabled to your development machine, you can use Safari 11 or newer to connect developer tools via Safari's `Develop` menu.

It can be handy to change the default URL loaded by the app by changing the `WEB_URL` string in WebARKHeader.h to the URL of your local web server. 

