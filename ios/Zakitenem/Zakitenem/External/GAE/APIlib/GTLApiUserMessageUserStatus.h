/* This file was generated by the ServiceGenerator.
 * The ServiceGenerator is Copyright (c) 2014 Google Inc.
 */

//
//  GTLApiUserMessageUserStatus.h
//

// ----------------------------------------------------------------------------
// NOTE: This file is generated from Google APIs Discovery Service.
// Service:
//   api/v1
// Description:
//   Zakitenem API
// Classes:
//   GTLApiUserMessageUserStatus (0 custom class methods, 9 custom properties)

#if GTL_BUILT_AS_FRAMEWORK
  #import "GTL/GTLObject.h"
#else
  #import "GTLObject.h"
#endif

@class GTLApiForecastMessageSpot;
@class GTLApiUserMessageSession;

// ----------------------------------------------------------------------------
//
//   GTLApiUserMessageUserStatus
//

@interface GTLApiUserMessageUserStatus : GTLObject
@property (copy) NSString *comment;
@property (retain) GTLDateTime *goDate;
@property (retain) NSNumber *gpsOn;  // boolValue
@property (retain) GTLDateTime *postDate;
@property (retain) GTLApiUserMessageSession *session;
@property (retain) GTLApiForecastMessageSpot *spot;
@property (retain) NSNumber *status;  // longLongValue
@property (retain) NSNumber *windFrom;  // longLongValue
@property (retain) NSNumber *windTo;  // longLongValue
@end