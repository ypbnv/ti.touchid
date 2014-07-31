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
	[self setIOS8_orAbove: [UIViewController instancesRespondToSelector:@selector(showDetailViewController:sender:)]];

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

-(NSNumber*)isAPIAvailable:(id)args
{
	return NUMBOOL([self iOS8_orAbove]);
}

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
	if(![self iOS8_orAbove])
	{
		TiThreadPerformOnMainThread(^{
			NSMutableDictionary *event = [NSMutableDictionary dictionary];
			[event setValue:@"This API is only available in iOS 8 and above" forKey:@"error"];
			[event setValue:NUMLONG(0.0) forKey:@"code"];
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
	if([self iOS8_orAbove]) {
		return NUMINT(LAErrorAuthenticationFailed);
	}
	return NUMINT(-1);
}
-(NSNumber*)ERROR_USER_CANCEL
{
	if([self iOS8_orAbove]) {
		return NUMINT(LAErrorUserCancel);
	}
	return NUMINT(-2);
}
-(NSNumber*)ERROR_USER_FALLBACK
{
	if([self iOS8_orAbove]) {
		return NUMINT(LAErrorUserFallback);
	}
	return NUMINT(-3);
}
-(NSNumber*)ERROR_SYSTEM_CANCEL
{
	if([self iOS8_orAbove]) {
		return NUMINT(LAErrorSystemCancel);
	}
	return NUMINT(-4);
}
-(NSNumber*)ERROR_PASSCODE_NOT_SET
{
	if([self iOS8_orAbove]) {
		return NUMINT(LAErrorPasscodeNotSet);
	}
	return NUMINT(-5);
}
-(NSNumber*)ERROR_TOUCH_ID_NOT_AVAILABLE
{
	if([self iOS8_orAbove]) {
		return NUMINT(LAErrorTouchIDNotAvailable);
	}
	return NUMINT(-6);
}
-(NSNumber*)ERROR_TOUCH_ID_NOT_ENROLLED
{
	if([self iOS8_orAbove]) {
		return NUMINT(LAErrorTouchIDNotEnrolled);
	}
	return NUMINT(-7);
}

@end

