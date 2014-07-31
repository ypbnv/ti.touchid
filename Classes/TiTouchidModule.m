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

@implementation TiTouchidModule

#pragma mark Internal

-(id)moduleGUID
{
	return @"0ee4118b-68f9-47c6-8c37-d68778ecb806";
}

-(NSString*)moduleId
{
	return @"ti.touchid";
}

#pragma mark Lifecycle

-(void)startup
{
	[super startup];
	NSLog(@"[INFO] %@ loaded",self);
}

-(void)shutdown:(id)sender
{
	[super shutdown:sender];
}

#pragma mark Cleanup 

-(void)dealloc
{
	[super dealloc];
}

#pragma mark Public API

/**
 * To be used this way:
 *
 * var TiTouchId = require('ti.touchid');
 *	
 * TiTouchId.authenticate({
 *     reason: 'We need your finprint to continue.',
 *     callback: function(e) {
 *         if (!e.success) {
 *             alert('Message: ' + e.error + '\nCode: ' + e.code);
 *         } else {
 *             // do something useful
 *         }
 *     }
 * });
 */
-(void)authenticate:(id)args
{
	ENSURE_SINGLE_ARG(args, NSDictionary)
	NSString *reason = [TiUtils stringValue:[args valueForKey:@"reason"]];
	KrollCallback *callback = [args valueForKey:@"callback"];

	if(![callback isKindOfClass:[KrollCallback class]]) {
		NSLog(@"\"callback\" must be a function");
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
				 [event setValue:NUMLONG([error code]) forKey:@"code"];
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
			[event setValue:NUMLONG([authError code]) forKey:@"code"];
		} else {
			[event setValue:@"Can not evaluate Touch ID" forKey:@"error"];
			[event setValue:NUMLONG(0.0) forKey:@"code"];
		}
		[event setValue:NUMBOOL(NO) forKey:@"success"];
		[callback call:[NSArray arrayWithObjects:event, nil] thisObject:self];
	}, NO);
}

-(NSNumber*)ERROR_AUTHENTICATION_FAILED
{
	return NUMINT(LAErrorAuthenticationFailed);
}
-(NSNumber*)ERROR_USER_CANCEL
{
	return NUMINT(LAErrorUserCancel);
}
-(NSNumber*)ERROR_USER_FALLBACK
{
	return NUMINT(LAErrorUserFallback);
}
-(NSNumber*)ERROR_SYSTEM_CANCEL
{
	return NUMINT(LAErrorSystemCancel);
}
-(NSNumber*)ERROR_PASSCODE_NOT_SET
{
	return NUMINT(LAErrorPasscodeNotSet);
}
-(NSNumber*)ERROR_TOUCH_ID_NOT_AVAILABLE
{
	return NUMINT(LAErrorTouchIDNotAvailable);
}
-(NSNumber*)ERROR_TOUCH_ID_NOT_ENROLLED
{
	return NUMINT(LAErrorTouchIDNotEnrolled);
}

@end

