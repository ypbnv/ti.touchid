/**
 * Appcelerator Titanium Mobile
 * Copyright (c) 2009-2016 by Appcelerator, Inc. All Rights Reserved.
 * Licensed under the terms of the Apache Public License
 * Please see the LICENSE included with this distribution for details.
 */
#import "TiProxy.h"
#import "KeychainItemWrapper.h"

@interface TiTouchidKeychainItemProxy : TiProxy {
@private
    KeychainItemWrapper *keychainItem;
    
    NSString *identifier;
    NSString *accessGroup;
    NSString *accessibilityMode;
    NSNumber *accessControlMode;
}

- (void)save:(id)value;

- (void)read:(id)unused;

- (void)reset:(id)unused;

@end
