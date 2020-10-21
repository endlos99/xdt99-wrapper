//
//  XDTAs99DelayedAddress.m
//  XDTools99
//
//  Created by Henrik Wedekind on 17.07.19.
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

#import "XDTAs99DelayedAddress.h"

#import <Python/Python.h>

#import "NSStringPythonAdditions.h"


#define XDTClassNameDelayedAddress "DelayedAddress"


NS_ASSUME_NONNULL_BEGIN

@interface XDTAs99DelayedAddress ()

- (instancetype)initWithPythonInstance:(PyObject *)object;

@end

NS_ASSUME_NONNULL_END


@implementation XDTAs99DelayedAddress

+ (NSString *)pythonClassName
{
    return [NSString stringWithUTF8String:XDTClassNameDelayedAddress];
}


+ (instancetype)delayedAddressWithPythonInstance:(PyObject *)object
{
    XDTAs99DelayedAddress *retVal = [[XDTAs99DelayedAddress alloc] initWithPythonInstance:object];
#if !__has_feature(objc_arc)
    [retVal autorelease];
#endif
    return retVal;
}


- (instancetype)initWithPythonInstance:(PyObject *)object
{
    self = [super initWithPythonInstance:object];
    if (nil == self) {
        return nil;
    }

    // nothing to do here

    return self;
}


- (void)dealloc
{
#if !__has_feature(objc_arc)
    [super dealloc];
#endif
}


#pragma mark - Property Wrapper


- (NSUInteger)addr
{
    PyObject *addr = PyObject_GetAttrString(self.pythonInstance, "addr");
    if (NULL == addr) {
        return NSNotFound;
    }

    NSUInteger retVal = PyLong_AsUnsignedLong(addr);
    return retVal;
}


- (NSString *)name
{
    PyObject *name = PyObject_GetAttrString(self.pythonInstance, "name");
    if (NULL == name) {
        return nil;
    }

    NSString *retVal = [NSString stringWithPythonString:name encoding:NSUTF8StringEncoding];
    return retVal;
}


- (NSUInteger)size
{
    PyObject *addr = PyObject_GetAttrString(self.pythonInstance, "size");
    if (NULL == addr) {
        return NSNotFound;
    }

    NSUInteger retVal = PyLong_AsUnsignedLong(addr);
    return retVal;
}


- (NSUInteger)value
{
    PyObject *val = PyObject_GetAttrString(self.pythonInstance, "value");
    if (NULL == val) {
        return NSNotFound;
    }

    NSUInteger retVal = PyLong_AsUnsignedLong(val);
    return retVal;
}


#pragma mark - Method Wrapper


- (void)patch:(NSUInteger)addr
{
    PyObject *methodName = PyString_FromString("patch");
    PyObject *pAddr = PyLong_FromUnsignedLong(addr);
    (void)PyObject_CallMethodObjArgs(self.pythonInstance, methodName, pAddr, NULL);
    Py_XDECREF(pAddr);
    Py_XDECREF(methodName);
}

@end
