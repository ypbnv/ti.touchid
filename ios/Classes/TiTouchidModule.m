/**
 * Appcelerator Titanium Mobile
 * Copyright (c) 2009-2014 by Appcelerator, Inc. All Rights Reserved.
 * Licensed under the terms of the Apache Public License
 * Please see the LICENSE included with this distribution for details.
 *
 */

#import <LocalAuthentication/LocalAuthentication.h>

#import "TiTouchidModule.h"
#import "TiBase.h"
#import "TiHost.h"
#import "TiUtils.h"
#import "KeychainItemWrapper.h"

@implementation TiTouchidModule

#pragma mark Internal

- (id)moduleGUID
{
	return @"0ee4118b-68f9-47c6-8c37-d68778ecb806";
}

- (NSString*)moduleId
{
	return @"ti.touchid";
}

#pragma mark Lifecycle

- (void)startup
{
	[super startup];
}

- (void)shutdown:(id)sender
{
	[super shutdown:sender];
}

#pragma mark Cleanup 

- (void)dealloc
{
	[super dealloc];
}

#pragma mark Public API

- (NSNumber*)isSupported:(id)unused
{
    if (![TiUtils isIOS8OrGreater]) {
        return NUMBOOL(NO);
    }
    
    LAContext *context = [[LAContext new] autorelease];
    __block BOOL isSupported = NO;
    
    TiThreadPerformOnMainThread(^{
        isSupported = [context canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics error:nil];
    },YES);
    
    return NUMBOOL(isSupported);
}

- (void)saveToKeychain:(id)args
{
    NSDictionary *items;
    NSString *identifier;
    NSString *accessGroup;
    KrollCallback *successCallback;
    KrollCallback *errorCallback;
    BOOL authorizationRequired = [TiUtils boolValue:[args objectForKey:@"authorizationRequired"] def:NO];
    
    ENSURE_ARG_FOR_KEY(items, args, @"items", NSDictionary);
    ENSURE_ARG_FOR_KEY(successCallback, args, @"success", KrollCallback);
    ENSURE_ARG_FOR_KEY(errorCallback, args, @"error", KrollCallback);
    ENSURE_ARG_FOR_KEY(identifier, args, @"identifier", NSString);
    ENSURE_ARG_OR_NIL_FOR_KEY(accessGroup, args, @"accessGroup", NSString);
    
    if (authorizationRequired) {
        // TODO: Show auth-dialog before
    }
    
    KeychainItemWrapper *wrapper = [[KeychainItemWrapper alloc] initWithIdentifier:identifier
                                                                       accessGroup:accessGroup];
    
    for (NSString *key in [items allKeys]) {
        [wrapper setObject:[items objectForKey:key] forKey:key];
    }
    
    RELEASE_TO_NIL(wrapper);
    
    NSDictionary * propertiesDict = @{@"success": NUMBOOL(YES)};
    NSArray * invocationArray = [[NSArray alloc] initWithObjects:&propertiesDict count:1];
    
    [successCallback call:invocationArray thisObject:self];
    [invocationArray release];
}

- (void)readFromKeychain:(id)args
{
    NSArray *items;
    NSString *identifier;
    NSString *accessGroup;
    KrollCallback *successCallback;
    KrollCallback *errorCallback;
    BOOL authorizationRequired = [TiUtils boolValue:[args objectForKey:@"authorizationRequired"] def:NO];

    ENSURE_ARG_FOR_KEY(items, args, @"items", NSArray);
    ENSURE_ARG_FOR_KEY(successCallback, args, @"success", KrollCallback);
    ENSURE_ARG_FOR_KEY(errorCallback, args, @"error", KrollCallback);
    ENSURE_ARG_FOR_KEY(identifier, args, @"identifier", NSString);
    ENSURE_ARG_OR_NIL_FOR_KEY(accessGroup, args, @"accessGroup", NSString);
    
    if (authorizationRequired) {
        // TODO: Show auth-dialog before
    }
    
    KeychainItemWrapper *wrapper = [[KeychainItemWrapper alloc] initWithIdentifier:identifier
                                                                       accessGroup:accessGroup];
    
    NSMutableDictionary *result = [NSMutableDictionary dictionary];
    
    for (NSString *key in items) {
        [result setObject:[wrapper objectForKey:key] forKey:key];
    }
    
    RELEASE_TO_NIL(wrapper);

    NSDictionary * propertiesDict = @{@"success": NUMBOOL(YES), @"items": result};
    NSArray * invocationArray = [[NSArray alloc] initWithObjects:&propertiesDict count:1];
    
    [successCallback call:invocationArray thisObject:self];
    [invocationArray release];
}

- (void)resetKeychain:(id)args
{
    NSString *identifier;
    NSString *accessGroup;
    BOOL authorizationRequired = [TiUtils boolValue:[args objectForKey:@"authorizationRequired"] def:NO];

    ENSURE_ARG_FOR_KEY(identifier, args, @"identifier", NSString);
    ENSURE_ARG_OR_NIL_FOR_KEY(accessGroup, args, @"accessGroup", NSString);

    if (authorizationRequired) {
        // TODO: Show auth-dialog before
    }
    
    KeychainItemWrapper *wrapper = [[KeychainItemWrapper alloc] initWithIdentifier:identifier
                                                                       accessGroup:accessGroup];
    
    [wrapper resetKeychainItem];
    RELEASE_TO_NIL(wrapper);
}

/**
 * To be used this way:
 *
 * var TiTouchId = require('ti.touchid');
 *	
 * TiTouchId.authenticate({
 *     reason: 'We need your fingerprint to continue.',
 *     callback: function(e) {
 *         if (!e.success) {
 *             alert('Message: ' + e.error + '\nCode: ' + e.code);
 *         } else {
 *             // do something useful
 *         }
 *     }
 * });
 */
- (void)authenticate:(id)args
{
	ENSURE_SINGLE_ARG(args, NSDictionary);
	NSString *reason = [TiUtils stringValue:[args valueForKey:@"reason"]];
	KrollCallback *callback = [args valueForKey:@"callback"];

	if(![callback isKindOfClass:[KrollCallback class]]) {
		NSLog(@"[WARN] Ti.TouchID: \"callback\" must be a function");
		return;
	}
	if(![[self isSupported:nil] boolValue]) {
		TiThreadPerformOnMainThread(^{
			NSMutableDictionary *event = [NSMutableDictionary dictionary];
			[event setValue:@"This API is only available in iOS 8 and above" forKey:@"error"];
			[event setValue:[self ERROR_TOUCH_ID_NOT_AVAILABLE] forKey:@"code"];
			[event setValue:NUMBOOL(NO) forKey:@"success"];
			[callback call:[NSArray arrayWithObjects:event, nil] thisObject:self];
		}, NO);
		return;
	}
	LAContext *myContext = [[[LAContext alloc] init] autorelease];
	NSError *authError = nil;
	
	if ([myContext canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics error:&authError]) {
		// Make sure this runs on the main thread, for two reasons:
		// 1. This will show an alert dialog, which is a UI component
		// 2. The callback function (KrollCallback) needs to run on main thread
		TiThreadPerformOnMainThread(^{
			[myContext evaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics localizedReason:reason reply:^(BOOL succes, NSError *error) {
			 NSMutableDictionary *event = [NSMutableDictionary dictionary];
			 if(error != nil) {
				 [event setValue:[error localizedDescription] forKey:@"error"];
				 [event setValue:NUMINTEGER([error code]) forKey:@"code"];
			 }
			 [event setValue:NUMBOOL(succes) forKey:@"success"];
			 [callback call:[NSArray arrayWithObjects:event, nil] thisObject:self];
		 }];
		}, NO);
		return;
	}
	
	// Again, make sure the callback function runs on the main thread
	TiThreadPerformOnMainThread(^{
		NSMutableDictionary *event = [NSMutableDictionary dictionary];
		if(authError != nil) {
			[event setValue:[authError localizedDescription] forKey:@"error"];
			[event setValue:NUMINTEGER([authError code]) forKey:@"code"];
		} else {
			[event setValue:@"Can not evaluate Touch ID" forKey:@"error"];
			[event setValue:NUMINT(0.0) forKey:@"code"];
		}
		[event setValue:NUMBOOL(NO) forKey:@"success"];
		[callback call:[NSArray arrayWithObjects:event, nil] thisObject:self];
	}, NO);
}

- (NSDictionary*)deviceCanAuthenticate:(id)args
{
	if(![TiUtils isIOS8OrGreater]) {
		NSDictionary * versionResult = [NSDictionary dictionaryWithObjectsAndKeys:
						@"This API is only available in iOS 8 and above",@"error",
						[self ERROR_TOUCH_ID_NOT_AVAILABLE],@"code",
						NUMBOOL(NO),@"canAuthenticate",nil];
		return versionResult;
	}
	LAContext *myContext = [[[LAContext alloc] init] autorelease];
	NSError *authError = nil;
	BOOL canAuthenticate = [myContext canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics error:&authError];
	NSMutableDictionary *result = [NSMutableDictionary dictionary];
	if(authError != nil) {
		[result setValue:[TiUtils messageFromError:authError] forKey:@"error"];
		[result setValue:NUMINTEGER([authError code]) forKey:@"code"];
	}
	[result setValue:NUMBOOL(canAuthenticate) forKey:@"canAuthenticate"];
	return result;
}

#pragma mark Constants

- (NSNumber*)ERROR_AUTHENTICATION_FAILED
{
	if([TiUtils isIOS8OrGreater]) {
		return NUMINT(LAErrorAuthenticationFailed);
	}
	return NUMINT(-1);
}

- (NSNumber*)ERROR_USER_CANCEL
{
	if([TiUtils isIOS8OrGreater]) {
		return NUMINT(LAErrorUserCancel);
	}
	return NUMINT(-2);
}

- (NSNumber*)ERROR_USER_FALLBACK
{
	if([TiUtils isIOS8OrGreater]) {
		return NUMINT(LAErrorUserFallback);
	}
	return NUMINT(-3);
}

- (NSNumber*)ERROR_SYSTEM_CANCEL
{
	if([TiUtils isIOS8OrGreater]) {
		return NUMINT(LAErrorSystemCancel);
	}
	return NUMINT(-4);
}

- (NSNumber*)ERROR_PASSCODE_NOT_SET
{
	if([TiUtils isIOS8OrGreater]) {
		return NUMINT(LAErrorPasscodeNotSet);
	}
	return NUMINT(-5);
}

- (NSNumber*)ERROR_TOUCH_ID_NOT_AVAILABLE
{
	if([TiUtils isIOS8OrGreater]) {
		return NUMINT(LAErrorTouchIDNotAvailable);
	}
	return NUMINT(-6);
}

- (NSNumber*)ERROR_TOUCH_ID_NOT_ENROLLED
{
	if([TiUtils isIOS8OrGreater]) {
		return NUMINT(LAErrorTouchIDNotEnrolled);
	}
	return NUMINT(-7);
}

- (NSNumber*)ERROR_APP_CANCELLED
{
    if([TiUtils isIOS9OrGreater]) {
        return NUMINT(LAErrorAppCancel);
    }
    return NUMINT(-8);
}

- (NSNumber*)ERROR_INVALID_CONTEXT
{
    if([TiUtils isIOS9OrGreater]) {
        return NUMINT(LAErrorInvalidContext);
    }
    return NUMINT(-9);
}

- (NSNumber*)ERROR_TOUCH_ID_LOCKOUT
{
    if([TiUtils isIOS9OrGreater]) {
        return NUMINT(LAErrorTouchIDLockout);
    }
    return NUMINT(-10);
}
@end

