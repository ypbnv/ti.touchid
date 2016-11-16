/**
 * Appcelerator Titanium Mobile
 * Copyright (c) 2009-2016 by Appcelerator, Inc. All Rights Reserved.
 * Licensed under the terms of the Apache Public License
 * Please see the LICENSE included with this distribution for details.
 */

#import "TiTouchidKeychainItemProxy.h"

@implementation TiTouchidKeychainItemProxy

#pragma mark Internal

- (id)_initWithPageContext:(id<TiEvaluator>)context args:(NSArray *)args
{
    if (self = [super _initWithPageContext:context args:args]) {
        NSDictionary *params = [args objectAtIndex:0];
        
        identifier = [[params objectForKey:@"identifier"] copy];
        accessibilityMode = [[params objectForKey:@"accessibilityMode"] copy];
        accessGroup = [[params objectForKey:@"accessGroup"] copy];
        accessControlMode = [[params objectForKey:@"accessControlMode"] retain];
    }
    return self;
}

- (KeychainItemWrapper*)keychainItem
{
    if (!keychainItem) {
        keychainItem = [[[KeychainItemWrapper alloc] initWithIdentifier:identifier
                                                            accessGroup:accessGroup
                                                      accessibilityMode:(__bridge CFStringRef)accessibilityMode
                                                      accessControlMode:[self formattedAccessControlFlags]] retain];
    }
    
    return keychainItem;
}

#pragma mark Public API's

- (void)save:(id)value
{
    ENSURE_SINGLE_ARG(value, NSString);
    
    [[self keychainItem] setObject:value forKey:(id)kSecValueData withCompletionBlock:^(NSError *error) {
        TiThreadPerformOnMainThread(^{
            NSMutableDictionary *propertiesDict = [NSMutableDictionary dictionaryWithDictionary:@{@"success": NUMBOOL(error == nil)}];
            
            if (error) {
                [propertiesDict setObject:error.localizedDescription forKey:@"error"];
                [propertiesDict setObject:NUMINTEGER(error.code) forKey:@"code"];
            }
            
            [self fireEvent:@"save" withObject:propertiesDict];
        }, NO);
    }];
}

- (void)read:(id)unused
{    
    NSString *value = [[[self keychainItem] objectForKey:(id)kSecValueData] retain];
    NSMutableDictionary *propertiesDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:NUMBOOL(value.length > 0), @"success", nil];
    
    if (value.length == 0) {
        [propertiesDict setObject:@"Keychain item does not exist" forKey:@"error"];
        [propertiesDict setObject:NUMINTEGER(-1) forKey:@"code"];
    } else {
        [propertiesDict setObject:value forKey:@"value"];
    }
    
    [self fireEvent:@"read" withObject:propertiesDict];
    RELEASE_TO_NIL(value);
}

- (void)reset:(id)unused
{
    [[self keychainItem] resetKeychainItem];
    [self fireEvent:@"reset"];
}

#pragma mark Utilities

- (long)formattedAccessControlFlags
{
    if (accessControlMode) {
        if (!accessibilityMode) {
            NSLog(@"[ERROR] Ti.TouchID: When using `accessControlMode` you must also specify the `accessibilityMode` property.");
        } else if ([accessControlMode isKindOfClass:[NSNumber class]]) {
            return kSecAccessControlTouchIDAny;
        } else {
            NSLog(@"[WARN] Ti.TouchID: The property \"accessControlMode\" must either be a single constant or an array of multiple constants.");
            NSLog(@"[WARN] Ti.TouchID: Falling back to default `ACCESS_CONTROL_USER_PRESENCE`");
        }
    }
    
    return kSecAccessControlUserPresence;
}

@end
