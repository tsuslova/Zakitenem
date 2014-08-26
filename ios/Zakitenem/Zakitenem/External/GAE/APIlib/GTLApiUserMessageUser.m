/* This file was generated by the ServiceGenerator.
 * The ServiceGenerator is Copyright (c) 2014 Google Inc.
 */

//
//  GTLApiUserMessageUser.m
//

// ----------------------------------------------------------------------------
// NOTE: This file is generated from Google APIs Discovery Service.
// Service:
//   api/v1
// Description:
//   Zakitenem API
// Classes:
//   GTLApiUserMessageUser (0 custom class methods, 11 custom properties)

#import "GTLApiUserMessageUser.h"

#import "GTLApiUserMessageRegion.h"
#import "GTLApiUserMessageSession.h"

// ----------------------------------------------------------------------------
//
//   GTLApiUserMessageUser
//

@implementation GTLApiUserMessageUser
@dynamic birthday, email, friendListIds, gender, login, password, phone, region,
         session, subscriptionEndDate, userpic;

+ (NSDictionary *)propertyToJSONKeyMap {
  NSDictionary *map =
    [NSDictionary dictionaryWithObjectsAndKeys:
      @"friend_list_ids", @"friendListIds",
      @"subscription_end_date", @"subscriptionEndDate",
      nil];
  return map;
}

+ (NSDictionary *)arrayPropertyToClassMap {
  NSDictionary *map =
    [NSDictionary dictionaryWithObject:[NSString class]
                                forKey:@"friend_list_ids"];
  return map;
}

@end
