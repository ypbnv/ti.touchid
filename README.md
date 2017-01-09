# 🖐 Ti.TouchID [![Build Status](https://travis-ci.org/appcelerator-modules/ti.touchid.svg?branch=master)](https://travis-ci.org/appcelerator-modules/ti.touchid)

Summary
---------------
The Ti.TouchID module allows you to use Fingerprint authentication (iOS & Android) and Keychain access (iOS) 
using Appcelerator Titanium.

Requirements
---------------
- Titanium Mobile SDK 6.0.0.GA or later
- iOS 8.0 or later
- Xcode 8 or later

Features
---------------
- [x] Use the Fingerprint sensor of your device to authenticate
- [x] Store, read, update and delete items with the native iOS-keychain

Example
---------------
Please see the full-featured example in `iphone/example/app.js` and `android/example/app.js`.

Build from Source
---------------
- iOS: `appc ti build -p ios --build-only` from the `ios` directory
- Android: `appc ti build -p android --build-only` from the `android` directory

> Note: Please do not use the (deprecated) `build.py` for iOS and `ant` for Android anymore.
> Those are unified in the above appc-cli these days.

Author
---------------
Appcelerator

License
---------------
Apache 2.0

Contributing
---------------
Code contributions are greatly appreciated, please submit a new [pull request](https://github.com/appcelerator-modules/ti.touchid/pull/new/master)!
