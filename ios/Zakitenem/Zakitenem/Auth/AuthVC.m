//
//  AuthVC.m
//  Zakitenem
//
//  Created by Toto on 04.08.14.
//
//

#import "AuthVC.h"
#import "Utils.h"
#import "constants.h"
#import "APNSManager.h"
#import "UserManager.h"

//GAE
#import "GTLServiceApi.h"
#import "GTLQueryApi.h"
#import "GTLErrorObject.h"
#import "UIViewController+Lock.h"

@interface AuthVC () <UITextFieldDelegate>

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

- (void)loginQuery:(NSString*)login
{
    GTLServiceApi *service = [[GTLServiceApi alloc] init];
    service.retryEnabled = YES;
    
    GTLApiUserMessageLoginInfo *loginInfo = [[GTLApiUserMessageLoginInfo alloc] init];
    loginInfo.login = login;
    loginInfo.password = @"";
    loginInfo.deviceId = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
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
            [[UserManager sharedManager] loggedIn:obj];
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

@end
