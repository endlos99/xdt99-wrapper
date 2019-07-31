//
//  XDTCallback.m
//  XDTools99
//
//  Created by Henrik Wedekind on 25.07.19.
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

#import "XDTCallback.h"

#import <Python/Python.h>

#import "NSObjectPythonAdditions.h"
#import "NSArrayPythonAdditions.h"


NS_ASSUME_NONNULL_BEGIN

@interface XDTCallback () {
    PyObject *_callable;
}

- (instancetype)initWithPyObject:(PyObject *)object;

- (nullable id)callWithPyList:(PyObject *_Nullable)pyList;

@end

NS_ASSUME_NONNULL_END


@implementation XDTCallback

+ (instancetype)callableWithPyObject:(PyObject *)object
{
    XDTCallback *retVal = [[XDTCallback alloc] initWithPyObject:object];
#if !__has_feature(objc_arc)
    return [retVal autorelease];
#else
    return retVal;
#endif
}


- (instancetype)initWithPyObject:(PyObject *)object
{
    self = [super init];
    if (nil == self) {
        return nil;
    }

    Py_XINCREF(object);
    _callable = object;

    return self;
}


- (void)dealloc
{
    Py_CLEAR(_callable);
    
#if !__has_feature(objc_arc)
    [super dealloc];
#endif
}


#pragma mark -


- (PyObject *)pythonInstance
{
    return _callable;
}


- (id)call
{
    return [self callWithPyList:NULL];
}


- (id)callWithArrayOfArguments:(NSArray *)args
{
    PyObject *argTuple = args.asPythonType;
    id retVal = [self callWithPyList:argTuple];
    Py_XDECREF(argTuple);
    return retVal;
}


- (id)callWithArguments:(NSObject *)firstArg, ...
{
    if (nil == firstArg) {
        return [self call];
    }

    PyObject *argTuple = PyList_New(0);
    PyList_Append(argTuple, firstArg.asPythonType);

    va_list argList;
    va_start(argList, firstArg);
    while (nil != (firstArg = va_arg(argList, NSObject *))) {
        PyList_Append(argTuple, firstArg.asPythonType);
    }
    va_end(argList);

    id retVal = [self callWithPyList:argTuple];
    Py_XDECREF(argTuple);
    return retVal;
}


#pragma mark - Private Methods


- (id)callWithPyList:(PyObject *)pyList
{
    PyObject *pArgs = (NULL == pyList)? NULL : PyList_AsTuple(pyList);
    PyObject *result = PyObject_CallObject(_callable, pArgs);
    Py_XDECREF(pArgs);
    if (NULL == result) {
        return nil;
    }

    id retVal = [NSObject objectWithPythonObject:result];
    Py_DECREF(result);
    return retVal;
}

@end
