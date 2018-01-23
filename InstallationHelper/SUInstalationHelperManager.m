//
//  SUInstalationHelperManager.m
//  Sparkle
//
//  Created by Volodimir Moskaliuk on 1/22/18.
//

#import "SUInstalationHelperManager.h"
#import <ServiceManagement/ServiceManagement.h>
#import "SULog.h"

NSString *const kRAHelperAppName = @"com.zoomsupport.InstallationHelper";
static NSString *const kRAHelperPrompt = @"Please enter your password to install Installation Helper.";

@interface SUInstalationHelperManager()
@end

@implementation SUInstalationHelperManager

+ (instancetype)manager
{
	static SUInstalationHelperManager *sSUHelperManager = nil;
	static dispatch_once_t sToken;
	dispatch_once(&sToken, ^
				  {
					  sSUHelperManager = [self new];
				  });
	return sSUHelperManager;
}

- (BOOL)establishHelperConnection
{
	NSError *error = nil;
	if (![self installHelperApplicationWithPrompt:kRAHelperPrompt error:&error])
	{
		SULog(@"Bless Helper Error: %@", error);
		return NO;
	}
	return YES;
}


- (OSStatus)setupAuthorization:(AuthorizationRef *)anAuthRef withPromt: (NSString *) aPromtString
{
	AuthorizationEnvironment *environment = kAuthorizationEmptyEnvironment;
	
	// Prompt
	AuthorizationItem promptItem =
	{
		kAuthorizationEnvironmentPrompt, 0, NULL, 0
	};
	AuthorizationEnvironment promptEnvironment =
	{
		1, &promptItem
	};
	if ([aPromtString length] > 0)
	{
		environment = &promptEnvironment;
		promptItem.value = (void *)[aPromtString UTF8String];
		promptItem.valueLength = [aPromtString length];
	}
	
	AuthorizationItem authItem =
	{
		.name = kSMRightBlessPrivilegedHelper,
		.valueLength = 0,
		.value = NULL,
		.flags = 0
	};
	
	AuthorizationRights authRights =
	{
		.count = 1,
		.items = &authItem
	};
	
	AuthorizationFlags authFlags =	kAuthorizationFlagDefaults |
	kAuthorizationFlagInteractionAllowed |
	kAuthorizationFlagPreAuthorize |
	kAuthorizationFlagExtendRights;
	
	
	// Obtain the right to install privileged helper tools (kSMRightBlessPrivilegedHelper).
	return AuthorizationCreate(&authRights, environment, authFlags, anAuthRef);;
}

- (BOOL)installHelperApplicationWithPrompt: (NSString *)aPromtString
									 error: (NSError **)aErrorPtr
{
	BOOL result = NO;
	NSError *error = nil;
	AuthorizationRef authRef = NULL;
	OSStatus status = [self setupAuthorization:&authRef withPromt:aPromtString];
	
	if (status == errAuthorizationSuccess)
	{
		/* This does all the work of verifying the helper tool against the application
		 * and vice-versa. Once verification has passed, the embedded launchd.plist
		 * is extracted and placed in /Library/LaunchDaemons and then loaded. The
		 * executable is placed in /Library/PrivilegedHelperTools.
		 */
		SULog(self.className, @"User authorization completed");
		CFErrorRef errorRef = NULL;
		SMJobRemove(kSMDomainSystemLaunchd, (__bridge CFStringRef)kRAHelperAppName, authRef, YES, NULL);
		
		result = SMJobBless(kSMDomainSystemLaunchd, (__bridge CFStringRef)kRAHelperAppName, authRef, &errorRef);
		if (!result)
		{
			error = CFBridgingRelease(errorRef);
		}
	}
	else
	{
		NSDictionary *errorUserInfo = @{ NSLocalizedDescriptionKey : NSLocalizedString(@"Failed to get authorisation.", nil) };
		error = [NSError errorWithDomain: NSOSStatusErrorDomain code: status userInfo: errorUserInfo];
	}
	
	if (!result && (aErrorPtr != NULL))
	{
		*aErrorPtr = error;
	}
	return result;
}


@end
