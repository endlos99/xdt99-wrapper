//
//  XDTGPLAssembler.m
//  XDTools99
//
//  Created by Henrik Wedekind on 18.12.16.
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

#import "XDTGPLAssembler.h"

#include <Python/Python.h>

#import "NSErrorPythonAdditions.h"
#import "NSArrayPythonAdditions.h"

#import "XDTException.h"
#import "XDTMessage.h"
#import "XDTGa99Objcode.h"


#define XDTModuleNameGPLAssembler "xga99"
#define XDTClassNameGPLAssembler "Assembler"


NS_ASSUME_NONNULL_BEGIN

@interface XDTGa99Objcode () {
    PyObject *objectcodePythonClass;
}

/**
 *
 * The visibility of all allocators / initializers are effectivly package private!
 * They are only visible for the XDTGPLAssembler. Objects of this class are created by calling any of
 * the assembleSourceFile: methods from an instance of the XDTGPLAssembler class.
 *
 **/

+ (nullable instancetype)gplObjectcodeWithPythonInstance:(void *)object;

- (nullable instancetype)initWithPythonInstance:(PyObject *)object;

@end

NS_ASSUME_NONNULL_END


NS_ASSUME_NONNULL_BEGIN

XDTGa99OptionKey const XDTGa99OptionGROM = @"XDTGa99OptionGROM";
XDTGa99OptionKey const XDTGa99OptionAORG = @"XDTGa99OptionAORG";
XDTGa99OptionKey const XDTGa99OptionStyle = @"XDTGa99OptionStyle";
XDTGa99OptionKey const XDTGa99OptionTarget = @"XDTGa99OptionTarget";
XDTGa99OptionKey const XDTGa99OptionWarnings = @"XDTGa99OptionWarnings";


@interface XDTGPLAssembler () {
    const PyObject *assemblerPythonModule;
    PyObject *assemblerPythonClass;
}

@property NSString *version;
@property XDTGa99TargetType targetType;
@property XDTGa99SyntaxType syntaxType;

- (nullable instancetype)initWithOptions:(NSDictionary<XDTGa99OptionKey, id> *)options forModule:(PyObject *)pModule includeURL:(NSArray<NSURL *> *)urls;

- (nullable const char *)syntaxTypeAsCString;
- (nullable const char *)targetTypeAsCString;

@end

NS_ASSUME_NONNULL_END


@implementation XDTGPLAssembler

+ (BOOL)checkRequiredModuleVersion
{
    PyObject *pName = PyString_FromString(XDTModuleNameGPLAssembler);
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
    if (0 != strcmp(PyString_AsString(pVar), XDTGPLAssemblerVersionRequired)) {
        NSLog(@"%s ERROR: Wrong GPL Assembler version %s! Required is %s", __FUNCTION__, PyString_AsString(pVar), XDTGPLAssemblerVersionRequired);
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

+ (instancetype)gplAssemblerWithOptions:(NSDictionary<XDTGa99OptionKey, id> *)options includeURL:(NSURL *)url
{
    assert(NULL != options);
    assert(nil != url);

    @synchronized (self) {
        PyObject *pModule = PyImport_ImportModuleNoBlock(XDTModuleNameGPLAssembler);
        if (NULL == pModule) {
            NSLog(@"%s ERROR: Importing module '%s' failed! Python path: %s", __FUNCTION__, XDTModuleNameGPLAssembler, Py_GetPath());
            PyObject *exeption = PyErr_Occurred();
            if (NULL != exeption) {
//            if (nil != error) {
//                *error = [NSError errorWithPythonError:exeption RecoverySuggestion:nil];
//            }
                PyErr_Print();
                //@throw [XDTException exceptionWithError:[NSError errorWithPythonError:exeption RecoverySuggestion:nil]];
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


- (instancetype)initWithOptions:(NSDictionary<XDTGa99OptionKey, id> *)options forModule:(PyObject *)pModule includeURL:(NSArray<NSURL *> *)urls
{
    assert(NULL != pModule);
    assert(nil != urls);

    self = [super init];
    if (nil == self) {
        return nil;
    }

    PyObject *pVar = PyObject_GetAttrString(pModule, "VERSION");
    if (NULL == pVar || !PyString_Check(pVar)) {
        NSLog(@"%s ERROR: annot get version string of module %s", __FUNCTION__, PyModule_GetName(pModule));
        if (PyErr_Occurred()) {
            PyErr_Print();
        }
        Py_XDECREF(pVar);
#if !__has_feature(objc_arc)
        [self release];
#endif
        return nil;
    }
    if (0 != strcmp(PyString_AsString(pVar), XDTGPLAssemblerVersionRequired)) {
        NSLog(@"%s ERROR: Wrong GPL Assembler version %s! Required is %s", __FUNCTION__, PyString_AsString(pVar), XDTGPLAssemblerVersionRequired);
        Py_XDECREF(pVar);
#if !__has_feature(objc_arc)
        [self release];
#endif
        return nil;
    }

    PyObject *pFunc = PyObject_GetAttrString(pModule, XDTClassNameGPLAssembler);
    if (NULL == pFunc || !PyCallable_Check(pFunc)) {
        NSLog(@"%s ERROR: Cannot find class \"%s\" in module %s", __FUNCTION__, XDTClassNameGPLAssembler, PyModule_GetName(pModule));
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
    _targetType = [[options valueForKey:XDTGa99OptionTarget] unsignedIntegerValue];
    _syntaxType = [[options valueForKey:XDTGa99OptionStyle] unsignedIntegerValue];
    _aorgAddress = [[options valueForKey:XDTGa99OptionAORG] unsignedIntegerValue];
    _gromAddress = [[options valueForKey:XDTGa99OptionGROM] unsignedIntegerValue];
    _outputWarnings = [[options valueForKey:XDTGa99OptionWarnings] boolValue];
    _version = [NSString stringWithCString:PyString_AsString(pVar) encoding:NSUTF8StringEncoding];
    Py_XDECREF(pVar);

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
    PyObject *outputWarnings = PyBool_FromLong(_outputWarnings);

    /* creating assembler object:
        asm = Assembler(syntax, grom, aorg, target="", include_path=None, defs=(), warnings=True):
     */
    PyObject *pArgs = PyTuple_Pack(7, syntax, grom, aorg, target, includePath, defs, outputWarnings);
    PyObject *assembler = PyObject_CallObject(pFunc, pArgs);
    Py_XDECREF(pArgs);
    Py_XDECREF(pFunc);
    if (NULL == assembler) {
        NSLog(@"%s ERROR: calling constructor %@(\"%s\", 0x%lx, 0x%lx, \"%s\", %@, None) failed!", __FUNCTION__,
              pFunc, [self syntaxTypeAsCString], _gromAddress, _aorgAddress, [self targetTypeAsCString], urls);
        PyObject *exeption = PyErr_Occurred();
        if (NULL != exeption) {
//            if (nil != error) {
//                *error = [NSError errorWithPythonError:exeption RecoverySuggestion:nil];
//            }
            PyErr_Print();
            @throw [XDTException exceptionWithError:[NSError errorWithPythonError:exeption RecoverySuggestion:nil]];
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
        case XDTGa99SyntaxTypeRAGGPL:
            //return "rag";     // removed in xga99 v1.8.5 - RAG is combined with Ryte
        case XDTGa99SyntaxTypeNativeXDT99:
            return "xdt99";
        case XDTGa99SyntaxTypeTIImageTool:
            return "mizapf";

        default:
            return NULL;
    }
}


- (const char *)targetTypeAsCString
{
    switch (_targetType) {
        case XDTGa99TargetTypePlainByteCode:
            return "gbc";
        case XDTGa99TargetTypeHeaderedByteCode:
            return "image";
        case XDTGa99TargetTypeMESSCartridge:
            return "cart";

        default:
            return NULL;
    }
}


#pragma mark - Parsing Methods


- (XDTGa99Objcode *)assembleSourceFile:(NSURL *)srcname error:(NSError **)error
{
    return [self assembleSourceFile:srcname pathName:[NSURL fileURLWithPath:@"." isDirectory:YES] error:error];
}


- (XDTGa99Objcode *)assembleSourceFile:(NSURL *)srcname pathName:(NSURL *)pathName error:(NSError **)error
{
    NSString *basename = [srcname lastPathComponent];

    /* calling assembler:
     code, errors, warnings = asm.assemble(basename)
     */
    PyObject *methodName = PyString_FromString("assemble");
    PyObject *pbaseName = PyString_FromString([basename UTF8String]);
    PyObject *pValueTupel = PyObject_CallMethodObjArgs(assemblerPythonClass, methodName, pbaseName, NULL);
    Py_XDECREF(pbaseName);
    Py_XDECREF(methodName);
    if (NULL == pValueTupel) {
        NSLog(@"%s ERROR: assemble(\"%@\") returns NULL!", __FUNCTION__, basename);
        PyObject *exeption = PyErr_Occurred();
        if (NULL != exeption) {
            if (nil != error) {
                *error = [NSError errorWithPythonError:exeption RecoverySuggestion:nil];
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
    XDTMutableMessage *newMessages = nil;
    PyObject *messageList = PyTuple_GetItem(pValueTupel, 2);
    if (NULL != messageList) {
        const Py_ssize_t messageCount = PyList_Size(messageList);
        if (0 < messageCount) {
            newMessages = [XDTMutableMessage messageWithPythonList:messageList];
            const NSUInteger errCount = [newMessages countOfType:XDTMessageTypeError];
            if (0 < errCount) {
                if (nil != error) {
                    NSBundle *myBundle = [NSBundle bundleForClass:[self class]];
                    NSDictionary *errorDict = @{
                                                NSLocalizedDescriptionKey: [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"Error occured while assembling '%@'", nil, myBundle, @"Description for an error object, discribing that the Assembler faild assembling a given file name."), basename],
                                                NSLocalizedFailureReasonErrorKey: [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"Assembler ends with %ld found error(s).", nil, myBundle, @"Reason for an error object, why the Assembler stopped abnormally."), errCount],
                                                NSLocalizedRecoverySuggestionErrorKey: NSLocalizedStringFromTableInBundle(@"For more information see messages in the log view. Please check your code and all assembler options and try again.", nil, myBundle, @"Recovery suggestion for an error object, when the Assembler terminates abnormally.")
                                                };
                    *error = [NSError errorWithDomain:XDTErrorDomain code:XDTErrorCodeToolLoggedError userInfo:errorDict];
                }
                NSLog(@"Assembler found %ld error(s) while assembling '%@'", errCount, basename);
            }
        }
    }
    [self willChangeValueForKey:NSStringFromSelector(@selector(messages))];
    _messages = newMessages;
    [self didChangeValueForKey:NSStringFromSelector(@selector(messages))];

    XDTGa99Objcode *retVal = nil;
    PyObject *objectCodeObject = PyTuple_GetItem(pValueTupel, 0);
    if (NULL != objectCodeObject) {
        retVal = [XDTGa99Objcode gplObjectcodeWithPythonInstance:objectCodeObject];
    }

    Py_DECREF(pValueTupel);

    return retVal;
}

@end
