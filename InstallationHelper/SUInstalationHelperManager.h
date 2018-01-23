//
//  SUInstalationHelperManager.h
//  Sparkle
//
//  Created by Volodimir Moskaliuk on 1/22/18.
//

#import <Foundation/Foundation.h>

@interface SUInstalationHelperManager : NSObject

+ (instancetype)manager;
- (BOOL) establishHelperConnection;

@end
