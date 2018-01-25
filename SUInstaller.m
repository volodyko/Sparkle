//
//  SUInstaller.m
//  Sparkle
//
//  Created by Andy Matuschak on 4/10/08.
//  Copyright 2008 Andy Matuschak. All rights reserved.
//

#import "SUInstaller.h"
#import "SUPlainInstaller.h"
#import "SUPackageInstaller.h"
#import "SUHost.h"
#import "SUConstants.h"
#import "SULog.h"
#import "SUGuidedPackageInstaller.h"
#import "SUPrivilegedGuidedPackageInstaller.h"

@implementation SUInstaller

static NSString*	sUpdateFolder = nil;

+(NSString*)	updateFolder
{
    return sUpdateFolder;
}

+ (BOOL)isAliasFolderAtPath:(NSString *)path
{
    FSRef fileRef;
    OSStatus err = noErr;
    Boolean aliasFileFlag, folderFlag;
    NSURL *fileURL = [NSURL fileURLWithPath:path];
    
    if (FALSE == CFURLGetFSRef((CFURLRef)fileURL, &fileRef))
        err = coreFoundationUnknownErr;
    
    if (noErr == err)
        err = FSIsAliasFile(&fileRef, &aliasFileFlag, &folderFlag);
    
    if (noErr == err)
        return (BOOL)(aliasFileFlag && folderFlag);
    else
        return NO;
}

+ (NSString *)installSourcePathInUpdateFolder:(NSString *)inUpdateFolder forHost:(SUHost *)host isPackage:(BOOL *)isPackagePtr isGuided:(BOOL *)isGuidedPtr isSilent:(BOOL *)isSilentPtr

{
    // Search subdirectories for the application
    NSString	*currentFile,
    *newAppDownloadPath = nil,
    *bundleFileName = [[host bundlePath] lastPathComponent],
    *alternateBundleFileName = [[host name] stringByAppendingPathExtension:[[host bundlePath] pathExtension]];
    BOOL isPackage = NO;
    BOOL isGuided = YES;
	BOOL isSilent = NO;
    NSString *fallbackPackagePath = nil;
    NSDirectoryEnumerator *dirEnum = [[NSFileManager defaultManager] enumeratorAtPath: inUpdateFolder];
    
    [sUpdateFolder release];
    sUpdateFolder = [inUpdateFolder retain];
    
    while ((currentFile = [dirEnum nextObject]))
    {
        NSString *currentPath = [inUpdateFolder stringByAppendingPathComponent:currentFile];
        if ([[currentFile lastPathComponent] isEqualToString:bundleFileName] ||
            [[currentFile lastPathComponent] isEqualToString:alternateBundleFileName]) // We found one!
        {
            isPackage = NO;
            newAppDownloadPath = currentPath;
            break;
        }
        else if ([[currentFile pathExtension] isEqualToString:@"pkg"] ||
                 [[currentFile pathExtension] isEqualToString:@"mpkg"])
        {
            if ([[[currentFile lastPathComponent] stringByDeletingPathExtension] isEqualToString:[bundleFileName stringByDeletingPathExtension]])
            {
                isPackage = YES;
                newAppDownloadPath = currentPath;
                break;
            }
            else
            {
                // Remember any other non-matching packages we have seen should we need to use one of them as a fallback.
                fallbackPackagePath = currentPath;
            }
        }
        else
        {
            // Try matching on bundle identifiers in case the user has changed the name of the host app
            NSBundle *incomingBundle = [NSBundle bundleWithPath:currentPath];
            if(incomingBundle && [[incomingBundle bundleIdentifier] isEqualToString:[[host bundle] bundleIdentifier]])
            {
                isPackage = NO;
                newAppDownloadPath = currentPath;
                break;
            }
        }
        
        // Some DMGs have symlinks into /Applications! That's no good!
        if ([self isAliasFolderAtPath:currentPath])
            [dirEnum skipDescendents];
    }
    
    // We don't have a valid path. Try to use the fallback package.
    
    if (newAppDownloadPath == nil && fallbackPackagePath != nil)
    {
        isPackage = YES;
        newAppDownloadPath = fallbackPackagePath;
    }
    
    if (isPackage) {
        // Guided (or now "normal") installs used to be opt-in (i.e, Sparkle would detect foo.sparkle_guided.pkg or foo.sparkle_guided.mpkg),
        // but to get an interactive (or "unguided") install, the developer now must opt-out of guided installations.
        
        // foo.app -> foo.sparkle_interactive.pkg or foo.sparkle_interactive.mpkg
        if ([[[newAppDownloadPath stringByDeletingPathExtension] pathExtension] isEqualToString:@"sparkle_interactive"]) {
            isGuided = NO;
        }
		
    }
    
    
    if (isPackagePtr) *isPackagePtr = isPackage;
    if (isGuidedPtr) *isGuidedPtr = isGuided;
    return newAppDownloadPath;
}

+ (NSString *)appPathInUpdateFolder:(NSString *)updateFolder forHost:(SUHost *)host
{
    BOOL isPackage = NO;
    NSString *path = [self installSourcePathInUpdateFolder:updateFolder forHost:host isPackage:&isPackage isGuided:nil isSilent:nil];
    return isPackage ? nil : path;
}

+ (void)installFromUpdateFolder:(NSString *)inUpdateFolder overHost:(SUHost *)host installationPath:(NSString *)installationPath delegate:delegate synchronously:(BOOL)synchronously versionComparator:(id <SUVersionComparison>)comparator
{
    BOOL isPackage = NO;
    BOOL isGuided = NO;
	//TODO: Process silent update type
	BOOL isSilent = YES;
    NSString *newAppDownloadPath = [self installSourcePathInUpdateFolder:inUpdateFolder forHost:host isPackage:&isPackage isGuided:&isGuided isSilent:&isSilent];
    if (newAppDownloadPath == nil)
    {
        [self finishInstallationToPath:installationPath withResult:NO host:host error:[NSError errorWithDomain:SUSparkleErrorDomain code:SUMissingUpdateError userInfo:[NSDictionary dictionaryWithObject:@"Couldn't find an appropriate update in the downloaded package." forKey:NSLocalizedDescriptionKey]] delegate:delegate];
    }
    else
    {
        if(isPackage && isGuided)
        {
            //[[SUGuidedPackageInstaller class] performInstallationToPath:installationPath fromPath:newAppDownloadPath host:host delegate:delegate synchronously:synchronously versionComparator:comparator];
			[[SUPrivilegedGuidedPackageInstaller class] performInstallationToPath:installationPath fromPath:newAppDownloadPath host:host delegate:delegate synchronously:synchronously versionComparator:comparator];
        }
        else if(isPackage && !isGuided)
        {
            [[SUPackageInstaller class] performInstallationToPath:installationPath fromPath:newAppDownloadPath host:host delegate:delegate synchronously:synchronously versionComparator:comparator];
        }
		else if(isPackage && isGuided && isSilent)
		{
			[[SUPrivilegedGuidedPackageInstaller class] performInstallationToPath:installationPath fromPath:newAppDownloadPath host:host delegate:delegate synchronously:synchronously versionComparator:comparator];
		}
        else
        {
            [[SUPlainInstaller class] performInstallationToPath:installationPath fromPath:newAppDownloadPath host:host delegate:delegate synchronously:synchronously versionComparator:comparator];
        }
    }
}

+ (void)mdimportInstallationPath:(NSString *)installationPath
{
    // *** GETS CALLED ON NON-MAIN THREAD!
    
    SULog( @"mdimporting" );
    
    NSTask *mdimport = [[[NSTask alloc] init] autorelease];
    [mdimport setLaunchPath:@"/usr/bin/mdimport"];
    [mdimport setArguments:[NSArray arrayWithObject:installationPath]];
    @try
    {
        [mdimport launch];
        [mdimport waitUntilExit];
    }
    @catch (NSException * launchException)
    {
        // No big deal.
        SULog(@"Sparkle Error: %@", [launchException description]);
    }
}


#define		SUNotifyDictHostKey		@"SUNotifyDictHost"
#define		SUNotifyDictErrorKey	@"SUNotifyDictError"
#define		SUNotifyDictDelegateKey	@"SUNotifyDictDelegate"

+ (void)finishInstallationToPath:(NSString *)installationPath withResult:(BOOL)result host:(SUHost *)host error:(NSError *)error delegate:delegate
{
    if (result)
    {
        [self mdimportInstallationPath:installationPath];
        if ([delegate respondsToSelector:@selector(installerFinishedForHost:)])
            [delegate performSelectorOnMainThread: @selector(installerFinishedForHost:) withObject: host waitUntilDone: NO];
    }
    else
    {
        if ([delegate respondsToSelector:@selector(installerForHost:failedWithError:)])
            [self performSelectorOnMainThread: @selector(notifyDelegateOfFailure:) withObject: [NSDictionary dictionaryWithObjectsAndKeys: host, SUNotifyDictHostKey, error, SUNotifyDictErrorKey, delegate, SUNotifyDictDelegateKey, nil] waitUntilDone: NO];
    }		
}


+(void)	notifyDelegateOfFailure: (NSDictionary*)dict
{
    [[dict objectForKey: SUNotifyDictDelegateKey] installerForHost: [dict objectForKey: SUNotifyDictHostKey] failedWithError: [dict objectForKey: SUNotifyDictErrorKey]];
}

@end
