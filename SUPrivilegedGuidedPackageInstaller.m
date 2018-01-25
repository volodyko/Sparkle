//
//  SUPrivilegedGuidedPackageInstaller.m
//  Sparkle
//
//  Created by Volodimir Moskaliuk on 1/25/18.
//

#import "SUPrivilegedGuidedPackageInstaller.h"
#import "SUInstalationHelperManager.h"
#import "SULog.h"


@implementation SUPrivilegedGuidedPackageInstaller

+ (void)finishInstallationWithInfo:(NSDictionary *)info
{
	[self finishInstallationToPath:[info objectForKey:SUPackageInstallerInstallationPathKey] withResult:YES host:[info objectForKey:SUPackageInstallerHostKey] error:nil delegate:[info objectForKey:SUPackageInstallerDelegateKey]];
}

+ (void)performInstallationToPath:(NSString *)installationPath fromPath:(NSString *)packagePath host:(SUHost *)host delegate:delegate synchronously:(BOOL)synchronously versionComparator:(id <SUVersionComparison>)comparator
{
	__block NSString *installerPath = [packagePath stringByReplacingOccurrencesOfString:@" " withString:@"\\ "];

	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		NSError* error = nil;
		int connectionResult = [[SUInstalationHelperManager manager] establishHelperConnection];
		if(connectionResult != HELPER_INSTALLED_ERROR_EXIT_CODE)
		{
			BOOL res = [[SUInstalationHelperManager manager] performInstallWithPackagePath:installerPath];
			SULog(@"result is %hhd", res);
		}
		else
		{
			NSString* errorMessage = [NSString stringWithFormat:@"Sparkle Updater: Script authorization denied."];
			error = [NSError errorWithDomain:SUSparkleErrorDomain code:SUInstallationError userInfo:[NSDictionary dictionaryWithObject:errorMessage forKey:NSLocalizedDescriptionKey]];
		}
		
		dispatch_async(dispatch_get_main_queue(), ^{
			NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:host, SUPackageInstallerHostKey, delegate, SUPackageInstallerDelegateKey, installationPath, SUPackageInstallerInstallationPathKey, nil];
			if (synchronously)
				[self performSelectorOnMainThread:@selector(finishInstallationWithInfo:) withObject:info waitUntilDone:NO];
			else
				[NSThread detachNewThreadSelector:@selector(finishInstallationWithInfo:) toTarget:self withObject:info];
		});
	});
}

@end
