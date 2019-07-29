//
//  XDTGa99Symbols.m
//  XDTools99
//
//  Created by Henrik Wedekind on 16.07.19.
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

#import "XDTGa99Symbols.h"

#import <Python/Python.h>

#import "NSStringPythonAdditions.h"


#define XDTClassNameSymbols "Symbols"


NS_ASSUME_NONNULL_BEGIN

@interface XDTGa99Symbols () {
    PyObject *symbolsPythonClass;
}

- (nullable instancetype)initWithPythonInstance:(void *)object;

@end

NS_ASSUME_NONNULL_END


@implementation XDTGa99Symbols

+ (instancetype)symbolsWithPythonInstance:(void *)object
{
    XDTGa99Symbols *retVal = [[XDTGa99Symbols alloc] initWithPythonInstance:object];
#if !__has_feature(objc_arc)
    [retVal autorelease];
#endif
    return retVal;
}


- (instancetype)initWithPythonInstance:(void *)object
{
    self = [super init];
    if (nil == self) {
        return nil;
    }

    symbolsPythonClass = object;
    Py_INCREF(symbolsPythonClass);

    return self;
}


- (void)dealloc
{
    Py_CLEAR(symbolsPythonClass);

#if !__has_feature(objc_arc)
    [super dealloc];
#endif
}


#pragma mark - Property Wrapper


- (NSDictionary<NSString *, NSNumber *> *)symbols
{
    PyObject *symbolDict = PyObject_GetAttrString(symbolsPythonClass, "symbols");
    if (NULL == symbolDict) {
        return nil;
    }

    Py_ssize_t itemCount = PyDict_Size(symbolDict);
    if (0 > itemCount) {
        return nil;
    }
    NSMutableDictionary<NSString *, NSNumber *> *retVal = [NSMutableDictionary dictionaryWithCapacity:itemCount];
    PyObject *key, *list;
    Py_ssize_t pos = 0;
    while (PyDict_Next(symbolDict, &pos, &key, &list)) {
        if (NULL != key) {
            long value = PyInt_AsLong(list);
            [retVal setValue:[NSNumber numberWithLong:value] forKey:[NSString stringWithPythonString:key encoding:NSUTF8StringEncoding]];
        }
    }
    Py_DECREF(symbolDict);

    return retVal;
}


- (NSArray<NSString *> *)symbolList
{
    PyObject *symbolDict = PyObject_GetAttrString(symbolsPythonClass, "symbols");
    if (NULL == symbolDict) {
        return nil;
    }

    Py_ssize_t itemCount = PyDict_Size(symbolDict);
    if (0 > itemCount) {
        return nil;
    }
    NSMutableArray<NSString *> *retVal = [NSMutableArray arrayWithCapacity:itemCount];
    PyObject *pKey, *pTuple;
    Py_ssize_t pos = 0;
    // Values for keys are tripel: symbols[name] = (value, weak, unused)
    while (PyDict_Next(symbolDict, &pos, &pKey, &pTuple)) {
        if (NULL != pKey) {
            [retVal addObject:[NSString stringWithPythonString:pKey encoding:NSUTF8StringEncoding]];
        }
    }
    Py_DECREF(symbolDict);

    return retVal;
}

@end