//
//  AuthVC.m
//  Zakitenem
//
//  Created by Toto on 04.08.14.
//
//

#import "AuthVC.h"

#import "APNSManager.h"
#import "UserManager.h"

#import "UserUpdateVC.h"

//Utils
#import "UIViewController+Lock.h"
#import "Utils.h"
#import "constants.h"

//GAE
#import "GTLServiceApi.h"
#import "GTLQueryApi.h"
#import "GTLErrorObject.h"

#import <SSKeychain/SSKeychain.h>

@interface AuthVC () <UITextFieldDelegate, UserUpdateDelegate>

@property (weak, nonatomic) IBOutlet UITextField *tfLogin;
@end

static NSString *const kToken = @"token";

@implementation AuthVC

- (void)viewDidLoad
{
    [super viewDidLoad];
    
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    DLOG(@"%@", textField.text);
    
    [textField resignFirstResponder];
    [self login];
    return YES;
}

#pragma mark - Data
- (void)login
{
    if ([APNSManager sharedManager].isLoading){
        DLOG(@"Device token is not loaded yet - wait till it is loaded (or failed to load)");
        [[APNSManager sharedManager] addObserver:self forKeyPath:kToken options:0 context:nil];
        [self lock];
    } else {
        [self loginQuery:self.tfLogin.text];
    }
}

- (NSString*)deviceId
{
    NSString *bundleIdentifier = [[NSBundle mainBundle] bundleIdentifier];
    NSError *error;
    NSString *kUDIDKey = @"deviceID";
    NSString *uuid = [SSKeychain passwordForService:bundleIdentifier account:kUDIDKey error:&error];
    if (error){
        DLOG(@"error %@",[error localizedDescription]);
    }
    if (uuid == nil) { // if this is the first time app launching , create key for device
        uuid = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
        error = nil;
        
        [SSKeychain setPassword:uuid forService:bundleIdentifier account:kUDIDKey error:&error];
        if (error){
            DLOG(@"error %@",[error localizedDescription]);
        }
    }
    return uuid;
}

- (void)loginQuery:(NSString*)login
{
    GTLServiceApi *service = [[GTLServiceApi alloc] init];
    service.retryEnabled = YES;
    
    GTLApiUserMessageLoginInfo *loginInfo = [[GTLApiUserMessageLoginInfo alloc] init];
    loginInfo.login = login;
    loginInfo.password = @"";
    loginInfo.deviceId = [self deviceId];
    DLOG(@"%@",loginInfo.deviceId);
    loginInfo.deviceToken = [APNSManager sharedManager].token;
    [self lock];
    
    GTLQueryApi *query = [GTLQueryApi queryForAuthWithObject:loginInfo];
    [service executeQuery:query completionHandler:^(GTLServiceTicket *ticket,
                                                    GTLApiUserMessageUser *obj, NSError *error){
        DLOG(@"%@", [obj login]);
        [self unlock];
        //TODO: store GTLApiUserMessageUser *obj
        if (error){
            GTLErrorObject *structuredError = [[error userInfo] objectForKey:kGTLStructuredErrorKey];
            if (structuredError){
                DLOG(@"%@", structuredError.message);
                if ([structuredError.message isEqualToString:kAccountUsed]){
                    DLOG(@"TODO Need a logic to restore/create password");
                    NSString *message = [NSString stringWithFormat:
                        NSLocalizedString(structuredError.message, @"Login"), login];
                    showErrorAlertView(error, message);
                } else {
                    showErrorAlertView(error, NSLocalizedString(structuredError.message, ));
                }
            } else {
                DLOG(@"Not a server error - assume as network one");
                showErrorAlertView(error, NSLocalizedString(@"NoInternetErrorMessage", ));
            }
        } else {
            DLOG(@"Logged in!");
            UserUpdateVC *userUpdateVC = [[UserUpdateVC alloc] initWithNibName:@"UserUpdateVCLogin"
                user:obj delegate:self];
            [self.navigationController pushViewController:userUpdateVC animated:YES];
        }
        
    }];

}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change
   context:(void *)context
{
    if ([keyPath isEqualToString:kToken]){
        [[APNSManager sharedManager] removeObserver:self forKeyPath:kToken];
        [self loginQuery:self.tfLogin.text];
    }
}

#pragma mark - UserUpdateDelegate
- (void)userUpdated:(GTLApiUserMessageUser *)user saved:(BOOL)isSaved
{
    [[UserManager sharedManager] userUpdated:user saved:isSaved];
}


@end
