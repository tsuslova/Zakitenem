//
//  AppDelegate.m
//  Zakitenem
//
//  Created by Toto on 29.07.14.
//
//

#import "AppDelegate.h"
#import "AuthVC.h"
#import "ForecastsVC.h"

#import "APNSManager.h"
#import "UserManager.h"



@interface AppDelegate()
@property (strong, nonatomic) AuthVC *authVC;
@property (strong, nonatomic) UINavigationController *rootVC;
@end

@implementation AppDelegate
static NSString *const kCurrentUserProperty = @"currentUser";

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    
    [[UIApplication sharedApplication] registerForRemoteNotificationTypes:
        UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeBadge |
        UIRemoteNotificationTypeSound];
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    self.window.backgroundColor = [UIColor whiteColor];
    [[APNSManager sharedManager] startLoadingToken];
    
    self.rootVC = [[UINavigationController alloc] init];
    self.rootVC.navigationBarHidden = YES;
    if ([UserManager sharedManager].currentUser){
        [self initStack];
    } else {
        [self showAuth];
    }
    self.window.rootViewController = self.rootVC;
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
    [[APNSManager sharedManager] stopLoadingToken:tokenStr];
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
    DLOG(@"Push notifications registration failed with error:%@", error);
    [[APNSManager sharedManager] stopLoadingToken:nil];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
{
    DLOG(@"Push userInfo %@ ", userInfo);
}

#pragma mark - Main controllers
- (void)initStack
{
    [self.rootVC popToRootViewControllerAnimated:NO];
    self.rootVC.viewControllers = @[[[ForecastsVC alloc] initWithNibName:@"ForecastsVC" bundle:nil]];
}

- (void)showAuth
{
    [[UserManager sharedManager] addObserver:self forKeyPath:kCurrentUserProperty options:0
                                     context:nil];
    self.authVC = [[AuthVC alloc] init];
    self.rootVC.viewControllers = @[self.authVC];
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change
                       context:(void *)context
{
    if ([keyPath isEqualToString:kCurrentUserProperty]){
        if ([[UserManager sharedManager] currentUser]){
            [self initStack];
        } else {
            [self showAuth];
        }
    }
}


@end
