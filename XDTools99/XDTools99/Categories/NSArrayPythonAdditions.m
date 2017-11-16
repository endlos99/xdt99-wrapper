//
//  NSArrayPythonAdditions.m
//  SimpleXDT99
//
//  Created by Henrik Wedekind on 04.12.16.
//
//  XDTools99.framework a collection of Objective-C wrapper for xdt99
//  Copyright © 2016 Henrik Wedekind (aka hackmac). All rights reserved.
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

#import "NSArrayPythonAdditions.h"

#import "NSDataPythonAdditions.h"


@implementation NSArray (NSArrayPythonAdditions)

+ (nullable NSArray<id> *)arrayWithPyTuple:(PyObject *)dataTuple
{
    assert(NULL != dataTuple);

    const Py_ssize_t dataCount = PyTuple_Size(dataTuple);
    if (0 > dataCount) {
        return nil;
    }
    NSMutableArray<id> *retVal = [NSMutableArray arrayWithCapacity:dataCount];
    if (nil == retVal) {
        return nil;
    }
    for (Py_ssize_t i = 0; i < dataCount; i++) {
        PyObject *dataItem = PyTuple_GetItem(dataTuple, i);
        if (NULL != dataItem) {
            if (PyInt_Check(dataItem)) {
                NSNumber *object = [NSNumber numberWithLong:PyInt_AsLong(dataItem)];
                [retVal addObject:object];
            } else if (PyString_Check(dataItem)) {
                NSData *object = [NSData dataWithPythonString:dataItem];
                [retVal addObject:object];
            } else if (PyList_Check(dataItem)) {
                NSArray *object = [NSArray arrayWithPyTuple:dataItem];
                [retVal addObject:object];
            } else if (PyTuple_Check(dataItem)) {
                NSArray *object = [NSArray arrayWithPyTuple:dataItem];
                [retVal addObject:object];
            } else if (Py_None == dataItem) {
                NSNull *object = [NSNull null];
                [retVal addObject:object];
            } else {
                PyTypeObject *dataType = dataItem->ob_type;
                NSLog(@"Cannot convert Python type '%s' to an Objective-C type", dataType->tp_name);
            }
            Py_DECREF(dataItem);
        }
    }

    return retVal;
}


+ (nullable NSArray<NSArray<id> *> *)arrayWithPyListOfTuple:(PyObject *)dataList
{
    assert(NULL != dataList);

    const Py_ssize_t dataCount = PyList_Size(dataList);
    if (0 > dataCount) {
        return nil;
    }
    NSMutableArray<NSArray<id> *> *retVal = [NSMutableArray arrayWithCapacity:dataCount];
    if (nil == retVal) {
        return nil;
    }
    for (Py_ssize_t i = 0; i < dataCount; i++) {
        PyObject *dataTupel = PyList_GetItem(dataList, i);
        if (NULL != dataTupel) {
            NSArray<id> *dataArray = [NSArray arrayWithPyTuple:dataTupel];
            [retVal addObject:dataArray];
            Py_DECREF(dataTupel);
        }
    }

    return retVal;
}


+ (nullable NSMutableArray<NSData *> *)arrayWithPyListOfString:(PyObject *)dataList
{
    assert(NULL != dataList);

    const Py_ssize_t dataCount = PyList_Size(dataList);
    if (0 > dataCount) {
        return nil;
    }
    NSMutableArray<NSData *> *retVal = [NSMutableArray arrayWithCapacity:dataCount];
    if (nil == retVal) {
        return nil;
    }
    for (Py_ssize_t i = 0; i < dataCount; i++) {
        PyObject *dataItem = PyList_GetItem(dataList, i);
        if (NULL != dataItem) {
            Py_ssize_t codeSize = PyString_Size(dataItem);
            char *codeStr = PyString_AsString(dataItem);
            NSData *imageData = [NSData dataWithBytes:codeStr length:codeSize];
            [retVal addObject:imageData];
            Py_DECREF(dataItem);
        }
    }

    return retVal;
}

@end
