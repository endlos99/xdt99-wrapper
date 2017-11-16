//
//  NSStringPythonAdditions.m
//  XDTools99
//
//  Created by henrik on 17.11.17.
//  Copyright © 2017 hackmac. All rights reserved.
//

#import "NSStringPythonAdditions.h"


@implementation NSString (NSStringPythonAdditions)

+ (instancetype)stringWithPythonString:(PyObject *)pyObj encoding:(NSStringEncoding)enc {
    const char * cString = PyString_AsString(pyObj);
    if (NULL == cString) {
        /* If pyObj is not a string object, try to make a more generic representation. */
        pyObj = PyObject_Str(pyObj);
        cString = PyString_AsString(pyObj);
        Py_XDECREF(pyObj);
    }

    return [NSString stringWithCString:cString encoding:enc];
}

@end
