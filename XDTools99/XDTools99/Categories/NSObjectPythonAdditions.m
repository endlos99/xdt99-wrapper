//
//  NSObjectPythonAdditions.m
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

#import "NSObjectPythonAdditions.h"

#import <Python/Python.h>

#import "NSDictionaryPythonAdditions.h"
#import "NSArrayPythonAdditions.h"
#import "NSDataPythonAdditions.h"
#import "NSStringPythonAdditions.h"
#import "NSNumberPythonAdditions.h"

#import "XDTAs99Address.h"
#import "XDTAs99DelayedAddress.h"
#import "XDTAs99ExternalReference.h"
#import "XDTAs99Block.h"
#import "XDTAs99Line.h"

#import "XDTCallback.h"


@implementation NSObject (NSObjectPythonAdditions)

+ (instancetype)objectWithPythonObject:(PyObject *)obj
{
    id object = nil;
    
    if (PyInt_Check(obj)) {
        object = [NSNumber numberWithPythonObject:obj];
    } else if (PyString_Check(obj)) {
        object = [NSData dataWithPythonString:obj];
    } else if (PyList_Check(obj)) {
        object = [NSArray arrayWithPythonList:obj];
    } else if (PyTuple_Check(obj)) {
        object = [NSArray arrayWithPythonTuple:obj];
    } else if (PyDict_Check(obj)) {
        object = [NSDictionary dictionaryWithPythonDictionary:obj];
    } else if (PyCallable_Check(obj)) {
        object = [XDTCallback callableWithPyObject:obj];
    } else if (Py_None == obj) {
        object = [NSNull null];
    } else if ([XDTAs99Address checkInstanceForPythonObject:obj]) {
        object = [XDTAs99Address addressWithPythonInstance:obj];
    } else if ([XDTAs99DelayedAddress checkInstanceForPythonObject:obj]) {
        object = [XDTAs99DelayedAddress delayedAddressWithPythonInstance:obj];
    } else if ([XDTAs99ExternalReference checkInstanceForPythonObject:obj]) {
        object = [XDTAs99ExternalReference referenceWithPythonInstance:obj];
    } else if ([XDTAs99Block checkInstanceForPythonObject:obj]) {
        object = [XDTAs99Block blockWithPythonInstance:obj];
    } else if ([XDTAs99Line checkInstanceForPythonObject:obj]) {
        object = [XDTAs99Line lineWithPythonInstance:obj];
    } else {
        Py_XINCREF(obj);    // Usually all other work with an scalar representation of the Python object or they retain its pointer
        object = [NSValue valueWithPointer:obj];
    }

    NSAssert(nil != object, @"%s EXCEPTION: Cannot create an instance of NSObject for a value of type %s.", __FUNCTION__, obj->ob_type->tp_name);
    return object;
}


- (PyObject *)asPythonType
{
    PyObject *retVal = nil;

    if ([self isKindOfClass:[NSNumber class]]) {
        retVal = [(NSNumber *)self asPythonType];
    } else if ([self isKindOfClass:[NSString class]]) {
        retVal = [(NSString *)self asPythonType];
    } else if ([self isKindOfClass:[NSData class]]) {
        retVal = [(NSData *)self asPythonType];
    } else if ([self isKindOfClass:[NSArray class]]) {
        retVal = [(NSArray *)self asPythonType];
    } else if ([self isKindOfClass:[NSSet class]]) {
        retVal = [(NSSet *)self asPythonType];
    } else if ([self isKindOfClass:[NSDictionary class]]) {
        retVal = [(NSDictionary *)self asPythonType];
    } else if ([self isKindOfClass:[XDTObject class]]) {
        retVal = [(XDTObject *)self pythonInstance];
        Py_XINCREF(retVal); // Usually new instances will be created in this method, so increment the reference count for borrowed pointers
    } else if ([self isKindOfClass:[NSValue class]]) {
        retVal = [(NSValue *)self pointerValue];
        Py_XINCREF(retVal); // Usually new instances will be created in this method, so increment the reference count for borrowed pointers
    } else {
        retVal = Py_None;
        Py_INCREF(retVal);
        NSAssert(false, @"%s EXCEPTION: Cannot create an Python instance for an onbject of type %@.", __FUNCTION__, [self className]);
    }

    return retVal;
}

@end
