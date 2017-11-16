//
//  NSStringPythonAdditions.h
//  XDTools99
//
//  Created by henrik on 17.11.17.
//  Copyright © 2017 hackmac. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <Python/Python.h>


NS_ASSUME_NONNULL_BEGIN
@interface NSString (NSStringPythonAdditions)

+ (nullable instancetype)stringWithPythonString:(PyObject *)pyObj encoding:(NSStringEncoding)enc;

@end
NS_ASSUME_NONNULL_END
