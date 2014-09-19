//
//  UserUpdateVC.h
//  Zakitenem
//
//  Created by Toto on 11.08.14.
//
//

#import <UIKit/UIKit.h>
#import "TabbedVCProto.h"

@class GTLApiUserMessageUser;

@protocol UserUpdateDelegate
- (void)userUpdated:(GTLApiUserMessageUser *)user saved:(BOOL)isSaved;
@end


@interface UserUpdateVC : UIViewController <TabbedVCProto>

- (id)initWithNibName:(NSString*)nibName user:(GTLApiUserMessageUser *)user
             delegate:(id<UserUpdateDelegate>)delegate;

@end
