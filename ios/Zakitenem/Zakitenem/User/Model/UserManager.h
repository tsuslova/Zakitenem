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

//If user wasn't successfully saved on server before, needSaveUser will return YES
- (BOOL)needSaveUser;

//If user wasn't successfully saved on server, isSaved must be NO to save it later
- (void)userUpdated:(GTLApiUserMessageUser*)user saved:(BOOL)isSaved;

- (void)logout;

@end
