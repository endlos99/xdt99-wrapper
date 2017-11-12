//
//  XDTZipFile.m
//  SimpleXDT99
//
//  Created by Henrik Wedekind on 05.12.16.
//
//  XDTools99.framework a collection of Objective-C wrapper for xdt99
//  Copyright © 2016 Henrik Wedekind (aka hackmac). All rights reserved.
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

#import "XDTZipFile.h"

#include <Python/Python.h>

#import "NSErrorPythonAdditions.h"


#define XDTModuleNameZipFile "zipfile"
#define XDTClassNameZipFile "ZipFile"


@interface XDTZipFile() {
    PyObject *zipfilePythonModule;
    PyObject *zipfilePythonClass;
}

- (instancetype)initForWritingToURL:(NSURL *)url forModule:(PyObject *)pModule error:(NSError * _Nullable __autoreleasing *)error;

@end


@implementation XDTZipFile

+ (instancetype)zipFileForWritingToURL:(NSURL *)url error:(NSError * _Nullable __autoreleasing *)error
{
    PyObject *pName = PyString_FromString(XDTModuleNameZipFile);
    PyObject *pModule = PyImport_Import(pName);
    Py_XDECREF(pName);
    if (NULL == pModule) {
        if (PyErr_Occurred()) {
            PyErr_Print();
        }
        return nil;
    }


    XDTZipFile *retVal = [[self alloc] initForWritingToURL:url forModule:pModule error:error];
    Py_DECREF(pModule);
#if !__has_feature(objc_arc)
    [retVal autorelease];
#endif
    return retVal;
}


- (instancetype)initForWritingToURL:(NSURL *)url forModule:(PyObject *)pModule error:(NSError *__autoreleasing  _Nullable *)error
{
    self = [super init];
    if (nil == self) {
        return nil;
    }

    PyObject *pFunc = PyObject_GetAttrString(pModule, XDTClassNameZipFile);
    if (NULL == pFunc || !PyCallable_Check(pFunc)) {
        PyObject *exeption = PyErr_Occurred();
        if (NULL != exeption) {
            if (nil != error) {
                *error = [NSError errorWithPythonError:exeption code:-2
                                    RecoverySuggestion:[NSString stringWithFormat:@"Expecting to find the function \"%s\" in module %s", XDTClassNameZipFile, XDTModuleNameZipFile]];
            }
            PyErr_Print();
        }
        Py_XDECREF(pFunc);
#if !__has_feature(objc_arc)
        [self release];
#endif
        return nil;
    }

    /* preparing parameters */
    PyObject *output = PyString_FromString([[url path] UTF8String]);
    PyObject *mode = PyString_FromString("w");
    /*
     creating ZipFile object:
     zipfile.ZipFile(output, "w")
     */
    PyObject *pArgs = PyTuple_Pack(2, output, mode);
    PyObject *zipfile = PyObject_CallObject(pFunc, pArgs);
    Py_XDECREF(pArgs);
    Py_DECREF(pFunc);
    if (NULL == zipfile) {
        PyObject *exeption = PyErr_Occurred();
        if (NULL != exeption) {
            if (nil != error) {
                *error = [NSError errorWithPythonError:exeption code:-2 RecoverySuggestion:nil];
            }
            PyErr_Print();
        }
#if !__has_feature(objc_arc)
        [self release];
#endif
        return nil;
    }

    zipfilePythonModule = pModule;
    Py_INCREF(zipfilePythonModule);
    zipfilePythonClass = zipfile;

    return self;
}


- (void)dealloc
{
    Py_XDECREF(zipfilePythonClass);
    Py_XDECREF(zipfilePythonModule);

#if !__has_feature(objc_arc)
    [super dealloc];
#endif
}


- (void)writeFile:(NSString *)fileName withData:(NSData *)data
{
    /*
     Function call in Python:
     writestr("layout.xml", layout)
     */
    PyObject *methodName = PyString_FromString("writestr");
    PyObject *pFileName = PyString_FromString([fileName UTF8String]);
    PyObject *pFileData = PyString_FromStringAndSize([data bytes], [data length]);
    PyObject *pValueTupel = PyObject_CallMethodObjArgs(zipfilePythonClass, methodName, pFileName, pFileData, NULL);
    Py_XDECREF(pFileData);
    Py_XDECREF(pFileName);
    Py_XDECREF(methodName);
    if (NULL == pValueTupel) {
        if (PyErr_Occurred()) {
            PyErr_Print();
        }
        return;
    }
    Py_DECREF(pValueTupel);
}

@end
