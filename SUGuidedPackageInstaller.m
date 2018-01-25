//
//  SUGuidedPackageInstaller.m
//  Sparkle
//
//  Created by Graham Miln on 14/05/2010.
//  Copyright 2010 Dragon Systems Software Limited. All rights reserved.
//

#import "SUGuidedPackageInstaller.h"
#import <Security/Security.h>
#import "sys/stat.h"
#import "SUInstalationHelperManager.h"

static BOOL AuthorizationExecuteWithPrivilegesAndWait(AuthorizationRef authorization, const char* executablePath, AuthorizationFlags options, char* const* arguments)
{
	sig_t oldSigChildHandler = signal(SIGCHLD, SIG_DFL);
	BOOL returnValue = YES;
	
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
	/* AuthorizationExecuteWithPrivileges used to support 10.4+; should be replaced with XPC or external process */
	if (AuthorizationExecuteWithPrivileges(authorization, executablePath, options, arguments, NULL) == errAuthorizationSuccess)
#pragma clang diagnostic pop
	{
		int status = 0;
		pid_t pid = wait(&status);
		if (pid == -1 || !WIFEXITED(status) || WEXITSTATUS(status) != 0)
			returnValue = NO;
	}
	else
		returnValue = NO;
	
	signal(SIGCHLD, oldSigChildHandler);
	return returnValue;
}

@implementation SUGuidedPackageInstaller (SUGuidedPackageInstallerAuthentication)

+ (AuthorizationRef)authorizationForExecutable:(NSString*)executablePath
{
	// Get authorization using advice in Apple's Technical Q&A1172
	
	// ...create authorization without specific rights
	AuthorizationRef auth = NULL;
	OSStatus validAuth = AuthorizationCreate(NULL,
											 kAuthorizationEmptyEnvironment,
											 kAuthorizationFlagDefaults,
											 &auth);
	// ...then extend authorization with desired rights
	if ((validAuth == errAuthorizationSuccess) &&
		(auth != NULL))
	{
		char executableFileSystemRepresentation[PATH_MAX];
		[executablePath getFileSystemRepresentation:executableFileSystemRepresentation maxLength:sizeof(executableFileSystemRepresentation)];
		
		// Prepare a right allowing script to execute with privileges
		AuthorizationItem right = {
			.name = kAuthorizationRightExecute,
			.value = executableFileSystemRepresentation,
			.valueLength = strlen(executableFileSystemRepresentation),
		};
		
		// Package up the single right
		AuthorizationRights rights;
		memset(&rights,0,sizeof(rights));
		rights.count = 1;
		rights.items = &right;
		
		// Extend rights to run script
		validAuth = AuthorizationCopyRights(auth,
											&rights,
											kAuthorizationEmptyEnvironment,
											(AuthorizationFlags)
											(kAuthorizationFlagPreAuthorize |
											 kAuthorizationFlagExtendRights |
											 kAuthorizationFlagInteractionAllowed),
											NULL);
		if (validAuth != errAuthorizationSuccess)
		{
			// Error, clean up authorization
			(void) AuthorizationFree(auth,kAuthorizationFlagDefaults);
			auth = NULL;
		}
	}
	
	return auth;
}

@end

@implementation SUGuidedPackageInstaller


+ (void)finishInstallationWithInfo:(NSDictionary *)info
{
	[self finishInstallationToPath:[info objectForKey:SUPackageInstallerInstallationPathKey] withResult:YES host:[info objectForKey:SUPackageInstallerHostKey] error:nil delegate:[info objectForKey:SUPackageInstallerDelegateKey]];
}

+ (void)performInstallationToPath:(NSString *)installationPath fromPath:(NSString *)packagePath host:(SUHost *)host delegate:delegate synchronously:(BOOL)synchronously versionComparator:(id <SUVersionComparison>)comparator
{
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		
		// Preflight
		NSString* installerPath = @"/usr/sbin/installer"; // Mac OS X 10.2+ command line installer tool
		NSError* error = nil;
		
		// Create authorization for installer executable
		BOOL validInstallation = NO;
		AuthorizationRef auth = [self authorizationForExecutable:installerPath];
		if (auth != NULL)
		{
			char pathBuffer[PATH_MAX] = {0};
			[packagePath getFileSystemRepresentation:pathBuffer maxLength:sizeof(pathBuffer)];
			
			// Permission was granted to execute the installer with privileges
			char * const arguments[] = {
				"-pkg",
				pathBuffer,
				"-target",
				"/",
				NULL
			};
			
			validInstallation = AuthorizationExecuteWithPrivilegesAndWait(auth,
																		  [installerPath fileSystemRepresentation],
																		  kAuthorizationFlagDefaults,
																		  arguments);
			// TODO: wait for communications pipe to close via fileno & CFSocketCreateWithNative
			AuthorizationFree(auth,kAuthorizationFlagDefaults);
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
