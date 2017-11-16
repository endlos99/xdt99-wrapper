//
//  XDTException.m
//  XDTools99
//
//  Created by henrik on 17.11.17.
//  Copyright © 2017 hackmac. All rights reserved.
//

#import "XDTException.h"

@implementation XDTException

+ (XDTException *)exceptionWithError:(NSError *)error {
    return (XDTException *)[super exceptionWithName:[error domain] reason:nil userInfo:[error userInfo]];
}

@end
