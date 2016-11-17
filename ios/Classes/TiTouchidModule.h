/**
 * Appcelerator Titanium Mobile
 * Copyright (c) 2009-2014 by Appcelerator, Inc. All Rights Reserved.
 * Licensed under the terms of the Apache Public License
 * Please see the LICENSE included with this distribution for details.
 *
 */

#import "TiModule.h"

@interface TiTouchidModule : TiModule {
    LAContext *authContext;
}

/**
 Determines if the current device supports Touch ID.
 @return YES if the current device supports Touch ID, NO otherwise.
 */
- (NSNumber*)isSupported:(id)unused;

/**
 Authenticates the user.
 */
- (void)authenticate:(id)args;

/**
 Invalidates the currently displayed Touch ID dialog if existing.
 */
- (void)invalidate:(id)unused;

/**
 Determines if the current device currently can authenticate with Touch ID.
 @return `NSDictionary` that contains infos about the device authentication.
 */
- (NSDictionary*)deviceCanAuthenticate:(id)unused;

@end
