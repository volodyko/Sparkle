//
//  SUInatllationHelper.h
//  Sparkle
//
//  Created by Volodimir Moskaliuk on 1/23/18.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol SUInstallationHelper <NSObject>

- (nullable NSString *)performTaskWithLaunchPath:(nullable NSString *)aPath
									   arguments:(nonnull NSArray *)anArguments
										   error:(NSError * __autoreleasing _Nonnull * _Nullable)anError;

@end

NS_ASSUME_NONNULL_END
