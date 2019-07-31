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

#import <Python/Python.h>

#import "NSObjectPythonAdditions.h"
#import "NSDataPythonAdditions.h"
#import "NSStringPythonAdditions.h"


@implementation NSArray (NSArrayPythonAdditions)

+ (nullable instancetype)arrayWithPythonTuple:(PyObject *)dataTuple
{
    assert(NULL != dataTuple && PyTuple_Check(dataTuple));

    const Py_ssize_t dataCount = PyTuple_Size(dataTuple);
    if (0 > dataCount) {
        return nil;
    }
    NSMutableArray<id> *retVal = [NSMutableArray arrayWithCapacity:dataCount];
    for (Py_ssize_t i = 0; i < dataCount; i++) {
        PyObject *dataItem = PyTuple_GetItem(dataTuple, i);
        if (NULL != dataItem) {
            id object = [NSObject objectWithPythonObject:dataItem];
            [retVal addObject:object];
        }
    }

    return retVal;
}


+ (nullable instancetype)arrayWithPythonList:(PyObject *)dataList
{
    assert(NULL != dataList && PyList_Check(dataList));

    const Py_ssize_t dataCount = PyList_Size(dataList);
    if (0 > dataCount) {
        return nil;
    }
    NSMutableArray<id> *retVal = [NSMutableArray arrayWithCapacity:dataCount];
    for (Py_ssize_t i = 0; i < dataCount; i++) {
        PyObject *dataItem = PyList_GetItem(dataList, i);
        if (NULL != dataItem) {
            id object = [NSObject objectWithPythonObject:dataItem];
            [retVal addObject:object];
        }
    }

    return retVal;
}


+ (nullable instancetype)arrayWithPythonListOfTuple:(PyObject *)dataList
{
    assert(NULL != dataList && PyList_Check(dataList));

    const Py_ssize_t dataCount = PyList_Size(dataList);
    if (0 > dataCount) {
        return nil;
    }
    NSMutableArray<NSArray<id> *> *retVal = [NSMutableArray arrayWithCapacity:dataCount];
    if (0 == dataCount) {
        return retVal;
    }

    PyObject *dataItem = PyList_GetItem(dataList, 0);
    if (NULL == dataItem || !PyTuple_Check(dataItem)) {
        return retVal;
    }
    for (Py_ssize_t i = 0; i < dataCount; i++) {
        PyObject *dataTupel = PyList_GetItem(dataList, i);
        if (NULL != dataTupel) {
            NSArray<id> *dataArray = [NSArray arrayWithPythonTuple:dataTupel];
            [retVal addObject:dataArray];
        }
    }

    return retVal;
}


+ (nullable instancetype)arrayWithPythonListOfData:(PyObject *)dataList
{
    assert(NULL != dataList && PyList_Check(dataList));

    const Py_ssize_t dataCount = PyList_Size(dataList);
    if (0 > dataCount) {
        return nil;
    }
    PyObject *dataItem = PyList_GetItem(dataList, 0);
    if (!PyString_Check(dataItem)) {
        return nil;
    }
    NSMutableArray<NSData *> *retVal = [NSMutableArray arrayWithCapacity:dataCount];
    if (0 == dataCount) {
        return retVal;
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


+ (nullable instancetype)arrayWithPythonListOfString:(PyObject *)dataList
{
    assert(NULL != dataList && PyList_Check(dataList));

    const Py_ssize_t dataCount = PyList_Size(dataList);
    if (0 > dataCount) {
        return nil;
    }
    NSMutableArray<NSString *> *retVal = [NSMutableArray arrayWithCapacity:dataCount];
    if (0 == dataCount) {
        return retVal;
    }

    PyObject *dataItem = PyList_GetItem(dataList, 0);
    if (NULL == dataItem || !PyString_Check(dataItem)) {
        return retVal;
    }
    for (Py_ssize_t i = 0; i < dataCount; i++) {
        PyObject *dataItem = PyList_GetItem(dataList, i);
        if (NULL != dataItem) {
            [retVal addObject:[NSString stringWithPythonString:dataItem encoding:NSUTF8StringEncoding]];
        }
    }

    return retVal;
}


- (PyObject *)asPythonType
{
    PyObject *retVal = PyList_New(self.count);
    if (NULL == retVal) {
        retVal = Py_None;
        Py_INCREF(retVal);
        return retVal;
    }

    [self enumerateObjectsUsingBlock:^(NSObject *obj, NSUInteger idx, BOOL *stop) {
        PyList_SetItem(retVal, idx, obj.asPythonType);
    }];

    return retVal;
}

@end
