//
//  AppDelegate.m
//  Zakitenem
//
//  Created by Toto on 29.07.14.
//
//

#import "AppDelegate.h"
#import "AuthVC.h"

@interface AppDelegate()
@property (strong, nonatomic) AuthVC *authVC;
@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    
    [[UIApplication sharedApplication] registerForRemoteNotificationTypes:
        UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeBadge |
        UIRemoteNotificationTypeSound];
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    self.window.backgroundColor = [UIColor whiteColor];

    self.authVC = [[AuthVC alloc] init];
    self.window.rootViewController = self.authVC;
    [self.window makeKeyAndVisible];
    return YES;
}

#pragma mark - Push notifications

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    const unsigned char *dataBuffer = (const unsigned char *)[deviceToken bytes];
    if (!dataBuffer) return;
    
    NSUInteger dataLength = [deviceToken length];
    NSMutableString *tokenStr  = [NSMutableString stringWithCapacity:(dataLength * 2)];
    for (int i = 0; i < dataLength; ++i) {
        [tokenStr appendString:[NSString stringWithFormat:@"%02lx", (unsigned long)dataBuffer[i]]];
    }
    
    DLOG(@"Push notifications token: %@", tokenStr);
    self.authVC.tokenStr = tokenStr;
    
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
    DLOG(@"Push notifications registration failed with error:%@", error);
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
{
    DLOG(@"Push userInfo %@ ", userInfo);
}


@end
