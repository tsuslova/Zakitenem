//
//  UserUpdateVC.m
//  Zakitenem
//
//  Created by Toto on 11.08.14.
//
//

#import "UserUpdateVC.h"

#import "UIViewController+Lock.h"
#import "UserManager.h"

// GKImagePicker

#import "GKImagePicker.h"

#import <UIAlertView-Blocks/UIAlertView+Blocks.h>

//GAE
#import "GTLServiceApi.h"
#import "GTLQueryApi.h"
#import "GTLErrorObject.h"
#import "GTLApiUserMessageUser.h"
#import "GTLApiUserMessageRegionList.h"
#import "GTLApiUserMessageRegion.h"

#import "GTLApiUserMessageUser+Wrapper.h"

// A little magic for the custom input type height would be equal to default keyboard height
static float const PICKER_HEIGHT_PROPORTION = 0.45;
static NSInteger const REGION_PICKER_COMPONENTS_NUMBER = 1;
static CGFloat const KEYBOARD_HELPER_HEIGHT = 30;
static int const kMaleKiterTag = 1;
static int const kFemaleKiterTag = 2;

static NSString *const kPasswordDefaultText = @"**********";

@interface UserUpdateVC ()
//    <UINavigationControllerDelegate,
//     UIImagePickerControllerDelegate,
    <GKImagePickerDelegate,
     UITextFieldDelegate,
     UIPickerViewDelegate,
     UIPickerViewDataSource>

@property (strong, nonatomic) GTLApiUserMessageUser *user;
@property (copy, nonatomic) NSDictionary *notChangedUserJSON;
@property (weak, nonatomic) id<UserUpdateDelegate> delegate;
@property (strong, nonatomic) GTLApiUserMessageRegionList *regionList;

@property (strong, nonatomic) GKImagePicker *imagePicker;
@property (strong, nonatomic) UIView *keyboardHelper;
@property (weak, nonatomic) IBOutlet UIImageView *backgroundImage;

@property (weak, nonatomic) IBOutlet UITextField *tfPassword;
@property (weak, nonatomic) IBOutlet UITextField *tfEmail;
@property (weak, nonatomic) IBOutlet UITextField *tfRegion;
@property (weak, nonatomic) IBOutlet UITextField *tfPhone;
@property (weak, nonatomic) IBOutlet UITextField *tfBirthday;

@property (weak, nonatomic) IBOutlet UIButton *btnUserpic;
@property (weak, nonatomic) IBOutlet UIButton *friendsOnlyCheckBox;
@property (strong, nonatomic) IBOutletCollection(UIButton) NSArray *genderButtons;
@property (nonatomic) CGFloat shift;

@end

@implementation UserUpdateVC

#pragma mark - Initialization & view lifecycle

- (id)init
{
    assert("Use designated initializer");
    return nil;
}

- (id)initWithNibName:(NSString*)nibName user:(GTLApiUserMessageUser *)user
             delegate:(id<UserUpdateDelegate>)delegate
{
    self = [super initWithNibName:nibName bundle:nil];
    if (self) {
        _user = user;
        _notChangedUserJSON = [user.JSON copy];
        _delegate = delegate;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.btnUserpic.imageView setContentMode:UIViewContentModeScaleAspectFit];
    [self loadRegions];

    [self makeRegionPicker];
    [self makeKeyboardHelper];
    [self showUserData];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillShowNotification
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillHideNotification
                                                  object:nil];
    
    if ([self checkNeedSaveUser]){
        [self save:NO];
    }
}

#pragma mark - Utility methods
- (void)showUserData
{
    if (!self.user){
        return;
    }
    self.tfEmail.text = self.user.email;
    self.tfPhone.text = self.user.phone;
    //Show default text in password field to show that the password was already set
    if (self.user.password){
        self.tfPassword.text = kPasswordDefaultText;
    }
    self.tfRegion.text = self.user.region.name;
    if ([self.user userpicImage]) {
        [self.btnUserpic.imageView setImage:self.user.userpicImage];
    }
}

- (void)keyboardWillShow:(NSNotification *)keyboardNotification
{
    NSDictionary *info = [keyboardNotification userInfo];
    CGRect keyboardFrame = [[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    NSValue *animationDurationValue = [info objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    NSTimeInterval animationDuration = 0;
    [animationDurationValue getValue:&animationDuration];

    for (UIView *view in [self.view subviews]) {
        if ([view isFirstResponder]) {
            if (view.origin.y + view.size.height >= keyboardFrame.origin.y) {
                self.shift = (-1) * (view.origin.y + view.height - keyboardFrame.origin.y);
            }
        }
    }
    
    BOOL shouldSlideUp = NO;
    if (self.view.frame.origin.y >=0) {
        shouldSlideUp = YES;
    }
    [self viewShouldSlide:shouldSlideUp
           withShiftValue:self.shift
     andAnimationDuration:animationDuration];
}

- (void)keyboardWillHide:(NSNotification *)keyboardNotification
{
    NSDictionary *info = [keyboardNotification userInfo];
    NSValue *animationDurationValue = [info objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    NSTimeInterval animationDuration = 0;
    [animationDurationValue getValue:&animationDuration];

    [self viewShouldSlide:YES
           withShiftValue:(-1) * self.shift
     andAnimationDuration:animationDuration];
    self.shift = 0;
}

- (void)viewShouldSlide:(BOOL)shouldSlide withShiftValue:(CGFloat)shift
   andAnimationDuration:(NSTimeInterval)animationDuration
{
    if (shouldSlide) {
        [UIView animateWithDuration:animationDuration
                              delay:0.0
                            options:UIViewAnimationOptionAllowUserInteraction
                         animations:^{
                             self.view.frame = (CGRect) {
                                 self.view.frame.origin.x,
                                 self.view.frame.origin.y + shift,
                                 self.view.frame.size.width,
                                 self.view.frame.size.height
                             };
                         }
                         completion:nil];
    }
}

- (void)makeRegionPicker
{
    UIPickerView *regionPicker = [[UIPickerView alloc] initWithFrame:(CGRect) {
        self.view.origin.x,
        self.view.size.height * (1 - PICKER_HEIGHT_PROPORTION),
        self.view.size.width,
        self.view.size.height * PICKER_HEIGHT_PROPORTION
    }];
    regionPicker.delegate = self;
    regionPicker.dataSource = self;
    
    self.tfRegion.inputView = regionPicker;
}

- (void)makeKeyboardHelper
{
    UIToolbar *keyboardHelper = [[UIToolbar alloc] init];
    keyboardHelper.bounds = (CGRect) {
        0,
        0,
        self.view.width,
        KEYBOARD_HELPER_HEIGHT
    };
    
    UIBarButtonItem *prevButton = [[UIBarButtonItem alloc]
                                   initWithBarButtonSystemItem:UIBarButtonSystemItemRewind
                                   target:self
                                   action:@selector(prevTextField:)];
    UIBarButtonItem *flexLeft = [[UIBarButtonItem alloc]
                             initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                             target:nil
                             action:nil];
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc]
                                   initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                   target:self
                                   action:@selector(doneWithTextField:)];
    UIBarButtonItem *flexRight = [[UIBarButtonItem alloc]
                                 initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                 target:nil
                                 action:nil];
    UIBarButtonItem *nextButton = [[UIBarButtonItem alloc]
                                   initWithBarButtonSystemItem:UIBarButtonSystemItemFastForward
                                   target:self
                                   action:@selector(nextTextField:)];
    [keyboardHelper setItems:@[ prevButton, flexLeft, doneButton, flexRight, nextButton]];
    
    self.keyboardHelper = keyboardHelper;
    
    for (UIView *view in [self.view subviews]) {
        if ([view isKindOfClass:[UITextField class]]) {
            ((UITextField *)view).inputAccessoryView = self.keyboardHelper;
        }
    }
}

- (void)prevTextField:(UIBarButtonItem *)sender
{
    NSArray *textFields = [self findTextFields];
    for (NSInteger i = 0; i < [textFields count]; i++) {
        if ([textFields[i] isFirstResponder]) {
            [self textFieldDidEndEditing:textFields[i]];
            if (i > 0) {
                [textFields[i - 1] becomeFirstResponder];
                return;
            } else {
                [textFields[[textFields count] - 1] becomeFirstResponder];
                return;
            }
        }
    }
}

- (void)doneWithTextField:(UIBarButtonItem *)sender
{
    for (UIView *view in [self.view subviews]) {
        if ([view isKindOfClass:[UITextField class]] && [view isFirstResponder]) {
            [self textFieldDidEndEditing:(UITextField *)view];
        }
    }
}

- (void)nextTextField:(UIBarButtonItem *)sender
{
    NSArray *textFields = [self findTextFields];
    for (NSInteger i = 0; i < [textFields count]; i++) {
        if ([textFields[i] isFirstResponder]) {
            [self textFieldDidEndEditing:textFields[i]];
            if (i < [textFields count] - 1) {
                [textFields[i + 1] becomeFirstResponder];
                return;
            } else {
                [textFields[0] becomeFirstResponder];
                return;
            }
        }
    }
}

- (NSArray *)findTextFields
{
    NSMutableArray *textFields = [[NSMutableArray alloc] initWithCapacity:4];
    for (UIView *view in [self.view subviews]) {
        if ([view isKindOfClass:[UITextField class]]) {
            [textFields addObject:view];
        }
    }
    return textFields;
}


#pragma mark - Data loading

- (void)loadRegions
{
    GTLServiceApi *service = [[GTLServiceApi alloc] init];
    service.retryEnabled = YES;
    
    GTLQueryApi *query = [GTLQueryApi queryForRegionsList];
    if (self.user.region){
        query.bodyObject = self.user.region;
    } else {
        if ([UserManager sharedManager].userLocation){
            CLLocationCoordinate2D coordinate = [UserManager sharedManager].userLocation.coordinate;
            
            NSDictionary *regionJSON =
                @{@"latitude":[NSString stringWithFormat:@"%f", coordinate.latitude],
                  @"longitude":[NSString stringWithFormat:@"%f", coordinate.longitude]};
            query.JSON = [NSMutableDictionary dictionaryWithDictionary:regionJSON];
        }
    }
    DLOG(@"%@", query);
    typeof(self) __weak wself = self;
    [service executeQuery:query completionHandler:
        ^(GTLServiceTicket *ticket, GTLApiUserMessageRegionList *list, NSError *error) {
            DLOG(@"%@", list);
            if (list) {
                wself.regionList = list;
            }
            DLOG(@"%@", list.possibleRegion);
            //If user region wasn't set yet - use "default" one (possibleRegion)
            if (!self.user.region && list.possibleRegion.name) {
                [wself.tfRegion setText:list.possibleRegion.name];
                [wself.user setRegion:list.possibleRegion];
            }
        }];
}

- (void)save:(BOOL)showActivity
{
    if (showActivity){
        [self lock];
    }
    
    
    GTLServiceApi *service = [[GTLServiceApi alloc] init];
    service.retryEnabled = YES;
    
    GTLQueryApi *query = [GTLQueryApi queryForUserUpdateWithObject:self.user];
    DLOG(@"Save %@", query);
    [service executeQuery:query completionHandler:^(GTLServiceTicket *ticket,
                                                    GTLApiUserMessageUser *obj, NSError *error){
        if (showActivity){
            [self unlock];
        }
        if (error){
            DLOG(@"TODO store userdata locally! %@", [error localizedDescription]);
        }
        self.user = (GTLApiUserMessageUser *)obj;
        if (self.delegate){
            [self.delegate userUpdated:self.user];
        } else {
            [[UserManager sharedManager] loggedIn:self.user];
        }
    }];
}

- (BOOL)checkNeedSaveUser
{
    DLOG(@"%@",self.notChangedUserJSON);
    DLOG(@"%@",self.user.JSON);
    return ![self.notChangedUserJSON isEqualToDictionary:self.user.JSON];
}

#pragma mark - IBActions

- (IBAction)changeUserpic:(id)sender
{
    self.imagePicker = [[GKImagePicker alloc] init];
    self.imagePicker.delegate = self;
    
    //CGFloat sizeCoefficient = self.view.height / self.btnUserpic.height;
    //self.imagePicker.cropSize = CGSizeMake(self.btnUserpic.width * sizeCoefficient, self.view.height);
    
    self.imagePicker.resizeableCropArea = YES;
    
    [self presentViewController:self.imagePicker.imagePickerController animated:YES completion:nil];
}


- (IBAction)savePressed:(id)sender
{
    [self save:YES];
    NSLog(@"%@", self.user);
    NSLog(@"\n%@", self.user.password);
    NSLog(@"\n%@", self.user.email);
    NSLog(@"\n%@", self.user.region.name);
    NSLog(@"\n%@", self.user.phone);
    NSLog(@"\n%@", self.user.gender);

}

- (IBAction)didCheckedFriendsOnlyCheckbox:(UIButton *)sender
{
    [sender setSelected:![sender isSelected]];
}

- (IBAction)didPickGender:(UIButton *)sender
{
    for (UIButton *button in self.genderButtons) {
        if ([button isEqual:sender]) {
            [button setSelected:YES];
        } else {
            [button setSelected:NO];
        }
        if (button.titleLabel.tag == kMaleKiterTag) {
            self.user.gender = @0;
        } else if (button.titleLabel.tag == kFemaleKiterTag) {
            self.user.gender = @1;
        }
    }
}

- (IBAction)skip:(id)sender
{
    [self.delegate userUpdated:self.user];
}

- (IBAction)showFriends:(id)sender
{
    DLOG(@"TODO");
}


- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    for (UIView *view in [self.view subviews]) {
        if ([view isFirstResponder]) {
            [view resignFirstResponder];
        }
    }
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    if ([textField isEqual:self.tfPassword]) {
        DLOG(@"Empty password field before start editing");
        self.tfPassword.text = @"";
    }
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    if ([textField isEqual:self.tfPassword]) {
        DLOG(@"TODO: validate password? if previous password was set - should we check anything??");
        self.user.password = self.tfPassword.text;
    } else if ([textField isEqual:self.tfEmail]) {
        [self validateEmail];
        self.user.email = self.tfEmail.text;
    } else if ([textField isEqual:self.tfRegion]) {
        for (GTLApiUserMessageRegion *region in [self.regionList regions]) {
            if ([region.name isEqualToString:self.tfRegion.text]) {
                self.user.region = region;
            }
        }
    } else if ([textField isEqual:self.tfPhone]) {
        self.user.phone = self.tfPhone.text;
    }
    [self textFieldShouldReturn:textField];
}

#pragma mark - UIPickerView stack

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return REGION_PICKER_COMPONENTS_NUMBER;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return [[self.regionList regions] count];
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row
       inComponent:(NSInteger)component
{
    NSString *regionName = [self pickerView:pickerView titleForRow:row forComponent:component];
    [self.tfRegion setText:regionName];
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row
            forComponent:(NSInteger)component
{
    return [[[self.regionList regions] objectAtIndex:row] name];
}

#pragma mark - GKImagePickerDelegate

- (void)imagePicker:(GKImagePicker *)imagePicker pickedImage:(UIImage *)image
{
    [self dismissViewControllerAnimated:YES completion:nil];
    self.user.userpicImage = image;
    [self.btnUserpic setImage:[self.user userpicImage] forState:UIControlStateNormal];
}

- (void)imagePickerDidCancel:(GKImagePicker *)imagePicker
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (BOOL)validateEmail
{
    BOOL valid = !self.tfEmail.text || [self.tfEmail.text isEqualToString:@""] ||
        [self.tfEmail.text isValidEmail];
    
    if (!valid) {
        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil)
          message:NSLocalizedString(@"EmailError", nil)
          cancelButtonItem:[RIButtonItem itemWithLabel:NSLocalizedString(@"Close", nil)]
          otherButtonItems:nil] show];
    }
    
    return valid;
}

@end
