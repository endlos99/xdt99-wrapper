//
//  NSSetPythonAdditions.m
//  XDTools99
//
//  Created by henrik on 22.06.19.
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

#import "NSSetPythonAdditions.h"

#import <Python/Python.h>

#import "NSObjectPythonAdditions.h"
#import "NSDataPythonAdditions.h"
#import "NSArrayPythonAdditions.h"
#import "NSStringPythonAdditions.h"


@implementation NSSet (NSSetPythonAdditions)

+ (nullable NSSet<id> *)setWithPythonTuple:(PyObject *)dataTuple
{
    assert(NULL != dataTuple && PyTuple_Check(dataTuple));

    const Py_ssize_t dataCount = PyTuple_Size(dataTuple);
    if (0 > dataCount) {
        return nil;
    }
    NSMutableSet<id> *retVal = [NSMutableSet setWithCapacity:dataCount];
    for (Py_ssize_t i = 0; i < dataCount; i++) {
        PyObject *dataItem = PyTuple_GetItem(dataTuple, i);
        if (NULL != dataItem) {
            id object = [NSObject objectWithPythonObject:dataItem];
            [retVal addObject:object];
        }
    }

    return retVal;
}


+ (nullable NSSet<id> *)setWithPythonList:(PyObject *)dataList
{
    assert(NULL != dataList && PyList_Check(dataList));

    const Py_ssize_t dataCount = PyTuple_Size(dataList);
    if (0 > dataCount) {
        return nil;
    }
    NSMutableSet<id> *retVal = [NSMutableSet setWithCapacity:dataCount];
    for (Py_ssize_t i = 0; i < dataCount; i++) {
        PyObject *dataItem = PyTuple_GetItem(dataList, i);
        if (NULL != dataItem) {
            id object = [NSObject objectWithPythonObject:dataItem];
            [retVal addObject:object];
        }
    }

    return retVal;
}


+ (nullable NSSet<NSArray<id> *> *)setWithPythonListOfTuple:(PyObject *)dataList
{
    assert(NULL != dataList && PyList_Check(dataList));

    const Py_ssize_t dataCount = PyList_Size(dataList);
    if (0 > dataCount) {
        return nil;
    }
    NSMutableSet<NSArray<id> *> *retVal = [NSMutableSet setWithCapacity:dataCount];
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


+ (nullable NSMutableSet<NSData *> *)setWithPythonListOfData:(PyObject *)dataList
{
    assert(NULL != dataList && PyList_Check(dataList));

    const Py_ssize_t dataCount = PyList_Size(dataList);
    if (0 > dataCount) {
        return nil;
    }
    NSMutableSet<NSData *> *retVal = [NSMutableSet setWithCapacity:dataCount];

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


+ (nullable NSMutableSet<NSString *> *)setWithPythonListOfString:(PyObject *)dataList
{
    assert(NULL != dataList && PyList_Check(dataList));

    const Py_ssize_t dataCount = PyList_Size(dataList);
    if (0 > dataCount) {
        return nil;
    }
    NSMutableSet<NSString *> *retVal = [NSMutableSet setWithCapacity:dataCount];
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
    PyObject *retVal = [self.allObjects asPythonType];

    return retVal;
}

@end
