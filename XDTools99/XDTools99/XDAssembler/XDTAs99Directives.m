//
//  XDTAs99Directives.m
//  XDTools99
//
//  Created by Henrik Wedekind on 18.07.19.
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

#import "XDTAs99Directives.h"

#import <Python/Python.h>

#import "XDTAs99Parser.h"
#import "XDTAs99Objcode.h"
#import "XDTAssembler.h"

#import "NSArrayPythonAdditions.h"
#import "NSErrorPythonAdditions.h"
#import "NSStringPythonAdditions.h"


#define XDTClassNameDirectives "Directives"


NS_ASSUME_NONNULL_BEGIN

@interface XDTAs99Directives ()

- (instancetype)initWithModule:(PyObject *)pModule;

@end

NS_ASSUME_NONNULL_END


@implementation XDTAs99Directives

+ (NSString *)pythonClassName
{
    return [NSString stringWithUTF8String:XDTClassNameDirectives];
}


static XDTAs99Directives *_sharedDirectives = nil;

+ (instancetype)directives
{
    if (nil != _sharedDirectives) {
        return _sharedDirectives;
    }

    @synchronized (self) {
        PyObject *pModule = self.xdtAs99ModuleInstance;
        if (NULL == pModule) {
            return nil;
        }

        _sharedDirectives = [[XDTAs99Directives alloc] initWithModule:pModule];
#if !__has_feature(objc_arc)
        return [sharedDirectives autorelease];
#else
        return _sharedDirectives;
#endif
    }
}


- (instancetype)initWithModule:(PyObject *)pModule
{
    assert(NULL != pModule);

    PyObject *directivesClass = PyObject_GetAttrString(pModule, XDTClassNameDirectives);
    if (NULL == directivesClass || !PyCallable_Check(directivesClass)) {
        NSLog(@"%s ERROR: Cannot find class \"%s\" in module %s", __FUNCTION__, XDTClassNameDirectives, PyModule_GetName(pModule));
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


static NSArray<NSString *> *_sharedIgnored = nil;

- (NSArray<NSString *> *)ignored
{
    if (nil != _sharedIgnored) {
        return _sharedIgnored;
    }

    PyObject *pVar = PyObject_GetAttrString(self.pythonInstance, "ignores");
    if (NULL == pVar || !PyList_Check(pVar)) {
        NSLog(@"%s ERROR: Cannot get ignores array", __FUNCTION__);
        if (PyErr_Occurred()) {
            PyErr_Print();
        }
        Py_XDECREF(pVar);
        _sharedIgnored = nil;
    } else {
        _sharedIgnored = [NSArray arrayWithPythonList:pVar];
    }

    return _sharedIgnored;
}


#pragma mark - Method Wrapper


- (BOOL)checkDirective:(NSString *)directive
{
    int retVal = PyObject_HasAttrString(self.pythonInstance, directive.UTF8String);
    return 1 == retVal;
}


- (BOOL)processCode:(XDTAs99Objcode *)code withParser:(XDTAs99Parser *)parser label:(NSString *)label mnemonic:(NSString *)mnemonic operands:(NSArray<id> *)operands error:(NSError **)error
{
    // process(parser, code, label, mnemonic, operands)
    PyObject *methodName = PyString_FromString("process");
    PyObject *pLabel = label.asPythonType;
    PyObject *pMnemonic = mnemonic.asPythonType;
    PyObject *pOperands = operands.asPythonType;
    PyObject *pResult = PyObject_CallMethodObjArgs(self.pythonInstance, methodName, parser.pythonInstance, code.pythonInstance, pLabel, pMnemonic, pOperands, NULL);
    Py_XDECREF(pOperands);
    Py_XDECREF(pMnemonic);
    Py_XDECREF(pLabel);
    Py_XDECREF(methodName);
    if (NULL == pResult) {
        NSLog(@"%s ERROR: process(parser, code, %@, %@, []) returns NULL!", __FUNCTION__, label, mnemonic);
        PyObject *exeption = PyErr_Occurred();
        if (NULL != exeption) {
            if (nil != error) {
                *error = [NSError errorWithPythonError:exeption localizedRecoverySuggestion:nil];
            }
            PyErr_Print();
        }
        return NO;
    }

    BOOL retVal = PyObject_IsTrue(pResult);
    Py_DECREF(pResult);
    return retVal;
}

@end
