//
//  XDTGPLAssembler.m
//  XDTools99
//
//  Created by Henrik Wedekind on 18.12.16.
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

#import "XDTGPLAssembler.h"

#include <Python/Python.h>

#import "NSErrorPythonAdditions.h"
#import "XDTException.h"
#include "XDTGPLObjcode.h"


#define XDTModuleNameGPLAssembler "xga99"
#define XDTClassNameGPLAssembler "Assembler"


NS_ASSUME_NONNULL_BEGIN
@interface XDTGPLAssembler () {
    const PyObject *assemblerPythonModule;
    PyObject *assemblerPythonClass;
}

@property XDTGPLAssemblerTargetType targetType;
@property XDTGPLAssemblerSyntaxType syntaxType;

- (nullable instancetype)initWithOptions:(NSDictionary<NSString *, id> *)options forModule:(PyObject *)pModule includeURL:(NSArray<NSURL *> *)urls;

- (nullable const char *)syntaxTypeAsCString;
- (nullable const char *)targetTypeAsCString;

@end
NS_ASSUME_NONNULL_END


@implementation XDTGPLAssembler

#pragma mark Initializers

+ (instancetype)gplAssemblerWithOptions:(NSDictionary<NSString *,NSObject *> *)options includeURL:(NSURL *)url
{
    assert(NULL != options);
    assert(nil != url);

    @synchronized (self) {
        PyObject *pName = PyString_FromString(XDTModuleNameGPLAssembler);
        PyObject *pModule = PyImport_Import(pName);
        Py_XDECREF(pName);
        if (NULL == pModule) {
            NSLog(@"ERROR: Importing module '%@' failed!", pName);
            PyObject *exeption = PyErr_Occurred();
            if (NULL != exeption) {
//            if (nil != error) {
//                *error = [NSError errorWithPythonError:exeption code:-2 RecoverySuggestion:nil];
//            }
                PyErr_Print();
                @throw [XDTException exceptionWithError:[NSError errorWithPythonError:exeption code:-2 RecoverySuggestion:nil]];
            }
            return nil;
        }

        BOOL isDirectory;
        if ([[NSFileManager defaultManager] fileExistsAtPath:[url path] isDirectory:&isDirectory]) {
            if (!isDirectory) {
                url = [url URLByDeletingLastPathComponent];
            }
        }
        XDTGPLAssembler *retVal = [[XDTGPLAssembler alloc] initWithOptions:options forModule:pModule includeURL:@[url]];
        Py_DECREF(pModule);
#if !__has_feature(objc_arc)
        return [retVal autorelease];
#endif
        return retVal;
    }
}


- (instancetype)initWithOptions:(NSDictionary<NSString *, id> *)options forModule:(PyObject *)pModule includeURL:(NSArray<NSURL *> *)urls
{
    assert(NULL != pModule);
    assert(nil != urls);

    self = [super init];
    if (nil == self) {
        return nil;
    }

    PyObject *pFunc = PyObject_GetAttrString(pModule, XDTClassNameGPLAssembler);
    if (NULL == pFunc || !PyCallable_Check(pFunc)) {
        NSLog(@"Cannot find function \"%s\" in module %s", XDTClassNameGPLAssembler, PyModule_GetName(pModule));
        if (PyErr_Occurred()) {
            PyErr_Print();
        }
        Py_XDECREF(pFunc);
#if !__has_feature(objc_arc)
        [self release];
#endif
        return nil;
    }

    /* reading option from dictionary */
    _targetType = [[options valueForKey:XDTGPLAssemblerOptionTarget] unsignedIntegerValue];
    _syntaxType = [[options valueForKey:XDTGPLAssemblerOptionStyle] unsignedIntegerValue];
    _aorgAddress = [[options valueForKey:XDTGPLAssemblerOptionAORG] unsignedIntegerValue];
    _gromAddress = [[options valueForKey:XDTGPLAssemblerOptionGROM] unsignedIntegerValue];

    /* preparing parameters */
    PyObject *target = PyString_FromString([self targetTypeAsCString]);
    PyObject *syntax = PyString_FromString([self syntaxTypeAsCString]);
    PyObject *grom = PyInt_FromLong(_gromAddress);
    PyObject *aorg = PyInt_FromLong(_aorgAddress);
    PyObject *includePath = PyList_New(0);
    for (NSURL *url in urls) {
        PyList_Append(includePath, PyString_FromString([[url path] UTF8String]));
    }
    PyObject *defs = PyList_New(0);

    /* creating assembler object:
        asm = Assembler(syntax, grom, aorg, target="", includePath=None, defs=None)
     */
    PyObject *pArgs = PyTuple_Pack(6, syntax, grom, aorg, target, includePath, defs);
    PyObject *assembler = PyObject_CallObject(pFunc, pArgs);
    Py_XDECREF(pArgs);
    Py_XDECREF(pFunc);
    if (NULL == assembler) {
        NSLog(@"ERROR: calling constructor %@(\"%s\", 0x%lx, 0x%lx, \"%s\", %@, None) failed!", pFunc,
              [self syntaxTypeAsCString], _gromAddress, _aorgAddress, [self targetTypeAsCString], urls);
        PyObject *exeption = PyErr_Occurred();
        if (NULL != exeption) {
//            if (nil != error) {
//                *error = [NSError errorWithPythonError:exeption code:-2 RecoverySuggestion:nil];
//            }
            PyErr_Print();
            @throw [XDTException exceptionWithError:[NSError errorWithPythonError:exeption code:-2 RecoverySuggestion:nil]];
        }
#if !__has_feature(objc_arc)
        [self release];
#endif
        return nil;
    }

    assemblerPythonModule = pModule;
    Py_INCREF(assemblerPythonModule);
    assemblerPythonClass = assembler;

    return self;
}


- (void)dealloc
{
    Py_CLEAR(assemblerPythonClass);
    Py_CLEAR(assemblerPythonModule);

#if !__has_feature(objc_arc)
    [super dealloc];
#endif
}


#pragma mark - Accessors


- (const char *)syntaxTypeAsCString
{
    switch (_syntaxType) {
        case XDTGPLAssemblerSyntaxTypeNativeXDT99:
            return "xdt99";
        case XDTGPLAssemblerSyntaxTypeRAGGPL:
            return "rag";
        case XDTGPLAssemblerSyntaxTypeTIImageTool:
            return "mizapf";

        default:
            return NULL;
    }
}


- (const char *)targetTypeAsCString
{
    switch (_targetType) {
        case XDTGPLAssemblerTargetTypePlainByteCode:
            return "gbc";
        case XDTGPLAssemblerTargetTypeHeaderedByteCode:
            return "image";
        case XDTGPLAssemblerTargetTypeMESSCartridge:
            return "cart";

        default:
            return NULL;
    }
}


#pragma mark - Parsing Methods


- (XDTGPLObjcode *)assembleSourceFile:(NSURL *)srcname error:(NSError **)error
{
    return [self assembleSourceFile:srcname pathName:[NSURL fileURLWithPath:@"." isDirectory:YES] error:error];
}


- (XDTGPLObjcode *)assembleSourceFile:(NSURL *)srcname pathName:(NSURL *)pathName error:(NSError **)error
{
    NSString *basename = [srcname lastPathComponent];

    /* calling assembler:
     code, errors = asm.assemble(basename)
     */
    PyObject *methodName = PyString_FromString("assemble");
    PyObject *pbaseName = PyString_FromString([basename UTF8String]);
    PyObject *pValueTupel = PyObject_CallMethodObjArgs(assemblerPythonClass, methodName, pbaseName, NULL);
    Py_XDECREF(pbaseName);
    Py_XDECREF(methodName);
    if (NULL == pValueTupel) {
        NSLog(@"ERROR: assemble(\"%s\") returns NULL!", [basename UTF8String]);
        PyObject *exeption = PyErr_Occurred();
        if (NULL != exeption) {
            if (nil != error) {
                *error = [NSError errorWithPythonError:exeption code:-2 RecoverySuggestion:nil];
            }
            PyErr_Print();
        }
        return nil;
    }

    PyObject *errorList = PyTuple_GetItem(pValueTupel, 1);
    if (NULL != errorList) {
        const Py_ssize_t errCount = PyList_Size(errorList);
        if (0 < errCount) {
            PyObject *unicodeErrorString = PyUnicode_Join(PyString_FromString("\n"), errorList);
            PyObject *completeErrorString = PyUnicode_AsUTF8String(unicodeErrorString);
            Py_XDECREF(unicodeErrorString);
            NSString *errorString = [NSString stringWithUTF8String:PyString_AsString(completeErrorString)];
            Py_XDECREF(completeErrorString);
            if (nil != error) {
                NSDictionary *errorDict = @{
                                            NSLocalizedDescriptionKey: [NSString stringWithFormat:@"Error occured while assembling '%@'", basename],
                                            NSLocalizedRecoverySuggestionErrorKey: [NSString stringWithFormat:@"%@\n%@", errorString, @"Please check all assembler options and try again."]
                                            };
                *error = [NSError errorWithDomain:XDTErrorDomain code:-1 userInfo:errorDict];
            }
            NSLog(@"Error occured while assembling '%@':\n%@", basename, errorString);
        }
    }

    XDTGPLObjcode *retVal = nil;
    PyObject *objectCodeObject = PyTuple_GetItem(pValueTupel, 0);
    if (NULL != objectCodeObject) {
        retVal = [XDTGPLObjcode gplObjectcodeWithPythonInstance:objectCodeObject];
    }

    Py_DECREF(pValueTupel);

    return retVal;
}

@end
