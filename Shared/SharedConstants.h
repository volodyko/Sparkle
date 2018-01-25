//
//  SharedConstants.h
//  Sparkle
//
//  Created by Volodimir Moskaliuk on 1/23/18.
//


extern NSString * const kSUInstallHelperParameter;

typedef NS_ENUM(NSInteger, InstallStatus) {
	HELPER_INSTALLED_DEFAULT_EXIT_CODE = 0,
	HELPER_INSTALLED_EXIST_EXIT_CODE = 1,
	HELPER_INSTALLED_SUCCESS_EXIT_CODE = 2,
	HELPER_INSTALLED_ERROR_EXIT_CODE = 3,
};
