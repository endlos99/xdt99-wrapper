//
//  NSStringPythonAdditions.m
//  XDTools99
//
//  Created by henrik on 17.11.17.
//  Copyright © 2017 hackmac. All rights reserved.
//

#import "NSStringPythonAdditions.h"


@implementation NSString (NSStringPythonAdditions)

+ (instancetype)stringWithPythonString:(PyObject *const)pyObj encoding:(NSStringEncoding)enc {
    if (NULL == pyObj) {
        return nil;
    }
    const char * cString = PyString_AsString(pyObj);
    if (NULL == cString) {
        /* If pyObj is not a string object, try to make a more generic representation. */
        PyObject *pyStr = PyObject_Str(pyObj);
        cString = PyString_AsString(pyStr);
        Py_XDECREF(pyStr);
    }

    return [NSString stringWithCString:cString encoding:enc];
}

@end
