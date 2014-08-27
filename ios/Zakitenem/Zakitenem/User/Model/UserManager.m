//
//  UserManager.m
//  Zakitenem
//
//  Created by Toto on 05.08.14.
//
//

#import "UserManager.h"


@interface UserManager() <CLLocationManagerDelegate>

@property (strong, nonatomic) GTLApiUserMessageUser *currentUser;
@property (strong, nonatomic) CLLocationManager *userLocationManager;
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

- (id)init
{
    if (self = [super init]){
        _userLocationManager = [[CLLocationManager alloc] init];
        _userLocationManager.desiredAccuracy = kCLLocationAccuracyKilometer;
        _userLocationManager.delegate = self;
        
        [_userLocationManager startUpdatingLocation];
    }
    return self;
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

#pragma mark - CLLocationManagerDelegate
- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation
    fromLocation:(CLLocation *)oldLocation
{
    self.userLocation = newLocation;
}

@end
