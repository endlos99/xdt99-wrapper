//
//  XDTAs99Address.m
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

#import "XDTAs99Address.h"

#import <Python/Python.h>

#import "NSStringPythonAdditions.h"


#define XDTClassNameAddress "Address"


NS_ASSUME_NONNULL_BEGIN

@interface XDTAs99Address ()

- (instancetype)initWithPythonInstance:(PyObject *)object;

@end

NS_ASSUME_NONNULL_END


@implementation XDTAs99Address

+ (NSString *)pythonClassName
{
    return [NSString stringWithUTF8String:XDTClassNameAddress];
}


+ (instancetype)addressWithPythonInstance:(PyObject *)object
{
    XDTAs99Address *retVal = [[XDTAs99Address alloc] initWithPythonInstance:object];
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


- (NSUInteger)bank
{
    PyObject *bank = PyObject_GetAttrString(self.pythonInstance, "bank");
    if (NULL == bank) {
        return NSNotFound;
    }

    NSUInteger retVal = PyLong_AsUnsignedLong(bank);
    return retVal;
}


- (BOOL)isRelocatable
{
    PyObject *reloc = PyObject_GetAttrString(self.pythonInstance, "relocatable");
    if (NULL == reloc) {
        return NO;
    }

    BOOL retVal = 1 == PyObject_IsTrue(reloc);
    return retVal;
}


#pragma mark - Method Wrapper


- (NSString *)hex
{
    PyObject *methodName = PyString_FromString("hex");
    PyObject *hexRepresentation = PyObject_CallMethodObjArgs(self.pythonInstance, methodName, NULL);
    Py_XDECREF(methodName);
    if (NULL == hexRepresentation) {
        return nil;
    }

    NSString *retVal = [NSString stringWithPythonString:hexRepresentation encoding:NSUTF8StringEncoding];
    Py_DECREF(hexRepresentation);

    return retVal;
}

@end
