/* This file was generated by the ServiceGenerator.
 * The ServiceGenerator is Copyright (c) 2014 Google Inc.
 */

//
//  GTLApiForecastMessageSpotList.m
//

// ----------------------------------------------------------------------------
// NOTE: This file is generated from Google APIs Discovery Service.
// Service:
//   api/v1
// Description:
//   Zakitenem API
// Classes:
//   GTLApiForecastMessageSpotList (0 custom class methods, 1 custom properties)

#import "GTLApiForecastMessageSpotList.h"

#import "GTLApiForecastMessageSpot.h"

// ----------------------------------------------------------------------------
//
//   GTLApiForecastMessageSpotList
//

@implementation GTLApiForecastMessageSpotList
@dynamic spots;

+ (NSDictionary *)arrayPropertyToClassMap {
  NSDictionary *map =
    [NSDictionary dictionaryWithObject:[GTLApiForecastMessageSpot class]
                                forKey:@"spots"];
  return map;
}

@end