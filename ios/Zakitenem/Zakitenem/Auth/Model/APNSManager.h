//
//  APNSManager.h
//  Zakitenem
//
//  Created by Toto on 05.08.14.
//
//

#import <Foundation/Foundation.h>

@interface APNSManager : NSObject
+ (APNSManager*)sharedManager;

- (void)startLoadingToken;
- (void)stopLoadingToken:(NSString*)token;

@property (strong, nonatomic, readonly) NSString *token;
@property (atomic, readonly) BOOL isLoading;

@end
