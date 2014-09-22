/* This file was generated by the ServiceGenerator.
 * The ServiceGenerator is Copyright (c) 2014 Google Inc.
 */

//
//  GTLApiUserMessageUserStatus.m
//

// ----------------------------------------------------------------------------
// NOTE: This file is generated from Google APIs Discovery Service.
// Service:
//   api/v1
// Description:
//   Zakitenem API
// Classes:
//   GTLApiUserMessageUserStatus (0 custom class methods, 9 custom properties)

#import "GTLApiUserMessageUserStatus.h"

#import "GTLApiForecastMessageSpot.h"
#import "GTLApiUserMessageSession.h"

// ----------------------------------------------------------------------------
//
//   GTLApiUserMessageUserStatus
//

@implementation GTLApiUserMessageUserStatus
@dynamic comment, goDate, gpsOn, postDate, session, spot, status, windFrom,
         windTo;

+ (NSDictionary *)propertyToJSONKeyMap {
  NSDictionary *map =
    [NSDictionary dictionaryWithObjectsAndKeys:
      @"go_date", @"goDate",
      @"gps_on", @"gpsOn",
      @"post_date", @"postDate",
      @"wind_from", @"windFrom",
      @"wind_to", @"windTo",
      nil];
  return map;
}

@end
