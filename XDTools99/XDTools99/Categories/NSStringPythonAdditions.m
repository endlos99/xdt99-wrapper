//
//  NSStringPythonAdditions.m
//  XDTools99
//
//  Created by Henrik Wedekind on 17.11.17.
//
//  XDTools99.framework a collection of Objective-C wrapper for xdt99
//  Copyright © 2016-2019 Henrik Wedekind (aka hackmac). All rights reserved.
//
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the GNU Lesser General Public License as
//  published by the Free Software Foundation; either version 2.1 of the
//  License, or (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
//  Lesser General Public License for more details.
//
//  You should have received a copy of the GNU Lesser General Public
//  License along with this program; if not, see <http://www.gnu.org/licenses/>
//

#import "NSStringPythonAdditions.h"

#import <Python/Python.h>


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


- (PyObject *)asPythonType
{
    return PyString_FromString(self.UTF8String);
}

@end
