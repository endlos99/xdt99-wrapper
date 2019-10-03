//
//  XDTAs99Symbols.m
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

#import "XDTAs99Symbols.h"

#import <Python/Python.h>


#define XDTClassNameSymbols "Symbols"


NS_ASSUME_NONNULL_BEGIN

@interface XDTAs99Symbols () {
    PyObject *symbolsPythonClass;
}

- (nullable instancetype)initWithPythonInstance:(void *)object;

@end

NS_ASSUME_NONNULL_END


@implementation XDTAs99Symbols

+ (instancetype)symbolsWithPythonInstance:(void *)object
{
    XDTAs99Symbols *retVal = [[XDTAs99Symbols alloc] initWithPythonInstance:object];
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


- (NSDictionary *)symbols
{
    PyObject *symbolDict = PyObject_GetAttrString(symbolsPythonClass, "symbols");
    if (NULL == symbolDict) {
        return nil;
    }

    Py_ssize_t itemCount = PyDict_Size(symbolDict);
    if (0 > itemCount) {
        return nil;
    }
    NSMutableDictionary *retVal = [NSMutableDictionary dictionaryWithCapacity:itemCount];
    PyObject *key, *value;
    Py_ssize_t pos = 0;
    while (PyDict_Next(symbolDict, &pos, &key, &value)) {
        if (NULL != key) {
            [retVal setValue:[NSNumber numberWithLong:PyInt_AsLong(value)] forKey:[NSString stringWithUTF8String:PyString_AsString(key)]];
        }
    }
    Py_DECREF(symbolDict);

    return retVal;
}


- (NSArray *)refdefs
{
    PyObject *refdefsList = PyObject_GetAttrString(symbolsPythonClass, "refdefs");
    if (NULL == refdefsList) {
        return nil;
    }

    const Py_ssize_t itemCount = PyList_Size(refdefsList);
    if (0 > itemCount) {
        return nil;
    }
    NSMutableArray *retVal = [NSMutableArray arrayWithCapacity:itemCount];
    for (int i = 0; i < itemCount; i++) {
        PyObject *name = PyList_GetItem(refdefsList, i);
        if (NULL != name) {
            [retVal addObject:[NSString stringWithUTF8String:PyString_AsString(name)]];
        }
    }
    Py_DECREF(refdefsList);

    return retVal;
}


- (NSDictionary *)xops
{
    PyObject *xopDict = PyObject_GetAttrString(symbolsPythonClass, "xops");
    if (NULL == xopDict) {
        return nil;
    }

    Py_ssize_t itemCount = PyDict_Size(xopDict);
    if (0 > itemCount) {
        return nil;
    }
    NSMutableDictionary *retVal = [NSMutableDictionary dictionaryWithCapacity:itemCount];
    PyObject *key, *value;
    Py_ssize_t pos = 0;
    while (PyDict_Next(xopDict, &pos, &key, &value)) {
        if (NULL != key) {
            [retVal setValue:[NSNumber numberWithLong:PyInt_AsLong(value)] forKey:[NSString stringWithUTF8String:PyString_AsString(key)]];
        }
    }
    Py_DECREF(xopDict);

    return retVal;
}


- (NSDictionary *)locations
{
    PyObject *locationsList = PyObject_GetAttrString(symbolsPythonClass, "locations");
    if (NULL == locationsList) {
        return nil;
    }

    Py_ssize_t itemCount = PyList_Size(locationsList);
    if (0 > itemCount) {
        return nil;
    }
    NSMutableDictionary *retVal = [NSMutableDictionary dictionaryWithCapacity:itemCount];
    for (int i = 0; i < itemCount; i++) {
        PyObject *itemTupel = PyList_GetItem(locationsList, i);
        PyObject *location = PyTuple_GetItem(itemTupel, 0);
        PyObject *name = PyTuple_GetItem(itemTupel, 1);
        if (NULL != name) {
            [retVal setValue:[NSNumber numberWithLong:PyInt_AsLong(location)] forKey:[NSString stringWithUTF8String:PyString_AsString(name)]];
        }
    }
    Py_DECREF(locationsList);

    return retVal;
}


#pragma mark - Method Wrapper


- (void)resetLineCounter
{
    /*
     Function call in Python:
     reset_LC()
     */
    PyObject *methodName = PyString_FromString("reset_LC");
    PyObject *dummy = PyObject_CallMethodObjArgs(symbolsPythonClass, methodName, NULL);
    Py_XDECREF(methodName);
    Py_XDECREF(dummy);
}


- (NSUInteger)effectiveLineCounter
{
    /*
     Function call in Python:
     effective_LC()
     */
    PyObject *methodName = PyString_FromString("effective_LC");
    PyObject *lineCountInteger = PyObject_CallMethodObjArgs(symbolsPythonClass, methodName, NULL);
    Py_XDECREF(methodName);
    if (NULL == lineCountInteger) {
        return NSNotFound;
    }

    NSUInteger retVal = PyInt_AsLong(lineCountInteger);
    Py_DECREF(lineCountInteger);

    return retVal;
}


- (BOOL)addSymbolName:(NSString *)name withValue:(NSUInteger)value
{
    /*
     Function call in Python:
     add_symbol(name, value)
     */
    PyObject *methodName = PyString_FromString("add_symbol");
    PyObject *pSymbolName = PyString_FromString([name UTF8String]);
    PyObject *pSymbolValue = PyInt_FromLong(value);
    PyObject *lineCountInteger = PyObject_CallMethodObjArgs(symbolsPythonClass, methodName, pSymbolName, pSymbolValue, NULL);
    BOOL retVal = lineCountInteger == pSymbolName;
    Py_XDECREF(pSymbolValue);
    Py_XDECREF(pSymbolName);
    Py_XDECREF(methodName);

    return retVal;
}


- (BOOL)addLabel:(NSString *)label withLineIndex:(NSUInteger)lineIdx
{
    return [self addLabel:label withLineIndex:lineIdx usingEffectiveLineCount:NO];
}


- (BOOL)addLabel:(NSString *)label withLineIndex:(NSUInteger)lineIdx usingEffectiveLineCount:(BOOL)realLineCount
{
    /*
     Function call in Python:
     add_label(lidx, label, realLC=False)
     */
    PyObject *methodName = PyString_FromString("add_label");
    PyObject *pLIdx = PyInt_FromLong(lineIdx);
    PyObject *pLabel = PyString_FromString([label UTF8String]);
    PyObject *pRealLC = PyBool_FromLong(realLineCount);
    PyObject *lineCountInteger = PyObject_CallMethodObjArgs(symbolsPythonClass, methodName, pLIdx, pLabel, pRealLC, NULL);
    Py_XDECREF(pRealLC);
    Py_XDECREF(pLabel);
    Py_XDECREF(pLIdx);
    Py_XDECREF(methodName);
    BOOL retVal = NULL != lineCountInteger;

    return retVal;
}


- (BOOL)addLocalLabel:(NSString *)label withLineIndex:(NSUInteger)lineIdx
{
    /*
     Function call in Python:
     add_local_label(lidx, label)
     */
    PyObject *methodName = PyString_FromString("add_local_label");
    PyObject *pLIdx = PyInt_FromLong(lineIdx);
    PyObject *pLabel = PyString_FromString([label UTF8String]);
    PyObject *lineCountInteger = PyObject_CallMethodObjArgs(symbolsPythonClass, methodName, pLIdx, pLabel, NULL);
    Py_XDECREF(pLabel);
    Py_XDECREF(pLIdx);
    Py_XDECREF(methodName);
    BOOL retVal = NULL != lineCountInteger;

    return retVal;
}


- (BOOL)addDef:(NSString *)name
{
    /*
     Function call in Python:
     add_def(name)
     */
    PyObject *methodName = PyString_FromString("add_def");
    PyObject *pName = PyString_FromString([name UTF8String]);
    PyObject *lineCountInteger = PyObject_CallMethodObjArgs(symbolsPythonClass, methodName, pName, NULL);
    Py_XDECREF(pName);
    Py_XDECREF(methodName);
    BOOL retVal = NULL != lineCountInteger;

    return retVal;
}


- (BOOL)addRef:(NSString *)name
{
    /*
     Function call in Python:
     add_ref(name)
     */
    PyObject *methodName = PyString_FromString("add_ref");
    PyObject *pName = PyString_FromString([name UTF8String]);
    PyObject *lineCountInteger = PyObject_CallMethodObjArgs(symbolsPythonClass, methodName, pName, NULL);
    Py_XDECREF(pName);
    Py_XDECREF(methodName);
    BOOL retVal = NULL != lineCountInteger;

    return retVal;
}


- (BOOL)addXop:(NSString *)name mode:(NSUInteger)mode
{
    /*
     Function call in Python:
     add_XOP(name, mode)
     */
    PyObject *methodName = PyString_FromString("add_XOP");
    PyObject *pName = PyString_FromString([name UTF8String]);
    PyObject *pMode = PyInt_FromLong(mode);
    PyObject *lineCountInteger = PyObject_CallMethodObjArgs(symbolsPythonClass, methodName, pName, pMode, NULL);
    Py_XDECREF(pMode);
    Py_XDECREF(pName);
    Py_XDECREF(methodName);
    BOOL retVal = NULL != lineCountInteger;

    return retVal;
}


- (NSUInteger)getSymbol:(NSString *)name
{
    /*
     Function call in Python:
     get_symbol(name)
     */
    PyObject *methodName = PyString_FromString("get_symbol");
    PyObject *pName = PyString_FromString([name UTF8String]);
    PyObject *symbolValueInteger = PyObject_CallMethodObjArgs(symbolsPythonClass, methodName, pName, NULL);
    Py_XDECREF(pName);
    Py_XDECREF(methodName);
    if (NULL == symbolValueInteger) {
        return NSNotFound;
    }

    NSUInteger retVal = PyInt_AsLong(symbolValueInteger);
    Py_DECREF(symbolValueInteger);

    return retVal;
}


- (NSUInteger)getLocal:(NSString *)name position:(NSUInteger)lpos distance:(NSUInteger)distance
{
    /*
     Function call in Python:
     get_local(name, lpos, distance)
     */
    PyObject *methodName = PyString_FromString("get_local");
    PyObject *pName = PyString_FromString([name UTF8String]);
    PyObject *pLpos = PyInt_FromLong(lpos);
    PyObject *pDistance = PyInt_FromLong(distance);
    PyObject *localValueInteger = PyObject_CallMethodObjArgs(symbolsPythonClass, methodName, pName, pLpos, pDistance, NULL);
    Py_XDECREF(pDistance);
    Py_XDECREF(pLpos);
    Py_XDECREF(pName);
    Py_XDECREF(methodName);
    if (NULL == localValueInteger) {
        return NSNotFound;
    }

    NSUInteger retVal = PyInt_AsLong(localValueInteger);
    Py_DECREF(localValueInteger);

    return retVal;
}

@end
