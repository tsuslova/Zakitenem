//
//  ForecastsVC.m
//  Zakitenem
//
//  Created by Toto on 05.08.14.
//
//

#import "ForecastsVC.h"
#import "UserManager.h"
#import "CellForecast.h"
#import "UIView+NibLoading.h"

//GAE
#import "GTLServiceApi.h"
#import "GTLQueryApi.h"
#import "GTLErrorObject.h"
#import "GTLApiUserMessageUser.h"
#import "GTLApiForecastMessageSpotList.h"

NSString *const kSavedForecasts = @"kSavedForecasts";

@interface ForecastsVC () <UITableViewDataSource, UITableViewDelegate>
@property (strong, nonatomic) GTLApiForecastMessageSpotList *spotList;
@property (strong, nonatomic) NSMutableDictionary *cellList;

@property (weak, nonatomic) IBOutlet UITableView *tableView;
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
    if ([[NSUserDefaults standardUserDefaults] objectForKey:kSavedForecasts]){
        NSMutableDictionary *json = [NSMutableDictionary dictionaryWithDictionary:
                                     [[NSUserDefaults standardUserDefaults] objectForKey:kSavedForecasts]];
        GTLApiForecastMessageSpotList *savedSpotList =
        [GTLApiForecastMessageSpotList objectWithJSON:json];
        self.spotList = savedSpotList;
        [self.tableView reloadData];
        return;
    }
    [self lock];
    
    GTLServiceApi *service = [[GTLServiceApi alloc] init];
    service.retryEnabled = YES;
    GTLApiUserMessageSession *session = [[UserManager sharedManager] currentUser].session;
    GTLQueryApi *query = [GTLQueryApi queryForUserForecastsWithObject:session];
    
    [service executeQuery:query completionHandler:^(GTLServiceTicket *ticket,
        GTLApiForecastMessageSpotList *obj, NSError *error){
        [self unlock];
        DLOG(@"%@", obj.spots);
        self.spotList = obj;
        if (error){
            DLOG(@"%@", [error localizedDescription]);
            if ([[NSUserDefaults standardUserDefaults] objectForKey:kSavedForecasts]){
                NSMutableDictionary *json = [NSMutableDictionary dictionaryWithDictionary:
                 [[NSUserDefaults standardUserDefaults] objectForKey:kSavedForecasts]];
                GTLApiForecastMessageSpotList *savedSpotList =
                    [GTLApiForecastMessageSpotList objectWithJSON:json];
                self.spotList = savedSpotList;
            }
        } else {
            
            [[NSUserDefaults standardUserDefaults] setObject:obj.JSON forKey:kSavedForecasts];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
        if (self.spotList){
            [self.tableView reloadData];
        } else {
            showErrorAlertView(error, NSLocalizedString(@"NoInternetErrorMessage", ));
        }
    }];
}


#pragma mark - IBActions
- (IBAction)logout:(id)sender
{
    [[UserManager sharedManager] logout];
}

- (IBAction)reload:(id)sender
{
    DLOG(@"TODO");
    self.cellList = nil;
//    [self.webView stopLoading];
//    [self.webView reload];
}

#pragma mark - Getters

- (NSMutableDictionary*)cellList
{
    if (!_cellList){
        _cellList = [NSMutableDictionary dictionary];
    }
    return _cellList;
}


#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.spotList.spots count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.cellList[indexPath]){
        return self.cellList[indexPath];
    }
    CellForecast *cell = [CellForecast loadFromNib];
    cell.spot = self.spotList.spots[indexPath.row];
    
    cell.backgroundView = nil;
    cell.selectedBackgroundView = nil;
    cell.backgroundColor = [UIColor clearColor];
    
    self.cellList[indexPath] = cell;
    return cell;
}

@end
