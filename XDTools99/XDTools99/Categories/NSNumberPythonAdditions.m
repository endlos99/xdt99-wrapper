//
//  NSNumberPythonAdditions.m
//  XDTools99
//
//  Created by Henrik Wedekind on 26.07.19.
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

#import "NSNumberPythonAdditions.h"

#import <Python/Python.h>


@implementation NSNumber (NSNumberPythonAdditions)

+ (instancetype)numberWithPythonObject:(PyObject *)obj
{
    if (PyBool_Check(obj)) {
        return [NSNumber numberWithBool:1 == PyObject_IsTrue(obj)];
    }
    if (PyInt_Check(obj)) {
        return [NSNumber numberWithInt:(int)PyInt_AsLong(obj)];
    }
    if (PyLong_Check(obj)) {
        return [NSNumber numberWithLong:PyLong_AsLong(obj)];
    }
    if (PyFloat_Check(obj)) {
        return [NSNumber numberWithDouble:PyFloat_AsDouble(obj)];
    }
    NSAssert(false, @"%s EXCEPTION: Cannot create an instance of NSNumber for a value of type %s.", __FUNCTION__, obj->ob_type->tp_name);
    return nil;
}


- (PyObject *)asPythonType
{
    PyObject *retVal = NULL;
    CFNumberType numType = CFNumberGetType((CFNumberRef)self);
    switch (numType) {
        case kCFNumberDoubleType:
            retVal = PyFloat_FromDouble(self.doubleValue);
            break;
        case kCFNumberLongType:
        case kCFNumberSInt64Type:
            retVal = PyLong_FromLong(self.longValue);
            break;
        case kCFNumberIntType:
        case kCFNumberSInt32Type:
        case kCFNumberNSIntegerType:
            retVal = PyInt_FromLong(self.intValue);
            break;

        default:
            retVal = PyBool_FromLong(self.boolValue);
            break;
    }

    return retVal;
}

@end
