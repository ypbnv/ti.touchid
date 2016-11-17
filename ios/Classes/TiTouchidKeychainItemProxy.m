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
        accessGroup = [[params objectForKey:@"accessGroup"] copy];
        accessibilityMode = [[params objectForKey:@"accessibilityMode"] copy];
        accessControlMode = [[params objectForKey:@"accessControlMode"] retain];
    }
    return self;
}

- (void)dealloc
{
    RELEASE_TO_NIL(identifier);
    RELEASE_TO_NIL(accessGroup);
    RELEASE_TO_NIL(accessibilityMode);
    RELEASE_TO_NIL(accessControlMode);
    
    [super dealloc];
}

- (APSKeychainWrapper*)keychainItem
{
    if (!keychainItem) {
        keychainItem = [[[APSKeychainWrapper alloc] initWithIdentifier:identifier
                                                               service:@"ti.touchid"
                                                            accessGroup:accessGroup
                                                      accessibilityMode:(CFStringRef)accessibilityMode
                                                      accessControlMode:[self formattedAccessControlFlags]] retain];
        
        [keychainItem setDelegate:self];
    }
    
    return keychainItem;
}

#pragma mark Public API's

- (void)save:(id)value
{
    ENSURE_SINGLE_ARG(value, NSString);
    [[self keychainItem] save:value];
}

- (void)read:(id)unused
{
    [[self keychainItem] read];
}

- (void)reset:(id)unused
{
    [[self keychainItem] reset];
}

- (id)exists:(id)unused
{
    return NUMBOOL([[self keychainItem] exists]);
}

#pragma mark APSKeychainWrapperDelegate

- (void)APSKeychainWrapper:(APSKeychainWrapper *)keychainWrapper didSaveValueWithResult:(NSDictionary *)result
{
    [self fireEvent:@"save" withObject:result];
}

- (void)APSKeychainWrapper:(APSKeychainWrapper *)keychainWrapper didSaveValueWithError:(NSError *)error
{
    [self fireEvent:@"save" withObject:[TiTouchidKeychainItemProxy errorDictionaryFromError:error]];
}

-(void)APSKeychainWrapper:(APSKeychainWrapper *)keychainWrapper didReadValueWithResult:(NSDictionary *)result
{
    [self fireEvent:@"read" withObject:result];
}

- (void)APSKeychainWrapper:(APSKeychainWrapper *)keychainWrapper didReadValueWithError:(NSError *)error
{
    [self fireEvent:@"read" withObject:[TiTouchidKeychainItemProxy errorDictionaryFromError:error]];
}

- (void)APSKeychainWrapper:(APSKeychainWrapper *)keychainWrapper didDeleteValueWithResult:(NSDictionary *)result
{
    [self fireEvent:@"reset" withObject:result];
}

- (void)APSKeychainWrapper:(APSKeychainWrapper *)keychainWrapper didDeleteValueWithError:(NSError *)error
{
    [self fireEvent:@"reset" withObject:[TiTouchidKeychainItemProxy errorDictionaryFromError:error]];
}

#pragma mark Utilities

+ (NSDictionary*)errorDictionaryFromError:(NSError*)error
{
    return @{
        @"success": @NO,
        @"error": [error localizedDescription],
        @"code": NUMINTEGER([error code])
    };
}

- (long)formattedAccessControlFlags
{
    if (accessControlMode) {
        if (!accessibilityMode) {
            NSLog(@"[ERROR] Ti.TouchID: When using `accessControlMode` you must also specify the `accessibilityMode` property.");
        } else if ([accessControlMode isKindOfClass:[NSNumber class]]) {
            return [accessControlMode longLongValue];
        } else {
            NSLog(@"[WARN] Ti.TouchID: The property \"accessControlMode\" must either be a single constant or an array of multiple constants.");
            NSLog(@"[WARN] Ti.TouchID: Falling back to default `ACCESS_CONTROL_USER_PRESENCE`");
        }
    }
    
    return kSecAccessControlTouchIDAny;
}

@end
