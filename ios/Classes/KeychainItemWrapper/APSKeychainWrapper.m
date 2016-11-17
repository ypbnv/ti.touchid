//
//  APSKeychainWrapper.m
//  TouchID
//
//  Created by Hans Knoechel on 16/11/2016.
//
//

#import "APSKeychainWrapper.h"

APSErrorDomain const APSKeychainWrapperErrorDomain = @"com.appcelerator.keychainwrapper.ErrorDomain";

@implementation APSKeychainWrapper

- (id)initWithIdentifier:(NSString*)identifier
                 service:(NSString*)service
             accessGroup:(NSString*)accessGroup
       accessibilityMode:(CFStringRef)accessibilityMode
       accessControlMode:(long)accessControlMode
{
    if (self = [super init]) {
        _identifier = [identifier copy];
        _service = [service copy];
        _accessGroup = [accessGroup copy];
        _accessibilityMode = accessibilityMode;
        _accessControlMode = accessControlMode;
        
        [self initializeBaseAttributes];
    }
    
    return self;
}

- (BOOL)exists
{
    OSStatus status = SecItemCopyMatching((CFDictionaryRef)(@{
        (id)kSecClass: (id)kSecClassGenericPassword,
        (id)kSecMatchLimit: (id)kSecMatchLimitOne,
        (id)kSecAttrService: _service,
        (id)kSecAttrAccount: _identifier,
    }), NULL);
    
    return status == noErr;
}

- (void)save:(NSString*)value
{
    [baseAttributes setObject:[value dataUsingEncoding:NSUTF8StringEncoding] forKey:(id)kSecValueData];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        OSStatus status = SecItemAdd((__bridge CFDictionaryRef)baseAttributes, nil);
        
        [baseAttributes removeObjectForKey:(id)kSecValueData];

        if (status == noErr) {
            [[self delegate] APSKeychainWrapper:self didSaveValueWithResult:@{@"success": @YES}];
        } else {
            [[self delegate] APSKeychainWrapper:self didSaveValueWithError:[APSKeychainWrapper errorFromStatus:status]];
        }
    });
}

- (void)read
{
    if (![self exists]) {
        [_delegate APSKeychainWrapper:self didReadValueWithError:[APSKeychainWrapper errorFromStatus:errSecItemNotFound]];
        return;
    }
    
    __block NSString *value;
    
    // Special attributes to fetch data
    [baseAttributes setObject:(id)kSecMatchLimitOne forKey:(id)kSecMatchLimit];
    [baseAttributes setObject:(id)kCFBooleanTrue forKey:(id)kSecReturnData];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        CFTypeRef keychainData = NULL;
        
        OSStatus status = SecItemCopyMatching((CFDictionaryRef)(baseAttributes), (CFTypeRef *)&keychainData);
        
        [baseAttributes removeObjectForKey:(id)kSecMatchLimit];
        [baseAttributes removeObjectForKey:(id)kSecReturnData];
        
        if (status == noErr) {
            [[self delegate] APSKeychainWrapper:self didReadValueWithResult:@{
                @"success": @YES,
                @"value": [[NSString alloc] initWithData:(NSData*)keychainData encoding:NSUTF8StringEncoding]
            }];
        } else {
            [[self delegate] APSKeychainWrapper:self didReadValueWithError:[APSKeychainWrapper errorFromStatus:status]];
        }
    });
}

- (void)reset
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        OSStatus status = SecItemDelete((CFDictionaryRef)baseAttributes);

        if (status == noErr) {
            [[self delegate] APSKeychainWrapper:self didDeleteValueWithResult:@{@"success": @YES}];
        } else {
            [[self delegate] APSKeychainWrapper:self didDeleteValueWithError:[APSKeychainWrapper errorFromStatus:status]];
        }
    });
}

#pragma mark Utilities

+ (NSError*)errorFromStatus:(OSStatus)status
{
    NSString *message = [NSString stringWithFormat:@"%ld", (long)status];
    
    switch (status) {
        case errSecSuccess:
            message = @"The keychain operation succeeded";
            break;
            
        case errSecDuplicateItem:
            message = @"The keychain item already exists";
            break;
            
        case errSecItemNotFound:
            message = @"The keychain item could not be found";
            break;
            
        case errSecAuthFailed:
            message = @"The keychain item authentication failed";
            break;
            
        case errSecParam:
            message = @"The keychain access failed dies to malformed attributes";
            break;
            
        default:
            break;
    }
    
    message = [message stringByAppendingString:[NSString stringWithFormat:@" (Code: %i)", (int)status]];
    
    return [NSError errorWithDomain:APSKeychainWrapperErrorDomain
                               code:(int)status
                           userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(message, nil)}];
}

- (void)initializeBaseAttributes
{
    if (baseAttributes) {
        [baseAttributes removeAllObjects];
        [baseAttributes release];
        baseAttributes = nil;
    }
    
    baseAttributes = [[NSMutableDictionary dictionaryWithDictionary:@{
        (id)kSecClass: (id)kSecClassGenericPassword,
        (id)kSecAttrAccount: _identifier,
        (id)kSecAttrService: _service,
        (id)kSecAttrAccount: @"",
        (id)kSecAttrLabel: @"",
        (id)kSecAttrDescription: @""
    }] retain];
    
    if (_accessibilityMode) {
        CFErrorRef error = NULL;
        SecAccessControlRef accessControl = SecAccessControlCreateWithFlags(kCFAllocatorDefault, _accessibilityMode, _accessControlMode, &error);
        
        if (error == NULL || accessControl != NULL) {
            [baseAttributes setObject:(id)accessControl forKey:(id)kSecAttrAccessControl];
            [baseAttributes setObject:(id)kSecUseAuthenticationUIAllow forKey:(id)kSecUseAuthenticationUI];
            
            CFRelease(accessControl);
        } else {
            NSLog(@"Error: Could not create access control: %@", [(NSError*)error localizedDescription]);
            
            if (accessControl) {
                CFRelease(accessControl);
            }
        }
    }
    
    if (_accessGroup != nil) {
#if TARGET_IPHONE_SIMULATOR
        // Ignore the access group if running on the iPhone simulator.
        //
        // Apps that are built for the simulator aren't signed, so there's no keychain access group
        // for the simulator to check. This means that all apps can see all keychain items when run
        // on the simulator.
        //
        // If a SecItem contains an access group attribute, SecItemAdd and SecItemUpdate on the
        // simulator will return -25243 (errSecNoAccessForItem).
#else
        [baseAttributes setObject:_accessGroup forKey:(id)kSecAttrAccessGroup];
#endif
    }
}

@end
