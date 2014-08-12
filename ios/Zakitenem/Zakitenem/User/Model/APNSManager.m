//
//  APNSManager.m
//  Zakitenem
//
//  Created by Toto on 05.08.14.
//
//

#import "APNSManager.h"

@interface APNSManager()
@property (strong, nonatomic) NSString *token;
@property (atomic) BOOL isLoading;
@end


@implementation APNSManager

+ (instancetype)sharedManager
{
	static id singleton;
	static dispatch_once_t pred;
    
	dispatch_once(&pred, ^{
		singleton = [[self alloc] init];
	});
    return singleton;
}

- (void)startLoadingToken
{
    self.isLoading = YES;
}

- (void)stopLoadingToken:(NSString*)token
{
    self.isLoading = NO;
    self.token = token;
}



@end
