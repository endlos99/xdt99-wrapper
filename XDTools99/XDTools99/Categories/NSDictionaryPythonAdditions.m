//
//  NSDictionaryPythonAdditions.m
//  XDTools99
//
//  Created by Henrik Wedekind on 18.07.19.
//
//  XDTools99.framework a collection of Objective-C wrapper for xdt99
//  Copyright © 2019 Henrik Wedekind (aka hackmac). All rights reserved.
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

#import "NSDictionaryPythonAdditions.h"

#import <Python/Python.h>

#import "NSObjectPythonAdditions.h"
#import "NSStringPythonAdditions.h"
#import "NSNumberPythonAdditions.h"


@implementation NSDictionary (NSDictionaryPythonAdditions)

+ (instancetype)dictionaryWithPythonDictionary:(PyObject *)dict
{
    assert(nil != dict && PyDict_Check(dict));

    Py_ssize_t itemCount = PyDict_Size(dict);
    if (0 > itemCount) {
        return nil;
    }

    NSMutableDictionary<NSObject *, NSObject *> *retVal = [NSMutableDictionary dictionaryWithCapacity:itemCount];
    PyObject *key, *value;
    Py_ssize_t pos = 0;
    while (PyDict_Next(dict, &pos, &key, &value)) {
        if (NULL == key) {
            break;  // NULL key are for termination
        }
        id k = NSNull.null;
        if (PyInt_Check(key) || PyLong_Check(key)) {
            k = [NSNumber numberWithPythonObject:key];
        } else if (PyString_Check(key)) {
            k = [NSString stringWithPythonString:key encoding:NSUTF8StringEncoding];
        } else {
            Py_XINCREF(key);    // Usually all other work with an scalar representation of the Python object or they retain its pointer
            k = [NSValue valueWithPointer:key];
        }
        [retVal setValue:[NSObject objectWithPythonObject:value] forKey:k];
    }

    return retVal;
}


- (PyObject *)asPythonType
{
    PyObject *retVal = PyDict_New();

    [self enumerateKeysAndObjectsUsingBlock:^(NSObject *key, NSObject *obj, BOOL *stop) {
        PyDict_SetItem(retVal, key.asPythonType, obj.asPythonType);
    }];

    return retVal;
}

@end
