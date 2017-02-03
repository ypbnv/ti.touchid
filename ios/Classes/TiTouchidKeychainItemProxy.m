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
        options = [[params objectForKey:@"options"] retain];
    }
    return self;
}

- (void)dealloc
{
    RELEASE_TO_NIL(identifier);
    RELEASE_TO_NIL(accessGroup);
    RELEASE_TO_NIL(accessibilityMode);
    RELEASE_TO_NIL(accessControlMode);
    RELEASE_TO_NIL(options);
    
    [super dealloc];
}

- (APSKeychainWrapper*)keychainItem
{
    if (!keychainItem) {
                
        keychainItem = [[[APSKeychainWrapper alloc] initWithIdentifier:identifier
                                                               service:@"ti.touchid"
                                                            accessGroup:accessGroup
                                                      accessibilityMode:(CFStringRef)accessibilityMode
                                                      accessControlMode:[self formattedAccessControlFlags]
                                                                options:options
                         ] retain];
        
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

- (void)update:(id)value
{
    ENSURE_SINGLE_ARG(value, NSString);
    [[self keychainItem] update:value];
}

- (void)reset:(id)unused
{
    [[self keychainItem] reset];
}

- (void)fetchExistence:(id)value
{
    ENSURE_SINGLE_ARG(value, KrollCallback);
    
    [[self keychainItem] exists:^(BOOL result, NSError *error) {
        TiThreadPerformOnMainThread(^{
            NSMutableDictionary *propertiesDict = [NSMutableDictionary dictionaryWithDictionary:@{@"exists": NUMBOOL(result)}];
            
            if (error) {
                [propertiesDict setObject:[error localizedDescription] forKey:@"error"];
            }
            
            NSArray * invocationArray = [[NSArray alloc] initWithObjects:&propertiesDict count:1];
            
            [value call:invocationArray thisObject:self];
            [invocationArray release];
        }, YES);
    }];
}

#pragma mark APSKeychainWrapperDelegate

- (void)APSKeychainWrapper:(APSKeychainWrapper *)keychainWrapper didSaveValueWithResult:(NSDictionary *)result
{
    if ([self _hasListeners:@"save"]) {
        [self fireEvent:@"save" withObject:result];
    }
}

- (void)APSKeychainWrapper:(APSKeychainWrapper *)keychainWrapper didSaveValueWithError:(NSError *)error
{
    if ([self _hasListeners:@"save"]) {
        [self fireEvent:@"save" withObject:[TiTouchidKeychainItemProxy errorDictionaryFromError:error]];
    }
}

-(void)APSKeychainWrapper:(APSKeychainWrapper *)keychainWrapper didReadValueWithResult:(NSDictionary *)result
{
    if ([self _hasListeners:@"read"]) {
        [self fireEvent:@"read" withObject:result];
    }
}

- (void)APSKeychainWrapper:(APSKeychainWrapper *)keychainWrapper didReadValueWithError:(NSError *)error
{
    if ([self _hasListeners:@"read"]) {
        [self fireEvent:@"read" withObject:[TiTouchidKeychainItemProxy errorDictionaryFromError:error]];
    }
}

- (void)APSKeychainWrapper:(APSKeychainWrapper *)keychainWrapper didUpdateValueWithError:(NSError *)error
{
    if ([self _hasListeners:@"update"]) {
        [self fireEvent:@"update" withObject:[TiTouchidKeychainItemProxy errorDictionaryFromError:error]];
    }
}

- (void)APSKeychainWrapper:(APSKeychainWrapper *)keychainWrapper didDeleteValueWithResult:(NSDictionary *)result
{
    if ([self _hasListeners:@"reset"]) {
        [self fireEvent:@"reset" withObject:result];
    }
}

- (void)APSKeychainWrapper:(APSKeychainWrapper *)keychainWrapper didDeleteValueWithError:(NSError *)error
{
    if ([self _hasListeners:@"reset"]) {
        [self fireEvent:@"reset" withObject:[TiTouchidKeychainItemProxy errorDictionaryFromError:error]];
    }
}

- (void)APSKeychainWrapper:(APSKeychainWrapper *)keychainWrapper didUpdateValueWithResult:(NSDictionary *)result
{
    if ([self _hasListeners:@"update"]) {
        [self fireEvent:@"update" withObject:result];
    }
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

- (SecAccessControlCreateFlags)formattedAccessControlFlags
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
    
    return NULL;
}

@end
