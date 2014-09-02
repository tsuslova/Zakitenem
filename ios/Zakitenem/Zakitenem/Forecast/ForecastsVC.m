//
//  ForecastsVC.m
//  Zakitenem
//
//  Created by Toto on 05.08.14.
//
//

#import "ForecastsVC.h"
#import "UserManager.h"

//GAE
#import "GTLServiceApi.h"
#import "GTLQueryApi.h"
#import "GTLErrorObject.h"
#import "GTLApiUserMessageUser.h"
#import "GTLApiForecastMessageSpot.h"
#import "GTLApiForecastMessageSpotList.h"

NSString *const kSavedForecasts = @"kSavedForecasts";

@interface ForecastsVC () <UIWebViewDelegate>
@property (weak, nonatomic) IBOutlet UIWebView *webView;

@end

@implementation ForecastsVC

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self loadForecasts];
}

#pragma mark - Data loading

- (void)loadForecasts
{
    [self lock];
    
    GTLServiceApi *service = [[GTLServiceApi alloc] init];
    service.retryEnabled = YES;
    GTLApiUserMessageSession *session = [[UserManager sharedManager] currentUser].session;
    GTLQueryApi *query = [GTLQueryApi queryForUserForecastsWithObject:session];
    
    [service executeQuery:query completionHandler:^(GTLServiceTicket *ticket,
        GTLApiForecastMessageSpotList *obj, NSError *error){
        [self unlock];
        DLOG(@"%@", obj.spots);
        NSArray *spots = obj.spots;
        if (error){
            DLOG(@"%@", [error localizedDescription]);
            if ([[NSUserDefaults standardUserDefaults] objectForKey:kSavedForecasts]){
                NSMutableDictionary *json = [NSMutableDictionary dictionaryWithDictionary:
                 [[NSUserDefaults standardUserDefaults] objectForKey:kSavedForecasts]];
                GTLApiForecastMessageSpotList *savedSpotList =
                    [GTLApiForecastMessageSpotList objectWithJSON:json];
                spots = savedSpotList.spots;
            }
        } else {
            
            [[NSUserDefaults standardUserDefaults] setObject:obj.JSON forKey:kSavedForecasts];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
        if (spots){
            [self showSpotsForecast:spots];
        } else {
            showErrorAlertView(error, NSLocalizedString(@"NoInternetErrorMessage", ));
        }
    }];
}

- (void)showSpotsForecast:(NSArray*)spotsList
{
    NSString *html = @"<html>";
    for (GTLApiForecastMessageSpot *spot in spotsList){
        html = [html stringByAppendingString:spot.forecast];
    }
    html = [html stringByAppendingString:@"</html>"];
    [self lock];
    [self.webView loadHTMLString:html baseURL:nil];
}

#pragma mark - IBActions
- (IBAction)logout:(id)sender
{
    [[UserManager sharedManager] logout];
}

- (IBAction)reload:(id)sender
{
    DLOG(@"%@",self.webView.request);
    [self.webView stopLoading];
    [self.webView reload];
}

#pragma mark - UIWebViewDelegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    DLOG(@"%@",request.URL.absoluteString);
    return YES;
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    DLOG(@"%@",[error localizedDescription]);
    [self unlock];
}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
    DLOG(@"");
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    DLOG(@"");
    [self unlock];
}

@end
