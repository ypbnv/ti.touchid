/**
 * Appcelerator Titanium Mobile
 * Copyright (c) 2009-2016 by Appcelerator, Inc. All Rights Reserved.
 * Licensed under the terms of the Apache Public License
 * Please see the LICENSE included with this distribution for details.
 * Author: Hans Knöchel / 2016-11-05
 *
 */
var win = Ti.UI.createWindow({
    backgroundColor: "#fff",
    layout: "vertical"
});

var btnSave = Ti.UI.createButton({
    title: "Save password to keychain",
    top: 40
});

// -- IMPORTANT --
// This prefix is required for device and production builds
// and will be ignored for simulator builds. It is the Team-ID 
// of your provisioning profile
var appIdentifierPrefix = "<YOU-APP-IDENTIFIER-PREFIX>";

btnSave.addEventListener("click", function() {
    var TouchID = require("ti.touchid");

    TouchID.saveValueToKeychain({
        identifier: "password",
        accessGroup: appIdentifierPrefix + ".com.appc.touchidtest",
        value: "s3cr3t_p4$$w0rd",
        callback: function(e) {
            if (!e.success) {
                Ti.API.error("Error: " + e.error + " (Code: " + e.code + ")");
                return;
            }
            Ti.API.info("Success!");
            Ti.API.info(e);
        },
    });
});

var btnRead = Ti.UI.createButton({
    title: "Read password from keychain",
    top: 40
});

btnRead.addEventListener("click", function() {
    var TouchID = require("ti.touchid");

    TouchID.readValueFromKeychain({
        identifier: "password",
        accessGroup: appIdentifierPrefix + ".com.appc.touchidtest",
        callback: function(e) {
            if (!e.success) {
                Ti.API.error("Error! Probably the keychain item does not exist");
                return;
            }
            Ti.API.info("Success!");
            Ti.API.info(e);
        },
    });
});


var btnDelete = Ti.UI.createButton({
    title: "Delete password from keychain",
    top: 40
});

btnDelete.addEventListener("click", function() {
    var TouchID = require("ti.touchid");

    TouchID.deleteValueFromKeychain({
        identifier: "password",
        accessGroup: appIdentifierPrefix + ".com.appc.touchidtest",
    });
    
    Ti.API.info("Deleted keychain item!");
});

win.add(btnSave);
win.add(btnRead);
win.add(btnDelete);
win.open();
