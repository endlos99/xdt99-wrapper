//
//  XDTAs99Opcodes.m
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

#import "XDTAs99Opcodes.h"

#import <Python/Python.h>

#import "NSDictionaryPythonAdditions.h"


#define XDTClassNameOpcodes "Opcodes"


NS_ASSUME_NONNULL_BEGIN

@interface XDTAs99Opcodes ()

- (instancetype)initWithModule:(PyObject *)pModule;

@end

NS_ASSUME_NONNULL_END


@implementation XDTAs99Opcodes

+ (NSString *)pythonClassName
{
    return [NSString stringWithUTF8String:XDTClassNameOpcodes];
}


static XDTAs99Opcodes *_sharedOpcodes = nil;

+ (XDTAs99Opcodes *)sharedOpcodes
{
    if (nil != _sharedOpcodes) {
        return _sharedOpcodes;
    }

    @synchronized (self) {
        PyObject *pModule = self.xdtAs99ModuleInstance;
        if (NULL == pModule) {
            return nil;
        }

        _sharedOpcodes = [[XDTAs99Opcodes alloc] initWithModule:(PyObject *)pModule];
    }

#if !__has_feature(objc_arc)
    return [_sharedOpcodes autorelease];
#else
    return _sharedOpcodes;
#endif
}


- (instancetype)initWithModule:(PyObject *)pModule
{
    assert(NULL != pModule);

    PyObject *directivesClass = PyObject_GetAttrString(pModule, XDTClassNameOpcodes);
    if (NULL == directivesClass || !PyCallable_Check(directivesClass)) {
        NSLog(@"%s ERROR: Cannot find class \"%s\" in module %s", __FUNCTION__, XDTClassNameOpcodes, PyModule_GetName(pModule));
        if (PyErr_Occurred()) {
            PyErr_Print();
        }
        Py_XDECREF(directivesClass);
#if !__has_feature(objc_arc)
        [self release];
#endif
        return nil;
    }

    self = [super initWithPythonInstance:directivesClass];
    Py_DECREF(directivesClass);
    if (nil == self) {
        return nil;
    }

    return self;
}


- (void)dealloc
{
#if !__has_feature(objc_arc)
    [super dealloc];
#endif
}


#pragma mark - Property Wrapper


/*
 Values of that dictionary are arrays which contains 5 objects: NSNumber, NSNumber, XDTCallback, XDTCallback, XDTAs99Timing
 */
static NSDictionary<NSString *,NSArray<id> *> *_sharedInstructions = nil;

- (NSDictionary<NSString *,NSArray<id> *> *)instructions
{
    if (nil != _sharedInstructions) {
        return _sharedInstructions;
    }

    PyObject *pVar = PyObject_GetAttrString(self.pythonInstance, "opcodes");
    if (NULL == pVar || !PyDict_Check(pVar)) {
        NSLog(@"%s ERROR: Cannot get opcodes dictionary", __FUNCTION__);
        if (PyErr_Occurred()) {
            PyErr_Print();
        }
        _sharedInstructions = nil;
    } else {
        _sharedInstructions = [NSDictionary dictionaryWithPythonDictionary:pVar];
    }
    Py_XDECREF(pVar);

    return _sharedInstructions;
}


static NSDictionary<NSString *,NSArray<id> *> *_sharedPseudoInstructions = nil;

- (NSDictionary<NSString *,NSArray<id> *> *)pseudoInstructions
{
    if (nil != _sharedPseudoInstructions) {
        return _sharedPseudoInstructions;
    }

    PyObject *pVar = PyObject_GetAttrString(self.pythonInstance, "pseudos");
    if (NULL == pVar || !PyDict_Check(pVar)) {
        NSLog(@"%s ERROR: Cannot get pseudos dictionary", __FUNCTION__);
        if (PyErr_Occurred()) {
            PyErr_Print();
        }
        _sharedPseudoInstructions = nil;
    } else {
        _sharedPseudoInstructions = [NSDictionary dictionaryWithPythonDictionary:pVar];
    }
    Py_XDECREF(pVar);

    return _sharedPseudoInstructions;
}


#pragma mark - Method Wrapper

@end
