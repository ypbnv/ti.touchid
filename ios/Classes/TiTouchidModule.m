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

- (void)dealloc
{
    RELEASE_TO_NIL(authContext);
    [super dealloc];
}

- (LAContext*)authContext
{
    if (!authContext) {
        authContext = [LAContext new];
        [authContext setTouchIDAuthenticationAllowableReuseDuration:(NSTimeInterval)240];

    }
    
    return authContext;
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

- (void)saveValueToKeychain:(id)args
{
    ENSURE_SINGLE_ARG(args, NSDictionary);
    
    NSString *value;
    KrollCallback *callback;
    
    ENSURE_ARG_FOR_KEY(value, args, @"value", NSString);
    ENSURE_ARG_FOR_KEY(callback, args, @"callback", KrollCallback);
    
    KeychainItemWrapper *wrapper = [[self keychainItemWrapperFromArgs:args] retain];
    [wrapper setObject:value forKey:(id)kSecValueData];
    
    RELEASE_TO_NIL(wrapper);
    
    NSDictionary * propertiesDict = @{@"success": NUMBOOL(YES)};
    NSArray * invocationArray = [[NSArray alloc] initWithObjects:&propertiesDict count:1];
    
    [callback call:invocationArray thisObject:self];
    [invocationArray release];
}

- (void)readValueFromKeychain:(id)args
{
    ENSURE_SINGLE_ARG(args, NSDictionary);

    KrollCallback *callback;
    ENSURE_ARG_FOR_KEY(callback, args, @"callback", KrollCallback);
    
    KeychainItemWrapper *wrapper = [[self keychainItemWrapperFromArgs:args] retain];
    
    NSString *value = [[wrapper objectForKey:(id)kSecValueData] retain];    
    NSDictionary * propertiesDict = @{@"success": NUMBOOL(value.length > 0), @"value": value ?: @""};
    NSArray * invocationArray = [[NSArray alloc] initWithObjects:&propertiesDict count:1];
    
    if ([value length] == 0) {
        [callback call:invocationArray thisObject:self];
    } else {
        [callback call:invocationArray thisObject:self];
    }
    
    [invocationArray release];
    RELEASE_TO_NIL(wrapper);
    RELEASE_TO_NIL(value);
}

- (void)deleteValueFromKeychain:(id)args
{
    ENSURE_SINGLE_ARG(args, NSDictionary);
    
    KeychainItemWrapper *wrapper = [[self keychainItemWrapperFromArgs:args] retain];
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
    NSDictionary *isSupportedDict = [self deviceCanAuthenticate:nil];
	KrollCallback *callback = [args valueForKey:@"callback"];
    id maxBiometryFailures = [args valueForKey:@"maxBiometryFailures"];
    id allowableReuseDuration = [args valueForKey:@"allowableReuseDuration"];
    id fallbackTitle = [args valueForKey:@"fallbackTitle"];
    id cancelTitle = [args valueForKey:@"cancelTitle"];
    
	if(![callback isKindOfClass:[KrollCallback class]]) {
		NSLog(@"[WARN] Ti.TouchID: The parameter `callback` in `authenticate` must be a function.");
		return;
	}
    
    // Fail when Touch ID is not supported by the current device
	if([isSupportedDict valueForKey:@"canAuthenticate"] == NUMBOOL(NO)) {
        TiThreadPerformOnMainThread(^{
            NSDictionary *event = @{
                @"error": [isSupportedDict valueForKey:@"error"],
                @"code": [isSupportedDict valueForKey:@"code"],
                @"success": NUMBOOL(NO)
            };

            [callback call:[NSArray arrayWithObjects:event, nil] thisObject:self];
        }, NO);
		return;
	}
    
	NSError *authError = nil;
    

#if IS_XCODE_8
    // iOS 10: Expose support for localized titles
    if ([TiUtils isIOS10OrGreater]) {
        if (fallbackTitle) {
            [[self authContext] setLocalizedFallbackTitle:[TiUtils stringValue:fallbackTitle]];
        }
        
        if (cancelTitle) {
            [[self authContext] setLocalizedCancelTitle:[TiUtils stringValue:cancelTitle]];
        }
    }
#endif

    // Display the dialog if the security policy allows it (= device has Touch ID enabled)
	if ([[self authContext] canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics error:&authError]) {
		// Make sure this runs on the main thread, for two reasons:
		// 1. This will show an alert dialog, which is a UI component
		// 2. The callback function (KrollCallback) needs to run on main thread
		TiThreadPerformOnMainThread(^{
			[[self authContext] evaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics localizedReason:reason reply:^(BOOL success, NSError *error) {
			 NSMutableDictionary *event = [NSMutableDictionary dictionary];
			 if(error != nil) {
				 [event setValue:[error localizedDescription] forKey:@"error"];
				 [event setValue:NUMINTEGER([error code]) forKey:@"code"];
			 }
			 [event setValue:NUMBOOL(success) forKey:@"success"];
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

- (void)invalidate:(id)unused
{
    if (![TiUtils isIOS9OrGreater]) {
        NSLog(@"[ERROR] Ti.TouchID: The method `invalidate` is only available in iOS 9 and later.");
        return;
    }

    if (![self authContext]) {
        NSLog(@"[ERROR] Ti.TouchID: Cannot invalidate a Touch ID instance that does not exist. Use 'authenticate' before calling this.");
        return;
    }
    
    [[self authContext] invalidate];
}

- (NSDictionary*)deviceCanAuthenticate:(id)unused
{
	if (![TiUtils isIOS8OrGreater]) {
        return @{
            @"error":@"The method `deviceCanAuthenticate` is only available in iOS 8 and later.",
            @"code": [self ERROR_TOUCH_ID_NOT_AVAILABLE],
            @"canAuthenticate": NUMBOOL(NO)
        };
	}
    
	NSError *authError = nil;
	BOOL canAuthenticate = [[self authContext] canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics error:&authError];
    NSMutableDictionary *result = [NSMutableDictionary dictionaryWithDictionary:@{
        @"canAuthenticate": NUMBOOL(canAuthenticate)
    }];
	
    if (authError != nil) {
		[result setValue:[TiUtils messageFromError:authError] forKey:@"error"];
		[result setValue:NUMINTEGER([authError code]) forKey:@"code"];
	}
	
    return result;
}

+ (SecAccessControlCreateFlags)accessControlFlagsFromArgs:(id)args
{
    id accessControlMode = [args objectForKey:@"accessControlMode"];
    id accessibilityMode = [args objectForKey:@"accessibilityMode"];
    
    SecAccessControlCreateFlags optionFlags = kSecAccessControlUserPresence;
    
    if (accessControlMode) {
        if (!accessibilityMode) {
            NSLog(@"[ERROR] Ti.TouchID: When using `accessControlMode` you must also specify the `accessibilityMode` property.");
        } else if ([accessControlMode isKindOfClass:[NSNumber class]]) {
            optionFlags = accessControlMode;
        } else if ([accessControlMode isKindOfClass:[NSArray class]]) {
            for (id flag in accessControlMode) {
                ENSURE_TYPE(flag, NSNumber); // flags are of type "SecAccessControlCreateFlags", which is "CFOptionFlags", which is "long", which is "NSNumber"
                optionFlags |= (SecAccessControlCreateFlags)flag;
            }
        } else {
            NSLog(@"[WARN] Ti.TouchID: The property \"accessControlMode\" must either be a single constant or a logic concatination of multiple constants.");
            NSLog(@"[WARN] Ti.TouchID: Falling back to default `ACCESS_CONTROL_USER_PRESENCE`");
        }
    }
    
    return optionFlags;
}

- (KeychainItemWrapper*)keychainItemWrapperFromArgs:(id)args
{
    NSString *identifier;
    NSString *accessGroup;
    NSString *accessibilityMode;
    
    ENSURE_ARG_FOR_KEY(identifier, args, @"identifier", NSString);
    ENSURE_ARG_OR_NIL_FOR_KEY(accessGroup, args, @"accessGroup", NSString);
    ENSURE_ARG_OR_NIL_FOR_KEY(accessibilityMode, args, @"accessibilityMode", NSString);
    
    return [[[KeychainItemWrapper alloc] initWithIdentifier:identifier
                                                accessGroup:accessGroup
                                          accessibilityMode:(CFStringRef)accessibilityMode
                                          accessControlMode:[TiTouchidModule accessControlFlagsFromArgs:args]] autorelease];
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

MAKE_SYSTEM_STR(ACCESSIBLE_WHEN_UNLOCKED, kSecAttrAccessibleWhenUnlocked);
MAKE_SYSTEM_STR(ACCESSIBLE_AFTER_FIRST_UNLOCK, kSecAttrAccessibleAfterFirstUnlock);
MAKE_SYSTEM_STR(ACCESSIBLE_ALWAYS, kSecAttrAccessibleAlways);
MAKE_SYSTEM_STR(ACCESSIBLE_WHEN_PASSCODE_SET_THIS_DEVICE_ONLY, kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly);
MAKE_SYSTEM_STR(ACCESSIBLE_WHEN_UNLOCKED_THIS_DEVICE_ONLY, kSecAttrAccessibleWhenUnlockedThisDeviceOnly);
MAKE_SYSTEM_STR(ACCESSIBLE_AFTER_FIRST_UNLOCK_THIS_DEVICE_ONLY, kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly);
MAKE_SYSTEM_STR(ACCESSIBLE_ALWAYS_THIS_DEVICE_ONLY, kSecAttrAccessibleAlwaysThisDeviceOnly);

MAKE_SYSTEM_STR(ACCESS_CONTROL_USER_PRESENCE, kSecAccessControlUserPresence);
MAKE_SYSTEM_STR(ACCESS_CONTROL_TOUCH_ID_ANY, kSecAccessControlTouchIDAny);
MAKE_SYSTEM_STR(ACCESS_CONTROL_TOUCH_ID_CURRENT_SET, kSecAccessControlTouchIDCurrentSet);
MAKE_SYSTEM_STR(ACCESS_CONTROL_DEVICE_PASSCODE, kSecAccessControlDevicePasscode);
MAKE_SYSTEM_STR(ACCESS_CONTROL_OR, kSecAccessControlOr);
MAKE_SYSTEM_STR(ACCESS_CONTROL_AND, kSecAccessControlAnd);
MAKE_SYSTEM_STR(ACCESS_CONTROL_PRIVATE_KEY_USAGE, kSecAccessControlPrivateKeyUsage);
MAKE_SYSTEM_STR(ACCESS_CONTROL_APPLICATION_PASSWORD, kSecAccessControlApplicationPassword);

@end
