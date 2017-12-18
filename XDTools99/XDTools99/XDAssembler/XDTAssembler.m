//
//  XDTAssembler.m
//  TIDisk-Manager
//
//  Created by Henrik Wedekind on 01.12.16.
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

#import "XDTAssembler.h"

#include <Python/Python.h>

#import "NSErrorPythonAdditions.h"
#include "XDTObjcode.h"


#define XDTModuleNameAssembler "xas99"
#define XDTClassNameAssembler "Assembler"


NS_ASSUME_NONNULL_BEGIN
@interface XDTObjcode () {
    PyObject *objectcodePythonClass;
}

/**
 *
 * The visibility of all allocators / initializers are effectivly package private!
 * They are only visible for the XDTAssembler. Objects of this class are created by calling any of
 * the assembleSourceFile: methods from an instance of the XDTAssembler class.
 *
 **/

+ (nullable instancetype)objectcodeWithPythonInstance:(void *)object;

- (nullable instancetype)initWithPythonInstance:(PyObject *)object;

@end
NS_ASSUME_NONNULL_END


NS_ASSUME_NONNULL_BEGIN
@interface XDTAssembler () {
    const PyObject *assemblerPythonModule;
    PyObject *assemblerPythonClass;
}

@property NSString *version;
@property BOOL beStrict;
@property BOOL useRegisterSymbols;
@property XDTAssemblerTargetType targetType;
@property (readonly, nullable) const char *targetTypeAsCString;

- (nullable instancetype)initWithOptions:(NSDictionary *)options forModule:(PyObject *)pModule includeURL:(NSArray<NSURL *> *)url;

@end
NS_ASSUME_NONNULL_END


@implementation XDTAssembler

+ (BOOL)checkRequiredModuleVersion
{
    PyObject *pName = PyString_FromString(XDTModuleNameAssembler);
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
        }
        return NO;
    }

    PyObject *pVar = PyObject_GetAttrString(pModule, "VERSION");
    Py_XDECREF(pModule);
    if (NULL == pVar || !PyString_Check(pVar)) {
        NSLog(@"Cannot get version string of module %s", PyModule_GetName(pModule));
        if (PyErr_Occurred()) {
            PyErr_Print();
        }
        Py_XDECREF(pVar);
#if !__has_feature(objc_arc)
        [self release];
#endif
        return NO;
    }
    if (0 != strcmp(PyString_AsString(pVar), XDTAssemblerVersionRequired)) {
        NSLog(@"Wrong Assembler version %s! Required is %s", PyString_AsString(pVar), XDTAssemblerVersionRequired);
        Py_XDECREF(pVar);
#if !__has_feature(objc_arc)
        [self release];
#endif
        return NO;
    }
    
    return YES;
}


#pragma mark Initializers

/* This class method initialize this singleton. It takes care of all python module related things. */
+ (instancetype)assemblerWithOptions:(NSDictionary<NSString *, NSObject *> *)options includeURL:(NSURL *)url
{
    assert(NULL != options);
    assert(nil != url);

    @synchronized (self) {
        PyObject *pName = PyString_FromString(XDTModuleNameAssembler);
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
            }
            return nil;
        }

        BOOL isDirectory;
        if ([[NSFileManager defaultManager] fileExistsAtPath:[url path] isDirectory:&isDirectory]) {
            if (!isDirectory) {
                url = [url URLByDeletingLastPathComponent];
            }
        }
        XDTAssembler *retVal = [[XDTAssembler alloc] initWithOptions:options forModule:pModule includeURL:@[url]];
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

    PyObject *pVar = PyObject_GetAttrString(pModule, "VERSION");
    if (NULL == pVar || !PyString_Check(pVar)) {
        NSLog(@"Cannot get version string of module %s", PyModule_GetName(pModule));
        if (PyErr_Occurred()) {
            PyErr_Print();
        }
        Py_XDECREF(pVar);
#if !__has_feature(objc_arc)
        [self release];
#endif
        return nil;
    }
    if (0 != strcmp(PyString_AsString(pVar), XDTAssemblerVersionRequired)) {
        NSLog(@"Wrong Assembler version %s! Required is %s", PyString_AsString(pVar), XDTAssemblerVersionRequired);
        Py_XDECREF(pVar);
#if !__has_feature(objc_arc)
        [self release];
#endif
        return nil;
    }

    PyObject *pFunc = PyObject_GetAttrString(pModule, XDTClassNameAssembler);
    if (NULL == pFunc || !PyCallable_Check(pFunc)) {
        NSLog(@"Cannot find function \"%s\" in module %s", XDTClassNameAssembler, PyModule_GetName(pModule));
        if (PyErr_Occurred()) {
            PyErr_Print();
        }
        Py_XDECREF(pVar);
        Py_XDECREF(pFunc);
#if !__has_feature(objc_arc)
        [self release];
#endif
        return nil;
    }

    /* reading option from dictionary */
    _targetType = [[options valueForKey:XDTAssemblerOptionTarget] unsignedIntegerValue];
    _beStrict = [[options valueForKey:XDTAssemblerOptionStrict] boolValue];
    _useRegisterSymbols = [[options valueForKey:XDTAssemblerOptionRegister] boolValue];
    _version = [NSString stringWithCString:PyString_AsString(pVar) encoding:NSUTF8StringEncoding];
    Py_XDECREF(pVar);

    /* preparing parameters */
    PyObject *target = PyString_FromString([self targetTypeAsCString]);
    PyObject *addRegisters = PyBool_FromLong(_useRegisterSymbols);
    PyObject *strictMode = PyBool_FromLong(_beStrict);
    PyObject *includePath = PyList_New(0);
    for (NSURL *url in urls) {
        PyList_Append(includePath, PyString_FromString([[url path] UTF8String]));
    }
    PyObject *defs = PyList_New(0);

    /* creating assembler object:
        asm = Assembler(target=target,
                        addRegisters=opts.optr,
                        strictMode=opts.strict,
                        includePath=inclpath,
                        defs=opts.defs or [])
     */
    PyObject *pArgs = PyTuple_Pack(5, target, addRegisters, strictMode, includePath, defs);
    PyObject *assembler = PyObject_CallObject(pFunc, pArgs);
    Py_XDECREF(pArgs);
    Py_XDECREF(pFunc);
    if (NULL == assembler) {
        NSLog(@"ERROR: calling constructor %@(\"%s\", %@, %@, %@, []) failed!", pFunc,
              [self targetTypeAsCString], _useRegisterSymbols? @"true" : @"false", _beStrict? @"true" : @"false", urls);
        PyObject *exeption = PyErr_Occurred();
        if (NULL != exeption) {
//            if (nil != error) {
//                *error = [NSError errorWithPythonError:exeption code:-2 RecoverySuggestion:nil];
//            }
            PyErr_Print();
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


- (const char *)targetTypeAsCString
{
    switch (_targetType) {
        case XDTAssemblerTargetTypeRawBinary:
            return "bin";
        case XDTAssemblerTargetTypeTextBinary:
            return "text";
        case XDTAssemblerTargetTypeObjectCode:
            return "obj";
        case XDTAssemblerTargetTypeProgramImage:
            return "image";
        case XDTAssemblerTargetTypeEmbededXBasic:
            return "xb";
        case XDTAssemblerTargetTypeMESSCartridge:
            return "cart";
        case XDTAssemblerTargetTypeJumpstart:
            return "js";

        default:
            return NULL;
    }
}


#pragma mark - Parsing Methods


- (XDTObjcode *)assembleSourceFile:(NSURL *)srcname error:(NSError **)error
{
    return [self assembleSourceFile:srcname pathName:[NSURL fileURLWithPath:@"." isDirectory:YES] error:error];
}


- (XDTObjcode *)assembleSourceFile:(NSURL *)srcname pathName:(NSURL *)pathName error:(NSError **)error
{
    NSString *dirname = [[srcname URLByDeletingLastPathComponent] path];
    NSString *basename = [srcname lastPathComponent];

    /* calling assembler:
        code, errors = asm.assemble(dirname, basename)
     */
    PyObject *methodName = PyString_FromString("assemble");
    PyObject *pDirName = PyString_FromString([dirname UTF8String]);
    PyObject *pbaseName = PyString_FromString([basename UTF8String]);
    PyObject *pValueTupel = PyObject_CallMethodObjArgs(assemblerPythonClass, methodName, pDirName, pbaseName, NULL);
    Py_XDECREF(pbaseName);
    Py_XDECREF(pDirName);
    Py_XDECREF(methodName);
    if (NULL == pValueTupel) {
        NSLog(@"ERROR: assemble(\"%s\", \"%s\") returns NULL!", [dirname UTF8String], [basename UTF8String]);
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
        /* TODO: Errors should be shown to the user! */
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
                                            NSLocalizedFailureReasonErrorKey: errorString,
                                            NSLocalizedRecoverySuggestionErrorKey: @"Please check all assembler options and try again."
                                            };
                *error = [NSError errorWithDomain:XDTErrorDomain code:-1 userInfo:errorDict];
            }
            NSLog(@"Error occured while assembling '%@':\n%@", basename, errorString);
        }
    }

    XDTObjcode *retVal = nil;
    PyObject *objectCodeObject = PyTuple_GetItem(pValueTupel, 0);
    if (NULL != objectCodeObject) {
        retVal = [XDTObjcode objectcodeWithPythonInstance:objectCodeObject];
    }

    Py_DECREF(pValueTupel);

    return retVal;
}

@end
