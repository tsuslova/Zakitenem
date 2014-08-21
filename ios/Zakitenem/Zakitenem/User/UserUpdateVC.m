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
static NSString *const kMaleKiter = @"Кайтер";
static NSString *const kFemaleKiter = @"Кайтерша";

@interface UserUpdateVC ()
//    <UINavigationControllerDelegate,
//     UIImagePickerControllerDelegate,
    <GKImagePickerDelegate,
     UITextFieldDelegate,
     UIPickerViewDelegate,
     UIPickerViewDataSource>

@property (strong, nonatomic) GTLApiUserMessageUser *user;
@property (weak, nonatomic) id<UserUpdateDelegate> delegate;
@property (strong, nonatomic) GTLApiUserMessageRegionList *regionList;

@property (strong, nonatomic) GKImagePicker *imagePicker;
@property (strong, nonatomic) UIView *keyboardHelper;
@property (weak, nonatomic) IBOutlet UIImageView *backgroundImage;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;
@property (weak, nonatomic) IBOutlet UITextField *emailTextField;
@property (weak, nonatomic) IBOutlet UITextField *regionTextField;
@property (weak, nonatomic) IBOutlet UITextField *phoneTextField;
@property (weak, nonatomic) IBOutlet UIButton *btnUserpic;
@property (weak, nonatomic) IBOutlet UIButton *friendsOnlyCheckBox;
@property (strong, nonatomic) IBOutletCollection(UIButton) NSArray *genderButtons;
@property (nonatomic) CGFloat shift;

@end

@implementation UserUpdateVC

#pragma mark - Initialization & view lifecycle

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
    if ([self.user userpicImage]) {
        [self.btnUserpic.imageView setImage:self.user.userpicImage];
    }
    [self.btnUserpic.imageView setContentMode:UIViewContentModeScaleAspectFit];
    [self loadRegions];

    [self makeRegionPicker];
    [self makeKeyboardHelper];
    
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
}

#pragma mark - Utility methods

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

- (void)viewShouldSlide:(BOOL)shouldSlide
         withShiftValue:(CGFloat)shift
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
    
    self.regionTextField.inputView = regionPicker;
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
    return [textFields copy];
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
    typeof(self) __weak wself = self;
    [service executeQuery:query completionHandler:
        ^(GTLServiceTicket *ticket, GTLApiUserMessageRegionList *list, NSError *error) {
            DLOG(@"%@", list);
            if (list) {
                wself.regionList = list;
            }
            DLOG(@"%@", list.possibleRegion);
            if (list.possibleRegion.name) {
                [wself.regionTextField setText:list.possibleRegion.name];
                [wself.user setRegion:list.possibleRegion];
            }
        }];
}

- (void)save
{
    [self lock];
    
    GTLServiceApi *service = [[GTLServiceApi alloc] init];
    service.retryEnabled = YES;
    
    GTLQueryApi *query = [GTLQueryApi queryForUserUpdateWithObject:self.user];
    
    [service executeQuery:query completionHandler:^(GTLServiceTicket *ticket,
                                                    GTLApiUserMessageUser *obj, NSError *error){
        [self unlock];
        [self.delegate userUpdated:self.user];
    }];
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


- (IBAction)save:(id)sender
{
    //[self save];
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
        if ([button.titleLabel.text isEqualToString:kMaleKiter]) {
            self.user.gender = @0;
        } else if ([button.titleLabel.text isEqualToString:kFemaleKiter]) {
            self.user.gender = @1;
        }
    }
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

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    if ([textField isEqual:self.passwordTextField]) {
        [self.user setPassword:[self.passwordTextField.text copy]];
    } else if ([textField isEqual:self.emailTextField]) {
        [self.user setEmail:[self.emailTextField.text copy]];
    } else if ([textField isEqual:self.regionTextField]) {
        for (GTLApiUserMessageRegion *region in [self.regionList regions]) {
            if ([region.name isEqualToString:[self.regionTextField.text copy]]) {
                [self.user setRegion:region];
            }
        }
    } else if ([textField isEqual:self.phoneTextField]) {
        [self.user setPhone:[self.phoneTextField.text copy]];
    }
    [self textFieldShouldReturn:textField];
}

#pragma mark - UIPickerView stack

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return REGION_PICKER_COMPONENTS_NUMBER;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView
numberOfRowsInComponent:(NSInteger)component
{
    return [[self.regionList regions] count];
}

- (void)pickerView:(UIPickerView *)pickerView
      didSelectRow:(NSInteger)row
       inComponent:(NSInteger)component
{
    [self.regionTextField setText:[self pickerView:pickerView
                                       titleForRow:row
                                      forComponent:component]];
}

- (NSString *)pickerView:(UIPickerView *)pickerView
             titleForRow:(NSInteger)row
            forComponent:(NSInteger)component
{
    return [[[self.regionList regions] objectAtIndex:row] name];
}

#pragma mark - GKImagePickerDelegate

- (void)imagePicker:(GKImagePicker *)imagePicker pickedImage:(UIImage *)image
{
    [self dismissViewControllerAnimated:YES completion:nil];
    [self.user setUserpicImage:image];
    [self.btnUserpic setImage:[[self.user userpicImage] copy] forState:UIControlStateNormal];
}

- (void)imagePickerDidCancel:(GKImagePicker *)imagePicker
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
