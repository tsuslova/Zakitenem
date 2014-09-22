/* This file was generated by the ServiceGenerator.
 * The ServiceGenerator is Copyright (c) 2014 Google Inc.
 */

//
//  GTLApiUserMessageUserStatusList.m
//

// ----------------------------------------------------------------------------
// NOTE: This file is generated from Google APIs Discovery Service.
// Service:
//   api/v1
// Description:
//   Zakitenem API
// Classes:
//   GTLApiUserMessageUserStatusList (0 custom class methods, 1 custom properties)

#import "GTLApiUserMessageUserStatusList.h"

#import "GTLApiUserMessageUserStatus.h"

// ----------------------------------------------------------------------------
//
//   GTLApiUserMessageUserStatusList
//

@implementation GTLApiUserMessageUserStatusList
@dynamic statuses;

+ (NSDictionary *)arrayPropertyToClassMap {
  NSDictionary *map =
    [NSDictionary dictionaryWithObject:[GTLApiUserMessageUserStatus class]
                                forKey:@"statuses"];
  return map;
}

@end
