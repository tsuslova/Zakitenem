//
//  UIImage+Tools.m
//  WeatherMap
//
//  Created by Toto on 22.07.14.
//
//

#import "UIImage+Tools.h"

@implementation UIImage (Tools)

CGFloat DegreesToRadians(CGFloat degrees) {return degrees * M_PI / 180;};

- (UIImage *)imageRotatedByDegrees:(CGFloat)degrees scale:(CGFloat)scale
{
	
	CGFloat maximum = MAX(self.size.width, self.size.height);
	
	CGSize rotatedSize = CGSizeMake(maximum*scale, maximum*scale);
	
	
	// Create the bitmap context
	UIGraphicsBeginImageContext(rotatedSize);
	CGContextRef bitmap = UIGraphicsGetCurrentContext();
	
	// Move the origin to the middle of the image so we will rotate and scale around the center.
	CGContextTranslateCTM(bitmap, rotatedSize.width/2, rotatedSize.height/2);
	
	//   // Rotate the image context
	CGContextRotateCTM(bitmap, DegreesToRadians(degrees));
	
	// Now, draw the rotated/scaled image into the context
	CGContextScaleCTM(bitmap, 1.0*scale, -1.0*scale);
	CGContextDrawImage(bitmap, CGRectMake(-self.size.width / 2, -self.size.height / 2, self.size.width, self.size.height), [self CGImage]);
	
	UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	return newImage;
	
}

@end
