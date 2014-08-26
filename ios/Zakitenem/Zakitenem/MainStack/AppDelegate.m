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
#import "UserUpdateVC.h"

#import "APNSManager.h"
#import "UserManager.h"

#import "RNCachingURLProtocol.h"


@interface AppDelegate() 
@property (strong, nonatomic) AuthVC *authVC;
@property (strong, nonatomic) UIViewController *rootVC;
@property (strong, nonatomic) UITabBarController *tabbarController;

@end

@implementation AppDelegate
static NSString *const kCurrentUserProperty = @"currentUser";

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [NSURLProtocol registerClass:[RNCachingURLProtocol class]];
    
    [[UIApplication sharedApplication] registerForRemoteNotificationTypes:
        UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeBadge |
        UIRemoteNotificationTypeSound];
    
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    self.window.backgroundColor = [UIColor whiteColor];
    
    [[APNSManager sharedManager] startLoadingToken];
    
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
- (void)setTabbarItem:(UITabBarItem*)tabBarItem image:(NSString*)imageName
{
    UIImage *image = [UIImage imageNamed:imageName];
    tabBarItem.image = [image imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    
    UIImage *selectedImage = [UIImage imageNamed:[imageName stringByAppendingString:@"_selected"]];
    tabBarItem.selectedImage = [selectedImage imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    
    //Now we have title inside an image - set image inset to use full height for tabbar image
    const CGFloat tabbarTitleHeight = 5;
    tabBarItem.imageInsets = UIEdgeInsetsMake(tabbarTitleHeight, 0, -tabbarTitleHeight, 0);
}

- (void)initStack
{
    ForecastsVC *forecastsVC = [[ForecastsVC alloc] initWithNibName:@"ForecastsVC" bundle:nil];
    UserUpdateVC *secondVC = [[UserUpdateVC alloc] initWithNibName:@"UserUpdateVC" bundle:nil];
    UserUpdateVC *thirdVC = [[UserUpdateVC alloc] initWithNibName:@"UserUpdateVC" bundle:nil];
    UserUpdateVC *userUpdateVC = [[UserUpdateVC alloc] initWithNibName:@"UserUpdateVC" bundle:nil];
    [self setTabbarItem:forecastsVC.tabBarItem image:@"btn_forecast"];
    [self setTabbarItem:secondVC.tabBarItem image:@"btn_plan"];
    [self setTabbarItem:thirdVC.tabBarItem image:@"btn_news"];
    [self setTabbarItem:userUpdateVC.tabBarItem image:@"btn_user"];
    
    self.tabbarController = [[UITabBarController alloc] init];
    UIImage *bgTabbar = [UIImage imageNamed:@"bg_tab_bar"];
    self.tabbarController.tabBar.backgroundImage = bgTabbar;
    self.tabbarController.viewControllers = @[forecastsVC, secondVC, thirdVC, userUpdateVC];
    self.rootVC = self.tabbarController;
}

- (void)showAuth
{
    UINavigationController *rootVC = [[UINavigationController alloc] init];
    rootVC.navigationBarHidden = YES;
    [[UserManager sharedManager] addObserver:self forKeyPath:kCurrentUserProperty options:0
                                     context:nil];
    self.authVC = [[AuthVC alloc] init];
    rootVC.viewControllers = @[self.authVC];
    self.rootVC = rootVC;
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change
                       context:(void *)context
{
    if ([keyPath isEqualToString:kCurrentUserProperty]){
        if ([[UserManager sharedManager] currentUser]){
            UINavigationController *authNC = (UINavigationController *)self.rootVC;
            [authNC popToRootViewControllerAnimated:NO];
            authNC.viewControllers = @[];
            [self initStack];
            self.window.rootViewController = self.rootVC;
        } else {
            [self showAuth];
        }
    }
}


@end
