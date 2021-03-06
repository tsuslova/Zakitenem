/* This file was generated by the ServiceGenerator.
 * The ServiceGenerator is Copyright (c) 2014 Google Inc.
 */

//
//  GTLApiUserMessageRegion.m
//

// ----------------------------------------------------------------------------
// NOTE: This file is generated from Google APIs Discovery Service.
// Service:
//   api/v1
// Description:
//   Zakitenem API
// Classes:
//   GTLApiUserMessageRegion (0 custom class methods, 4 custom properties)

#import "GTLApiUserMessageRegion.h"

// ----------------------------------------------------------------------------
//
//   GTLApiUserMessageRegion
//

@implementation GTLApiUserMessageRegion
@dynamic identifier, latitude, longitude, name;

+ (NSDictionary *)propertyToJSONKeyMap {
  NSDictionary *map =
    [NSDictionary dictionaryWithObject:@"id"
                                forKey:@"identifier"];
  return map;
}

@end
