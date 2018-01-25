//
//  SUInstalationHelperManager.h
//  Sparkle
//
//  Created by Volodimir Moskaliuk on 1/22/18.
//

#import <Foundation/Foundation.h>
#import "SUInatllationHelper.h"
#import "SharedConstants.h"
@interface SUInstalationHelperManager : NSObject<SUInstallationHelper>

+ (instancetype)manager;

// return
//  HELPER_INSTALLED_EXIST_EXIT_CODE = 1;
//  HELPER_INSTALLED_SUCCESS_EXIT_CODE = 2;
//  HELPER_INSTALLED_ERROR_EXIT_CODE = 3;

- (enum InstallStatus) establishHelperConnection;

@end
