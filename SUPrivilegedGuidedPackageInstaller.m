//
//  SUPrivilegedGuidedPackageInstaller.m
//  Sparkle
//
//  Created by Volodimir Moskaliuk on 1/25/18.
//

#import "SUPrivilegedGuidedPackageInstaller.h"
#import "SUInstalationHelperManager.h"

@implementation SUPrivilegedGuidedPackageInstaller

+ (void)finishInstallationWithInfo:(NSDictionary *)info
{
	[self finishInstallationToPath:[info objectForKey:SUPackageInstallerInstallationPathKey] withResult:YES host:[info objectForKey:SUPackageInstallerHostKey] error:nil delegate:[info objectForKey:SUPackageInstallerDelegateKey]];
}

+ (void)performInstallationToPath:(NSString *)installationPath fromPath:(NSString *)packagePath host:(SUHost *)host delegate:delegate synchronously:(BOOL)synchronously versionComparator:(id <SUVersionComparison>)comparator
{
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		NSError* error = nil;
		
		if([[SUInstalationHelperManager manager] performInstallWithPackagePath:packagePath] != 0)
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
