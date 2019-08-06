//
//  XDTObject.m
//  XDTools99
//
//  Created by Henrik Wedekind on 05.12.16.
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

#import "XDTObject.h"

#import <Python/Python.h>


NS_ASSUME_NONNULL_BEGIN

@interface XDTObject () {
    PyObject *_pythonObject;
}

+ (BOOL)importModule:(XDTModuleName)moduleID withVersion:(const char *)requiredVersion;

@end

NS_ASSUME_NONNULL_END


XDTModuleName const XDTAs99ModuleName = "xas99";
XDTModuleName const XDTGa99ModuleName = "xga99";
XDTModuleName const XDTBas99ModuleName = "xbas99";


@implementation XDTObject

/* This initializer sets up python related things. */
+ (void)initialize
{
    if (self != [XDTObject self]) { // protect against multiple calling when subclasses do not implement initialize
        return;
    }
    if (Py_IsInitialized()) {
        return;
    }
    NSArray<NSString *>* modulPathes = @[[[NSBundle mainBundle] resourcePath], [[NSBundle bundleForClass:[self class]] resourcePath]];
    [self reinitializeWithXDTModulePath:[modulPathes componentsJoinedByString:@":"]];
}


+ (NSString *)pythonClassName
{
    [NSException raise:NSGenericException format:@"%s is not implemented. Subclasses should do that.", __FUNCTION__];
    return nil;
}


static PyObject *_xdtAs99ModuleInstance = NULL;

+ (PyObject *)xdtAs99ModuleInstance
{
    if (NULL != _xdtAs99ModuleInstance) {
        return _xdtAs99ModuleInstance;
    }

    (void)[self importModule:XDTAs99ModuleName withVersion:XDTAs99RequiredVersion];

    return _xdtAs99ModuleInstance;
}


static PyObject *_xdtGa99ModuleInstance = NULL;

+ (PyObject *)xdtGa99ModuleInstance
{
    if (NULL != _xdtGa99ModuleInstance) {
        return _xdtGa99ModuleInstance;
    }

    (void)[self importModule:XDTGa99ModuleName withVersion:XDTGa99RequiredVersion];

    return _xdtGa99ModuleInstance;
}


static PyObject *_xdtBas99ModuleInstance = NULL;

+ (PyObject *)xdtBas99ModuleInstance
{
    if (NULL != _xdtBas99ModuleInstance) {
        return _xdtBas99ModuleInstance;
    }

    (void)[self importModule:XDTBas99ModuleName withVersion:XDTBas99RequiredVersion];

    return _xdtBas99ModuleInstance;
}


+ (BOOL)importModule:(XDTModuleName)moduleID withVersion:(const char *)requiredVersion
{
    if (NULL != _xdtAs99ModuleInstance && XDTAs99ModuleName == moduleID) {
        Py_DECREF(_xdtAs99ModuleInstance);
        _xdtAs99ModuleInstance = NULL;
    }
    if (NULL != _xdtGa99ModuleInstance && XDTGa99ModuleName == moduleID) {
        Py_DECREF(_xdtGa99ModuleInstance);
        _xdtGa99ModuleInstance = NULL;
    }
    if (NULL != _xdtBas99ModuleInstance && XDTBas99ModuleName == moduleID) {
        Py_DECREF(_xdtBas99ModuleInstance);
        _xdtBas99ModuleInstance = NULL;
    }

    PyObject *pModule = PyImport_ImportModuleNoBlock(moduleID);
    if (NULL == pModule) {
        NSLog(@"%s ERROR: Importing module '%s' failed! Python path: %s", __FUNCTION__, moduleID, Py_GetPath());
        PyObject *exeption = PyErr_Occurred();
        if (NULL != exeption) {
//            if (nil != error) {
//                *error = [NSError errorWithPythonError:exeption code:-2 RecoverySuggestion:nil];
//            }
            PyErr_Print();
        }
        return NO;
    }

    PyObject *pVar = PyObject_GetAttrString(pModule, "VERSION");
    if (NULL == pVar || !PyString_Check(pVar)) {
        NSLog(@"%s ERROR: Cannot get VERSION string of module %s", __FUNCTION__, moduleID);
        Py_XDECREF(pModule);
        if (PyErr_Occurred()) {
            PyErr_Print();
        }
        Py_XDECREF(pVar);
        return NO;
    }
    if (0 != strcmp(PyString_AsString(pVar), requiredVersion)) {
        NSLog(@"%s ERROR: Wrong module version %s for %s! Required version is %s", __FUNCTION__, PyString_AsString(pVar), moduleID, requiredVersion);
        Py_XDECREF(pVar);
        Py_XDECREF(pModule);
        return NO;
    }
    Py_XDECREF(pVar);

    //Py_INCREF(pModule);   // Ref count is already at 2, should not be increased again
    if (NULL == _xdtAs99ModuleInstance && XDTAs99ModuleName == moduleID) {
        _xdtAs99ModuleInstance = pModule;
    }
    if (NULL == _xdtGa99ModuleInstance && XDTGa99ModuleName == moduleID) {
        _xdtGa99ModuleInstance = pModule;
    }
    if (NULL == _xdtBas99ModuleInstance && XDTBas99ModuleName == moduleID) {
        _xdtBas99ModuleInstance = pModule;
    }

    return NULL != pModule;
}


+ (BOOL)checkInstanceForPythonObject:(PyObject *)pythonObject
{
    //int isInstance = PyObject_IsInstance(pW, pW->ob_type);
    // TODO: This is a bad way to check if an object is an instance of a class to test teir class names.
    NSString *className = [NSString stringWithUTF8String:PyEval_GetFuncName(pythonObject)];
    return [self.pythonClassName isEqualToString:className];
}


+ (void)reinitializeWithXDTModulePath:(NSString *)modulePath
{
    @synchronized (self) {
        Py_Finalize();
        Py_Initialize();

        NSString *pyModulePath = [NSString stringWithFormat:@"%s:%s", Py_GetPath(), [modulePath fileSystemRepresentation]];
        PySys_SetPath((char *)pyModulePath.UTF8String);
    }
}


/* This calss method is deprecated from macOS 10.8 on, but where should it be placed else? */
+ (void)finalize
{
    Py_Finalize();
}

@end


@implementation XDTObject (Private)

- (instancetype)initWithPythonInstance:(PyObject *)object
{
    self = [super init];
    if (nil == self) {
        return nil;
    }

    Py_XINCREF(object);
    _pythonObject = object;

    return self;
}


- (void)dealloc
{
    Py_CLEAR(_pythonObject);

#if !__has_feature(objc_arc)
    [super dealloc];
#endif
}


- (PyObject *)pythonInstance
{
    return _pythonObject;
}

@end
