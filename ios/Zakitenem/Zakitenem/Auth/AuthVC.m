//
//  AuthVC.m
//  Zakitenem
//
//  Created by Toto on 04.08.14.
//
//

#import "AuthVC.h"

//GAE
#import "GTLServiceApi.h"
#import "GTLQueryApi.h"
#import "GTLApiUserMessageLoginInfo.h"
#import "GTLApiUserMessageUser.h"

@interface AuthVC () <UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UITextField *tfLogin;
@end

@implementation AuthVC

- (void)viewDidLoad
{
    [super viewDidLoad];
    
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    DLOG(@"%@", textField.text);
    
    GTLServiceApi *service = [[GTLServiceApi alloc] init];
    service.retryEnabled = YES;
    
    GTLApiUserMessageLoginInfo *loginInfo = [[GTLApiUserMessageLoginInfo alloc] init];
    loginInfo.login = textField.text;
    loginInfo.password = @"";
    loginInfo.deviceId = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    loginInfo.deviceToken = self.tokenStr;
    
    GTLQueryApi *query = [GTLQueryApi queryForAuthWithObject:loginInfo];
    [service executeQuery:query completionHandler:^(GTLServiceTicket *ticket,
                                                    GTLApiUserMessageUser *obj, NSError *error){
        DLOG(@"%@", [obj login]);
        //TODO: store GTLApiUserMessageUser *obj
        if (error){
            DLOG(@"%@", [error localizedDescription]);
            
        }
    }];
    
    return YES;
}

@end
