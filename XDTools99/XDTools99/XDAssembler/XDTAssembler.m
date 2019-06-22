//
//  XDTAssembler.m
//  XDTools99
//
//  Created by Henrik Wedekind on 01.12.16.
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

#import "XDTAssembler.h"

#include <Python/Python.h>

#import "NSErrorPythonAdditions.h"
#import "NSArrayPythonAdditions.h"
#import "XDTMessage.h"
#import "XDTAs99Objcode.h"


#define XDTModuleNameAssembler "xas99"
#define XDTClassNameAssembler "Assembler"


NS_ASSUME_NONNULL_BEGIN

@interface XDTAs99Objcode () {
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

- (XDTAs99Objcode *)assembleSourceFile:(NSString *)basename pathName:(NSString *)dirname error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END


NS_ASSUME_NONNULL_BEGIN

XDTAs99OptionKey const XDTAs99OptionRegister = @"XDTAs99OptionRegister";
XDTAs99OptionKey const XDTAs99OptionStrict = @"XDTAs99OptionStrict";
XDTAs99OptionKey const XDTAs99OptionTarget = @"XDTAs99OptionTarget";
XDTAs99OptionKey const XDTAs99OptionWarnings = @"XDTAs99OptionWarnings";


@interface XDTAssembler () {
    const PyObject *assemblerPythonModule;
    PyObject *assemblerPythonClass;
}

@property NSString *version;
@property BOOL beStrict;
@property BOOL useRegisterSymbols;
@property BOOL outputWarnings;
@property XDTAs99TargetType targetType;
@property (readonly, nullable) const char *targetTypeAsCString;

- (nullable instancetype)initWithOptions:(NSDictionary<XDTAs99OptionKey, id> *)options forModule:(PyObject *)pModule includeURL:(NSArray<NSURL *> *)url;

@end

NS_ASSUME_NONNULL_END


@implementation XDTAssembler

+ (BOOL)checkRequiredModuleVersion
{
    PyObject *pName = PyString_FromString(XDTModuleNameAssembler);
    PyObject *pModule = PyImport_Import(pName);
    if (NULL == pModule) {
        NSLog(@"%s ERROR: Importing module '%s' failed! Python path: %s", __FUNCTION__, PyString_AsString(pName), Py_GetPath());
        Py_XDECREF(pName);
        PyObject *exeption = PyErr_Occurred();
        if (NULL != exeption) {
//            if (nil != error) {
//                *error = [NSError errorWithPythonError:exeption RecoverySuggestion:nil];
//            }
            PyErr_Print();
        }
        return NO;
    }
    Py_XDECREF(pName);

    PyObject *pVar = PyObject_GetAttrString(pModule, "VERSION");
    if (NULL == pVar || !PyString_Check(pVar)) {
        NSLog(@"%s ERROR: Cannot get version string of module %s", __FUNCTION__, PyModule_GetName(pModule));
        Py_XDECREF(pModule);
        if (PyErr_Occurred()) {
            PyErr_Print();
        }
        Py_XDECREF(pVar);
#if !__has_feature(objc_arc)
        [self release];
#endif
        return NO;
    }
    Py_XDECREF(pModule);
    if (0 != strcmp(PyString_AsString(pVar), XDTAssemblerVersionRequired)) {
        NSLog(@"%s ERROR: Wrong Assembler version %s! Required is %s", __FUNCTION__, PyString_AsString(pVar), XDTAssemblerVersionRequired);
        Py_XDECREF(pVar);
#if !__has_feature(objc_arc)
        [self release];
#endif
        return NO;
    }
    Py_XDECREF(pVar);

    return YES;
}


#pragma mark Initializers

/* This class method initialize this singleton. It takes care of all python module related things. */
+ (instancetype)assemblerWithOptions:(NSDictionary<XDTAs99OptionKey, id> *)options includeURL:(NSURL *)url
{
    assert(NULL != options);
    assert(nil != url);

    @synchronized (self) {
        PyObject *pModule = PyImport_ImportModuleNoBlock(XDTModuleNameAssembler);
        if (NULL == pModule) {
            NSLog(@"%s ERROR: Importing module '%s' failed! Python path: %s", __FUNCTION__, XDTModuleNameAssembler, Py_GetPath());
            PyObject *exeption = PyErr_Occurred();
            if (NULL != exeption) {
//            if (nil != error) {
//                *error = [NSError errorWithPythonError:exeption RecoverySuggestion:nil];
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


- (instancetype)initWithOptions:(NSDictionary<XDTAs99OptionKey, id> *)options forModule:(PyObject *)pModule includeURL:(NSArray<NSURL *> *)urls
{
    assert(NULL != pModule);
    assert(nil != urls);

    self = [super init];
    if (nil == self) {
        return nil;
    }

    PyObject *pVar = PyObject_GetAttrString(pModule, "VERSION");
    if (NULL == pVar || !PyString_Check(pVar)) {
        NSLog(@"%s ERROR: Cannot get version string of module %s", __FUNCTION__, PyModule_GetName(pModule));
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
        NSLog(@"%s ERROR: Wrong Assembler version %s! Required is %s", __FUNCTION__, PyString_AsString(pVar), XDTAssemblerVersionRequired);
        Py_XDECREF(pVar);
#if !__has_feature(objc_arc)
        [self release];
#endif
        return nil;
    }

    PyObject *pFunc = PyObject_GetAttrString(pModule, XDTClassNameAssembler);
    if (NULL == pFunc || !PyCallable_Check(pFunc)) {
        NSLog(@"%s ERROR: Cannot find class \"%s\" in module %s", __FUNCTION__, XDTClassNameAssembler, PyModule_GetName(pModule));
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
    _targetType = [[options valueForKey:XDTAs99OptionTarget] unsignedIntegerValue];
    _beStrict = [[options valueForKey:XDTAs99OptionStrict] boolValue];
    _useRegisterSymbols = [[options valueForKey:XDTAs99OptionRegister] boolValue];
    _outputWarnings = [[options valueForKey:XDTAs99OptionWarnings] boolValue];
    _version = [NSString stringWithCString:PyString_AsString(pVar) encoding:NSUTF8StringEncoding];
    Py_XDECREF(pVar);

    /* preparing parameters */
    PyObject *target = PyString_FromString([self targetTypeAsCString]);
    PyObject *addRegisters = PyBool_FromLong(_useRegisterSymbols);
    PyObject *strictMode = PyBool_FromLong(_beStrict);
    PyObject *outputWarnings = PyBool_FromLong(_outputWarnings);
    PyObject *includePath = PyList_New(0);
    for (NSURL *url in urls) {
        PyList_Append(includePath, PyString_FromString([[url path] UTF8String]));
    }
    PyObject *defs = PyList_New(0);

    /* creating assembler object:
        asm = Assembler(target=target,
                        addRegisters=opts.optr,
                        defs=opts.defs or [],
                        includePath=inclpath,
                        strictMode=opts.strict,
                        warnings=outputWarnings)
     */
    PyObject *pArgs = PyTuple_Pack(6, target, addRegisters, defs, includePath, strictMode, outputWarnings);
    PyObject *assembler = PyObject_CallObject(pFunc, pArgs);
    Py_XDECREF(pArgs);
    Py_XDECREF(pFunc);
    if (NULL == assembler) {
        NSLog(@"%s ERROR: calling constructor %s(\"%s\", %@, [], %@, %@, %@) failed!", __FUNCTION__, XDTClassNameAssembler,
              [self targetTypeAsCString], _useRegisterSymbols? @"true" : @"false", urls, _beStrict? @"true" : @"false", _outputWarnings? @"true" : @"false");
        PyObject *exeption = PyErr_Occurred();
        if (NULL != exeption) {
//            if (nil != error) {
//                *error = [NSError errorWithPythonError:exeption RecoverySuggestion:nil];
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
    Py_INCREF(assemblerPythonClass);

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
        case XDTAs99TargetTypeRawBinary:
            return "bin";
        case XDTAs99TargetTypeTextBinaryC:
        case XDTAs99TargetTypeTextBinaryBas:
        case XDTAs99TargetTypeTextBinaryAsm:
            return "text";
        case XDTAs99TargetTypeObjectCode:
            return "obj";
        case XDTAs99TargetTypeProgramImage:
            return "image";
        case XDTAs99TargetTypeEmbededXBasic:
            return "xb";
        case XDTAs99TargetTypeMESSCartridge:
            return "cart";

        default:
            return NULL;
    }
}


#pragma mark - Parsing Methods


- (XDTAs99Objcode *)assembleSourceFile:(NSURL *)srcFile error:(NSError **)error
{
    return [self assembleSourceFile:[srcFile lastPathComponent] pathName:[[srcFile URLByDeletingLastPathComponent] path] error:error];
}


- (XDTAs99Objcode *)assembleSourceFile:(NSString *)baseName pathName:(NSString *)dirName error:(NSError **)error
{
    /* calling assembler:
        code, errors, warnings = asm.assemble(dirname, basename)
     */
    PyObject *methodName = PyString_FromString("assemble");
    PyObject *pDirName = PyString_FromString([dirName UTF8String]);
    PyObject *pbaseName = PyString_FromString([baseName UTF8String]);
    PyObject *pValueTupel = PyObject_CallMethodObjArgs(assemblerPythonClass, methodName, pDirName, pbaseName, NULL);
    Py_XDECREF(pbaseName);
    Py_XDECREF(pDirName);
    Py_XDECREF(methodName);
    if (NULL == pValueTupel) {
        NSLog(@"%s ERROR: assemble(\"%@\", \"%@\") returns NULL!", __FUNCTION__, dirName, baseName);
        PyObject *exeption = PyErr_Occurred();
        if (NULL != exeption) {
            if (nil != error) {
                *error = [NSError errorWithPythonError:exeption localizedRecoverySuggestion:nil];
            }
            PyErr_Print();
        }
        return nil;
    }

    /*
     Don't need to process the dedicated error return value. So skip the item 1 of the value tupel.
     Modern version of xas99 has a console return value which contains all messages (errors and warnings).

     Fetch the console return value which contains all messages the assembler generates.
     */
    XDTMessage *newMessages = nil;
    PyObject *messageList = PyTuple_GetItem(pValueTupel, 2);
    if (NULL != messageList) {
        const Py_ssize_t messageCount = PyList_Size(messageList);
        if (0 < messageCount) {
            newMessages = [XDTMessage messageWithPythonList:messageList];
            const NSUInteger errCount = [newMessages countOfType:XDTMessageTypeError];
            if (0 < errCount) {
                if (nil != error) {
                    NSBundle *myBundle = [NSBundle bundleForClass:[self class]];
                    NSDictionary *errorDict = @{
                                                NSLocalizedDescriptionKey: [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"Error occured while assembling '%@'", nil, myBundle, @"Description for an error object, discribing that the Assembler faild assembling a given file name."), baseName],
                                                NSLocalizedFailureReasonErrorKey: [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"Assembler ends with %ld found error(s).", nil, myBundle, @"Reason for an error object, why the Assembler stopped abnormally."), errCount],
                                                NSLocalizedRecoverySuggestionErrorKey: NSLocalizedStringFromTableInBundle(@"For more information see messages in the log view. Please check your code and all assembler options and try again.", nil, myBundle, @"Recovery suggestion for an error object, when the Assembler terminates abnormally.")
                                                };
                    *error = [NSError errorWithDomain:XDTErrorDomain code:XDTErrorCodeToolLoggedError userInfo:errorDict];
                }
                NSLog(@"Assembler found %ld error(s) while assembling '%@'", errCount, baseName);
            }
        }
    }
    [self willChangeValueForKey:NSStringFromSelector(@selector(messages))];
    _messages = newMessages;
    [self didChangeValueForKey:NSStringFromSelector(@selector(messages))];

    XDTAs99Objcode *retVal = nil;
    PyObject *objectCodeObject = PyTuple_GetItem(pValueTupel, 0);
    if (NULL != objectCodeObject) {
        retVal = [XDTAs99Objcode objectcodeWithPythonInstance:objectCodeObject];
    }

    Py_DECREF(pValueTupel);

    return retVal;
}

@end
