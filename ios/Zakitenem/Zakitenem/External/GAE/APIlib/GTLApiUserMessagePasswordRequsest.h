/* This file was generated by the ServiceGenerator.
 * The ServiceGenerator is Copyright (c) 2014 Google Inc.
 */

//
//  GTLApiUserMessagePasswordRequsest.h
//

// ----------------------------------------------------------------------------
// NOTE: This file is generated from Google APIs Discovery Service.
// Service:
//   api/v1
// Description:
//   Zakitenem API
// Classes:
//   GTLApiUserMessagePasswordRequsest (0 custom class methods, 2 custom properties)

#if GTL_BUILT_AS_FRAMEWORK
  #import "GTL/GTLObject.h"
#else
  #import "GTLObject.h"
#endif

@class GTLApiUserMessageSession;

// ----------------------------------------------------------------------------
//
//   GTLApiUserMessagePasswordRequsest
//

@interface GTLApiUserMessagePasswordRequsest : GTLObject
@property (retain) GTLApiUserMessageSession *session;
@property (copy) NSString *tool;
@end
