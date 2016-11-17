//
//  APSKeychainWrapper.h
//  TouchID
//
//  Created by Hans Knoechel on 16/11/2016.
//
//

#import <Foundation/Foundation.h>

typedef NSString *APSErrorDomain;

@class APSKeychainWrapper;

@protocol APSKeychainWrapperDelegate <NSObject>
@required

/* -- Save -- */
- (void)APSKeychainWrapper:(APSKeychainWrapper*)keychainWrapper didSaveValueWithResult:(NSDictionary*)result;
- (void)APSKeychainWrapper:(APSKeychainWrapper*)keychainWrapper didSaveValueWithError:(NSError*)error;

/* -- Read -- */
- (void)APSKeychainWrapper:(APSKeychainWrapper*)keychainWrapper didReadValueWithResult:(NSDictionary*)result;
- (void)APSKeychainWrapper:(APSKeychainWrapper*)keychainWrapper didReadValueWithError:(NSError*)error;

/* -- Delete -- */
- (void)APSKeychainWrapper:(APSKeychainWrapper*)keychainWrapper didDeleteValueWithResult:(NSDictionary*)result;
- (void)APSKeychainWrapper:(APSKeychainWrapper*)keychainWrapper didDeleteValueWithError:(NSError*)error;

@end

@interface APSKeychainWrapper : NSObject {
    
@private
    NSMutableDictionary *baseAttributes;
    
    NSString *_identifier;
    NSString *_service;
    NSString *_accessGroup;
    CFStringRef _accessibilityMode;
    long _accessControlMode;
}

@property(nonatomic, assign)id<APSKeychainWrapperDelegate>delegate;

- (id)initWithIdentifier:(NSString*)identifier
                 service:(NSString*)service
             accessGroup:(NSString*)accessGroup
       accessibilityMode:(CFStringRef)accessibilityMode
       accessControlMode:(long)accessControlMode;

- (BOOL)exists;

- (void)save:(NSString*)value;

- (void)read;

- (void)reset;

@end
