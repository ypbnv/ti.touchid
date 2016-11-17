/**
 * Appcelerator Titanium Mobile
 * Copyright (c) 2009-2016 by Appcelerator, Inc. All Rights Reserved.
 * Licensed under the terms of the Apache Public License
 * Please see the LICENSE included with this distribution for details.
 */
#import "TiProxy.h"
#import "APSKeychainWrapper.h"

@interface TiTouchidKeychainItemProxy : TiProxy<APSKeychainWrapperDelegate> {
@private
    APSKeychainWrapper *keychainItem;
    
    NSString *identifier;
    NSString *accessGroup;
    NSString *accessibilityMode;
    NSNumber *accessControlMode;
}

/**
 Saves a new value to the keychain. The value is identified by it's keychain
 item identifier and an optional access-group.
 */
- (void)save:(id)value;

/**
 Reads an existing value from the keychain. The value is identified by it's
 keychain item identifier and an optional access-group.
 */
- (void)read:(id)unused;

/**
 Deletes a value from the keychain. The value is identified by it's
 keychain item identifier and an optional access-group.
 */
- (void)reset:(id)unused;

/**
 Checks if an item exists already.
 */
- (id)exists:(id)unused;

@end
