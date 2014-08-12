//
//  GTLApiUserMessageUser+Wrapper.m
//  Zakitenem
//
//  Created by Toto on 12.08.14.
//
//

#import "GTLApiUserMessageUser+Wrapper.h"
#import "GTLBase64.h"

@implementation GTLApiUserMessageUser (Wrapper)

- (void)setUserpicImage:(UIImage*)image
{
    //TODO: 0.1 -> 1 after image resolution changing
    NSData* data = UIImageJPEGRepresentation(image, 0.1f);
    self.userpic = GTLEncodeBase64(data);
}

- (UIImage*)userpicImage
{
    NSData* data = GTLDecodeBase64(self.userpic);
    return [UIImage imageWithData:data];
}

@end
