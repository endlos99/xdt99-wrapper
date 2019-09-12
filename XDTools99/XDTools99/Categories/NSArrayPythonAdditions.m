//
//  NSArrayPythonAdditions.m
//  XDTools99
//
//  Created by Henrik Wedekind on 04.12.16.
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

#import "NSArrayPythonAdditions.h"

#import "NSDataPythonAdditions.h"
#import "NSStringPythonAdditions.h"


@implementation NSArray (NSArrayPythonAdditions)

+ (nullable instancetype)arrayWithPyTuple:(PyObject *)dataTuple
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
                NSArray *object = [NSArray arrayWithPyList:dataItem];
                [retVal addObject:object];
            } else if (PyTuple_Check(dataItem)) {
                NSArray *object = [NSArray arrayWithPyTuple:dataItem];
                [retVal addObject:object];
            } else if (Py_None == dataItem) {
                NSNull *object = [NSNull null];
                [retVal addObject:object];
            } else {
                PyTypeObject *dataType = dataItem->ob_type;
                NSLog(@"%s ERROR: Cannot convert Python type '%s' to an Objective-C type", __FUNCTION__, dataType->tp_name);
            }
        }
    }

    return retVal;
}


+ (nullable instancetype)arrayWithPyList:(PyObject *)dataList
{
    assert(NULL != dataList);

    const Py_ssize_t dataCount = PyList_Size(dataList);
    if (0 > dataCount) {
        return nil;
    }
    NSMutableArray<id> *retVal = [NSMutableArray arrayWithCapacity:dataCount];
    if (nil == retVal) {
        return nil;
    }
    for (Py_ssize_t i = 0; i < dataCount; i++) {
        PyObject *dataItem = PyList_GetItem(dataList, i);
        if (NULL != dataItem) {
            if (PyInt_Check(dataItem)) {
                NSNumber *object = [NSNumber numberWithLong:PyInt_AsLong(dataItem)];
                [retVal addObject:object];
            } else if (PyString_Check(dataItem)) {
                NSData *object = [NSData dataWithPythonString:dataItem];
                [retVal addObject:object];
            } else if (PyList_Check(dataItem)) {
                NSArray *object = [NSArray arrayWithPyList:dataItem];
                [retVal addObject:object];
            } else if (PyTuple_Check(dataItem)) {
                NSArray *object = [NSArray arrayWithPyTuple:dataItem];
                [retVal addObject:object];
            } else if (Py_None == dataItem) {
                NSNull *object = [NSNull null];
                [retVal addObject:object];
            } else {
                PyTypeObject *dataType = dataItem->ob_type;
                NSLog(@"%s ERROR: Cannot convert Python type '%s' to an Objective-C type", __FUNCTION__, dataType->tp_name);
            }
        }
    }

    return retVal;
}


+ (nullable instancetype)arrayWithPyListOfTuple:(PyObject *)dataList
{
    assert(NULL != dataList);

    const Py_ssize_t dataCount = PyList_Size(dataList);
    if (0 > dataCount) {
        return nil;
    }
    PyObject *dataItem = PyList_GetItem(dataList, 0);
    if (!PyTuple_Check(dataItem)) {
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
        }
    }

    return retVal;
}


+ (nullable instancetype)arrayWithPyListOfData:(PyObject *)dataList
{
    assert(NULL != dataList);

    const Py_ssize_t dataCount = PyList_Size(dataList);
    if (0 > dataCount) {
        return nil;
    }
    PyObject *dataItem = PyList_GetItem(dataList, 0);
    if (!PyString_Check(dataItem)) {
        return nil;
    }
    NSMutableArray<NSData *> *retVal = [NSMutableArray arrayWithCapacity:dataCount];
    if (nil == retVal) {
        return nil;
    }
    for (Py_ssize_t i = 0; i < dataCount; i++) {
        PyObject *dataItem = PyList_GetItem(dataList, i);
        if (NULL != dataItem) {
            NSData *imageData = [NSData dataWithPythonString:dataItem];
            if (nil != imageData) {
                [retVal addObject:imageData];
            }
        }
    }
    
    return retVal;
}


+ (nullable instancetype)arrayWithPyListOfString:(PyObject *)dataList
{
    assert(NULL != dataList);

    const Py_ssize_t dataCount = PyList_Size(dataList);
    if (0 > dataCount) {
        return nil;
    }
    NSMutableArray<NSString *> *retVal = [NSMutableArray arrayWithCapacity:dataCount];
    if (nil == retVal) {
        return nil;
    }
    for (Py_ssize_t i = 0; i < dataCount; i++) {
        PyObject *dataItem = PyList_GetItem(dataList, i);
        if (NULL != dataItem) {
            [retVal addObject:[NSString stringWithPythonString:dataItem encoding:NSUTF8StringEncoding]];
        }
    }

    return retVal;
}

@end
