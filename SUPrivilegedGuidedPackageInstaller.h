//
//  SUPrivilegedGuidedPackageInstaller.h
//  Sparkle
//
//  Created by Volodimir Moskaliuk on 1/25/18.
//

/*!
 # Sparkle Guided Installations with priviledged helper
 
 A guided installation allows Sparkle to download and install a package (pkg) or multi-package (mpkg) without user interaction.
 
 The installer package is installed using macOS's built-in command line installer, `/usr/sbin/installer`. No installation interface is shown to the user.
 
 A guided installation can be started by applications other than the application being replaced. This is particularly useful where helper applications or agents are used.
 
 */

#import "SUPlainInstaller.h"

NS_ASSUME_NONNULL_BEGIN

@interface SUPrivilegedGuidedPackageInstaller : SUPlainInstaller

@end

NS_ASSUME_NONNULL_END
