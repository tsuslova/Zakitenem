//
//  UserUpdateVC.m
//  Zakitenem
//
//  Created by Toto on 11.08.14.
//
//

#import "UserUpdateVC.h"

#import "UIViewController+Lock.h"

//GAE
#import "GTLServiceApi.h"
#import "GTLQueryApi.h"
#import "GTLErrorObject.h"
#import "GTLApiUserMessageUser.h"

#import "GTLApiUserMessageUser+Wrapper.h"

@interface UserUpdateVC () <UINavigationControllerDelegate, UIImagePickerControllerDelegate>
@property (strong, nonatomic) GTLApiUserMessageUser *user;
@property (weak, nonatomic) id<UserUpdateDelegate> delegate;
@property (weak, nonatomic) IBOutlet UIButton *btnUserpic;
@property (weak, nonatomic) IBOutlet UIImageView *ivUserpic;

@end

@implementation UserUpdateVC

- (id)initWithUser:(GTLApiUserMessageUser *)user delegate:(id<UserUpdateDelegate>)delegate
{
    self = [super init];
    if (self) {
        _user = user;
        _delegate = delegate;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.ivUserpic.image = self.user.userpicImage;
}

#pragma mark - IBActions

- (IBAction)changeUserpic:(id)sender
{
    UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
    
    imagePicker.delegate = self;
    imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    imagePicker.allowsEditing = YES;
    [self presentViewController:imagePicker animated:YES completion:nil];
}


- (IBAction)save:(id)sender
{
    [self.delegate userUpdated:self.user];
}

#pragma mark - UIImagePickerControllerDelegate
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    [self dismissViewControllerAnimated:YES completion:nil];
    [self lock];
    UIImage *image = (UIImage*) [info objectForKey:UIImagePickerControllerOriginalImage];

    [self.user setUserpicImage:image];
    
    GTLServiceApi *service = [[GTLServiceApi alloc] init];
    service.retryEnabled = YES;
    
    GTLQueryApi *query = [GTLQueryApi queryForUserUpdateWithObject:self.user];

    [service executeQuery:query completionHandler:^(GTLServiceTicket *ticket,
                                                    GTLApiUserMessageUser *obj, NSError *error){
        [self unlock];
        
        self.ivUserpic.image = obj.userpicImage;
        self.btnUserpic.titleLabel.text = @"";
    }];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    
}

@end
