//
//  SUGuidedPackageInstaller.m
//  Sparkle
//
//  Created by Graham Miln on 14/05/2010.
//  Copyright 2010 Dragon Systems Software Limited. All rights reserved.
//

#import "SUGuidedPackageInstaller.h"
#import "SUFileManager.h"


@interface SUGuidedPackageInstaller ()

@property (nonatomic, readonly, copy) NSString *packagePath;
@property (nonatomic, readonly, copy) NSString *installationPath;
@property (nonatomic, readonly, copy) NSString *fileOperationToolPath;

@end

@implementation SUGuidedPackageInstaller

@synthesize packagePath = _packagePath;
@synthesize installationPath = _installationPath;
@synthesize fileOperationToolPath = _fileOperationToolPath;

- (instancetype)initWithPackagePath:(NSString *)packagePath installationPath:(NSString *)installationPath fileOperationToolPath:(NSString *)fileOperationToolPath
{
    self = [super init];
    if (self != nil) {
        _packagePath = [packagePath copy];
        _installationPath = [installationPath copy];
        _fileOperationToolPath = [fileOperationToolPath copy];
    }
    return self;
}

+ (void)finishInstallationWithInfo:(NSDictionary *)info
{
    [self finishInstallationToPath:[info objectForKey:SUPackageInstallerInstallationPathKey] withResult:YES host:[info objectForKey:SUPackageInstallerHostKey] error:nil delegate:[info objectForKey:SUPackageInstallerDelegateKey]];
}

- (BOOL)performInitialInstallation:(NSError * __autoreleasing *)__unused error
{
    return YES;
}

- (BOOL)performFinalInstallationProgressBlock:(nullable void(^)(double))progressBlock error:(NSError * __autoreleasing *)error host:(SUHost *)host delegate:delegate
{
    SUFileManager *fileManager = [SUFileManager fileManagerWithAuthorizationToolPath:self.fileOperationToolPath];
    
    BOOL result =  [fileManager executePackageAtURL:[NSURL fileURLWithPath:self.packagePath] progressBlock:progressBlock error:error];
    if (result) {
        NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys: host, SUPackageInstallerHostKey, delegate, SUPackageInstallerDelegateKey, self.installationPath, SUPackageInstallerInstallationPathKey, nil];
        [self performSelectorOnMainThread:@selector(finishInstallationWithInfo:) withObject:info waitUntilDone:NO];    }
    return result;
}

- (BOOL)canInstallSilently
{
    return YES;
}



@end
