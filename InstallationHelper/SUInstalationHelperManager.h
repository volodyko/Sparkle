//
//  SUInstalationHelperManager.h
//  Sparkle
//
//  Created by Volodimir Moskaliuk on 1/22/18.
//

#import <Foundation/Foundation.h>
#import "SUInatllationHelper.h"

@interface SUInstalationHelperManager : NSObject<SUInstallationHelper>

+ (instancetype)manager;
- (BOOL) establishHelperConnection;

@end
