//
//  AppDelegate.m
//  Zakitenem
//
//  Created by Toto on 29.07.14.
//
//

#import "AppDelegate.h"

//TBD: test code
#import "GTLServiceApi.h"
#import "GTLQueryApi.h"
#import "GTLApiUserMessageLoginInfo.h"
#import "GTLApiUserMessageUser.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];

    //TBD: test code
    GTLServiceApi *service = [[GTLServiceApi alloc] init];
    service.retryEnabled = YES;
    
    GTLApiUserMessageLoginInfo *loginInfo = [[GTLApiUserMessageLoginInfo alloc] init];
    loginInfo.login = @"TestUser11";
    loginInfo.password = @"123";
    loginInfo.deviceId = @"dffo8447fhi37";
    
    GTLQueryApi *query = [GTLQueryApi queryForAuthWithObject:loginInfo];
    [service executeQuery:query completionHandler:^(GTLServiceTicket *ticket,
                                                    GTLApiUserMessageUser *obj, NSError *error){
        DLOG(@"%@", [obj login]);
        DLOG(@"%@", [error localizedDescription]);
    }];
    //TBD: test code
    
    return YES;
}

@end
