//
//  XDTException.h
//  XDTools99
//
//  Created by henrik on 17.11.17.
//  Copyright © 2017 hackmac. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface XDTException : NSException

+ (XDTException *)exceptionWithError:(NSError *)error;

@end
