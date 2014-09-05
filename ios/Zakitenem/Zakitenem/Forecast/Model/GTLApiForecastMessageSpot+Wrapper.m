//
//  GTLApiForecastMessageSpot+Wrapper.m
//  Zakitenem
//
//  Created by Toto on 04.09.14.
//
//

#import "GTLApiForecastMessageSpot+Wrapper.h"

@implementation GTLApiForecastMessageSpot (Wrapper)

- (void)removeCache
{
    if ([[NSFileManager defaultManager] fileExistsAtPath:[self forecastPath]]){
        NSError *error;
        if (![[NSFileManager defaultManager] removeItemAtPath:[self forecastPath] error:&error]){
            NSLog(@"Error: fail to remove cache!");
        }
        
    }
}

- (void)setForecastImage:(UIImage*)image
{
    NSData* data = UIImagePNGRepresentation(image);
    if (![data writeToFile:[self forecastPath] atomically:YES]){
        NSLog(@"Error while writing image: %@",[self forecastPath]);
        NSAssert(NO, @"Error while writing image");
    }
}

- (UIImage*)forecastImage
{
    return [UIImage imageWithContentsOfFile:[self forecastPath]];
}

- (NSString*)forecastPath
{
    NSString *kForecastFolder = @"ForecastFolder";
    NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
        NSUserDomainMask, YES) objectAtIndex:0];
    NSString *path = [documentsDirectory stringByAppendingPathComponent:kForecastFolder];
    NSError *error;
    if (![[NSFileManager defaultManager] fileExistsAtPath:path]){
        [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES
            attributes:nil error:&error];
    }
    path = [path stringByAppendingPathComponent:self.identifier];
//    DLOG(@"%@", path);
    return path;
}
@end
