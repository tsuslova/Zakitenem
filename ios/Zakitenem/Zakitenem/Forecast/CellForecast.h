//
//  CellForecast.h
//  Zakitenem
//
//  Created by Toto on 02.09.14.
//
//

#import <UIKit/UIKit.h>
#import "GTLApiForecastMessageSpot.h"

@interface CellForecast : UITableViewCell
@property (strong, nonatomic) GTLApiForecastMessageSpot *spot;

@end