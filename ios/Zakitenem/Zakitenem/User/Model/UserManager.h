//
//  UserManager.h
//  Zakitenem
//
//  Created by Toto on 05.08.14.
//
//

#import <Foundation/Foundation.h>

@import CoreLocation;

#import "GTLApiUserMessageLoginInfo.h"
#import "GTLApiUserMessageUser.h"

@interface UserManager : NSObject
@property (strong, nonatomic) CLLocation *userLocation;

+ (UserManager*)sharedManager;
- (GTLApiUserMessageUser*)currentUser;
- (void)loggedIn:(GTLApiUserMessageUser*)user;

- (void)logout;

@end
