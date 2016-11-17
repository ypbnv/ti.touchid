/**
 * Appcelerator Titanium Mobile
 * Copyright (c) 2009-2016 by Appcelerator, Inc. All Rights Reserved.
 * Licensed under the terms of the Apache Public License
 * Please see the LICENSE included with this distribution for details.
 *
 */
var TouchID = require("ti.touchid");
var win = Ti.UI.createWindow({
    backgroundColor: "#fff",
    layout: "vertical"
});

var keychainItem = TouchID.createKeychainItem({
    identifier: "mypassword",
    accessGroup: "<YOUR-TEAM-ID>.com.appc.touchidtest",
    promptMessage: "Authenticate to access service password",
    accessibilityMode: TouchID.ACCESSIBLE_WHEN_PASSCODE_SET_THIS_DEVICE_ONLY,
    accessControlMode: TouchID.ACCESS_CONTROL_TOUCH_ID_ANY
});

keychainItem.addEventListener("save", function(e) {
    if (!e.success) {
        Ti.API.error("Error saving to the keychain: " + e.error);
        return;
    }

    Ti.API.info("Successfully saved!");
    Ti.API.info(e);
});

keychainItem.addEventListener("read", function(e) {
    if (!e.success) {
        Ti.API.error("Error reading the keychain: " + e.error);
        return;
    }

    Ti.API.info("Successfully read!");
    Ti.API.info(e);
});

keychainItem.addEventListener("reset", function(e) {
    if (!e.success) {
        Ti.API.error("Error resetting the keychain: " + e.error);
        return;
    }

    Ti.API.info("Successfully resetted!");
});


var btnExists = Ti.UI.createButton({
    title: "Exists?",
    top: 40
});

btnExists.addEventListener("click", function() {
    Ti.API.info("Exists? " + keychainItem.exists());
});


var btnSave = Ti.UI.createButton({
    title: "Save password to keychain!",
    top: 40
});


btnSave.addEventListener("click", function() {
    keychainItem.save("s3cr3t_p4$$w0rd");
});

var btnRead = Ti.UI.createButton({
    title: "Read password from keychain",
    top: 40
});

btnRead.addEventListener("click", function() {
    keychainItem.read();
});


var btnDelete = Ti.UI.createButton({
    title: "Delete password from keychain",
    top: 40
});

btnDelete.addEventListener("click", function() {
    keychainItem.reset();
});

win.add(btnExists);
win.add(btnSave);
win.add(btnRead);
win.add(btnDelete);
win.open();
