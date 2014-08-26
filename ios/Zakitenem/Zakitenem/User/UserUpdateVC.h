//
//  UserUpdateVC.h
//  Zakitenem
//
//  Created by Toto on 11.08.14.
//
//

#import <UIKit/UIKit.h>
@class GTLApiUserMessageUser;

@protocol UserUpdateDelegate
- (void)userUpdated:(GTLApiUserMessageUser *)user;
@end


@interface UserUpdateVC : UIViewController

- (id)initWithNibName:(NSString*)nibName user:(GTLApiUserMessageUser *)user
             delegate:(id<UserUpdateDelegate>)delegate;

@end
