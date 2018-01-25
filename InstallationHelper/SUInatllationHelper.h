//
//  SUInatllationHelper.h
//  Sparkle
//
//  Created by Volodimir Moskaliuk on 1/23/18.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol SUInstallationHelper <NSObject>

- (nullable BOOL *)performInstallWithPackagePath:(nullable NSString *)aPath;

@end

NS_ASSUME_NONNULL_END
