//
//  UserManager.m
//  Zakitenem
//
//  Created by Toto on 05.08.14.
//
//

#import "UserManager.h"

@interface UserManager()

@property (strong, nonatomic) GTLApiUserMessageUser *currentUser;

@end

@implementation UserManager

static NSString *const kUserKey = @"UserKey";

+ (instancetype)sharedManager
{
	static id singleton;
	static dispatch_once_t pred;
    
	dispatch_once(&pred, ^{
		singleton = [[self alloc] init];
	});
    return singleton;
}

- (GTLApiUserMessageUser*)currentUser
{
    if (_currentUser){
        return _currentUser;
    }
    NSMutableDictionary *userJSON = [[NSUserDefaults standardUserDefaults] objectForKey:kUserKey];
    if (userJSON){
        _currentUser = [GTLApiUserMessageUser objectWithJSON:userJSON];
    }
    return _currentUser;
}

- (void)loggedIn:(GTLApiUserMessageUser*)user
{
    [[NSUserDefaults standardUserDefaults] setObject:user.JSON forKey:kUserKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    self.currentUser = user;
}

- (void)logout
{
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kUserKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    self.currentUser = nil;
}

@end
