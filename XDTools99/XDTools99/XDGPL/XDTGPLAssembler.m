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

#import <Python/Python.h>

#import "NSArrayPythonAdditions.h"
#import "NSErrorPythonAdditions.h"
#import "NSStringPythonAdditions.h"

#import "XDTException.h"
#import "XDTMessage.h"
#import "XDTGa99Objcode.h"


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

@interface XDTGPLAssembler () {
    XDTMessage *_messages;
}

- (nullable instancetype)initWithModule:(PyObject *)pModule includeURL:(NSArray<NSURL *> *)urls grom:(NSUInteger)gromAddress aorg:(NSUInteger)aorgAddress target:(XDTGa99TargetType)targetType syntax:(XDTGa99SyntaxType)syntaxType outputWarnings:(BOOL)outputWarnings;

+ (nullable const char *)targetTypeAsCString:(XDTGa99TargetType)targetType;

@end

NS_ASSUME_NONNULL_END


@implementation XDTGPLAssembler

+ (NSString *)pythonClassName
{
    return [NSString stringWithUTF8String:XDTClassNameGPLAssembler];
}


#pragma mark Initializers

+ (instancetype)gplAssemblerWithIncludeURL:(NSURL *)url grom:(NSUInteger)gromAddress aorg:(NSUInteger)aorgAddress target:(XDTGa99TargetType)targetType syntax:(XDTGa99SyntaxType)syntaxType outputWarnings:(BOOL)outputWarnings
{
    assert(nil != url);

    @synchronized (self) {
        PyObject *pModule = self.xdtGa99ModuleInstance;
        if (NULL == pModule) {
            return nil;
        }

        BOOL isDirectory;
        if ([[NSFileManager defaultManager] fileExistsAtPath:[url path] isDirectory:&isDirectory]) {
            if (!isDirectory) {
                url = [url URLByDeletingLastPathComponent];
            }
        }
        XDTGPLAssembler *retVal = [[XDTGPLAssembler alloc] initWithModule:pModule includeURL:@[url] grom:gromAddress aorg:aorgAddress target:targetType syntax:syntaxType outputWarnings:outputWarnings];
#if !__has_feature(objc_arc)
        return [retVal autorelease];
#endif
        return retVal;
    }
}


- (instancetype)initWithModule:(PyObject *)pModule includeURL:(NSArray<NSURL *> *)urls grom:(NSUInteger)gromAddress aorg:(NSUInteger)aorgAddress target:(XDTGa99TargetType)targetType syntax:(XDTGa99SyntaxType)syntaxType outputWarnings:(BOOL)outputWarnings
{
    assert(NULL != pModule);
    assert(nil != urls);

    PyObject *pFunc = PyObject_GetAttrString(pModule, XDTClassNameGPLAssembler);
    if (NULL == pFunc || !PyCallable_Check(pFunc)) {
        NSLog(@"%s ERROR: Cannot find class \"%s\" in module %s", __FUNCTION__, XDTClassNameGPLAssembler, PyModule_GetName(pModule));
        if (PyErr_Occurred()) {
            PyErr_Print();
        }
        Py_XDECREF(pFunc);
#if !__has_feature(objc_arc)
        [self release];
#endif
        return nil;
    }

    /* preparing parameters */
    PyObject *pTargetType = PyString_FromString([self.class targetTypeAsCString:targetType]);
    PyObject *pSyntaxType = PyString_FromString([XDTGa99Syntax syntaxTypeAsCString:syntaxType]);
    PyObject *pGromAddress = PyInt_FromLong(gromAddress);
    PyObject *pAorgAddress = PyInt_FromLong(aorgAddress);
    PyObject *pIncludePath = PyList_New(0);
    for (NSURL *url in urls) {
        PyList_Append(pIncludePath, PyString_FromString([[url path] UTF8String]));
    }
    PyObject *pDefs = PyList_New(0);
    PyObject *pOutputWarnings = PyBool_FromLong(outputWarnings);

    /* creating assembler object:
        asm = Assembler(syntax, grom, aorg, target="", include_path=None, defs=(), warnings=True):
     */
    PyObject *pArgs = PyTuple_Pack(7, pSyntaxType, pGromAddress, pAorgAddress, pTargetType, pIncludePath, pDefs, pOutputWarnings);
    PyObject *pAssembler = PyObject_CallObject(pFunc, pArgs);
    Py_XDECREF(pArgs);
    Py_DECREF(pFunc);
    if (NULL == pAssembler) {
        NSLog(@"%s ERROR: calling constructor %@(\"%s\", 0x%lx, 0x%lx, \"%s\", %@, None) failed!", __FUNCTION__,
              pFunc, [XDTGa99Syntax syntaxTypeAsCString:self.syntaxType], self.gromAddress, self.aorgAddress, [self.class targetTypeAsCString:self.targetType], urls);
        PyObject *exeption = PyErr_Occurred();
        if (NULL != exeption) {
//            if (nil != error) {
//                *error = [NSError errorWithPythonError:exeption RecoverySuggestion:nil];
//            }
            PyErr_Print();
            @throw [XDTException exceptionWithError:[NSError errorWithPythonError:exeption localizedRecoverySuggestion:nil]];
        }
#if !__has_feature(objc_arc)
        [self release];
#endif
        return nil;
    }

    self = [super initWithPythonInstance:pAssembler];
    Py_DECREF(pAssembler);
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


+ (const char *)targetTypeAsCString:(XDTGa99TargetType)targetType
{
    switch (targetType) {
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


- (NSUInteger)aorgAddress
{
    PyObject *pResult = PyObject_GetAttrString(self.pythonInstance, "aorg");
    if (NULL == pResult) {
        return 0;
    }

    NSUInteger retVal = PyLong_AsUnsignedLong(pResult);
    Py_DECREF(pResult);
    return retVal;
}


- (void)setAorgAddress:(NSUInteger)aorgAddress
{
    PyObject * pAORG = PyLong_FromUnsignedLong(aorgAddress);
    (void)PyObject_SetAttrString(self.pythonInstance, "aorg", pAORG);
    Py_XDECREF(pAORG);
}


- (NSUInteger)gromAddress
{
    PyObject *pResult = PyObject_GetAttrString(self.pythonInstance, "grom");
    if (NULL == pResult) {
        return 0;
    }

    NSUInteger retVal = PyLong_AsUnsignedLong(pResult);
    Py_DECREF(pResult);
    return retVal;
}


- (void)setGromAddress:(NSUInteger)gromAddress
{
    PyObject *pGROM = PyLong_FromUnsignedLong(gromAddress);
    (void)PyObject_SetAttrString(self.pythonInstance, "grom", pGROM);
    Py_XDECREF(pGROM);
}


- (XDTGa99SyntaxType)syntaxType
{
    PyObject *pResult = PyObject_GetAttrString(self.pythonInstance, "syntax");
    if (NULL == pResult) {
        return XDTGa99SyntaxTypeNativeXDT99;
    }

    NSString *syntaxType = [NSString stringWithPythonString:pResult encoding:NSUTF8StringEncoding];
    Py_XDECREF(pResult);
    if ([@"xdt99" isEqualToString:syntaxType]) {
        return XDTGa99SyntaxTypeNativeXDT99;
    } else if ([@"mizapf" isEqualToString:syntaxType]) {
        return XDTGa99SyntaxTypeTIImageTool;
    } else {
        NSLog(@"Got unknown syntax type from Python class: %@", syntaxType);
    }
    return XDTGa99SyntaxTypeNativeXDT99;
}


- (void)setSyntaxType:(XDTGa99SyntaxType)syntaxType
{
    PyObject *pSyntax = PyString_FromString([XDTGa99Syntax syntaxTypeAsCString:syntaxType]);
    (void)PyObject_SetAttrString(self.pythonInstance, "syntax", pSyntax);
    Py_XDECREF(pSyntax);
}


- (XDTGa99TargetType)targetType
{
    // TODO: datt muss aussn defs rausgezogen werden...
    PyObject *pResult = NULL; //PyObject_GetAttrString(self.pythonInstance, );
    if (NULL == pResult) {
        return XDTGa99TargetTypePlainByteCode;
    }
    XDTGa99TargetType retVal = (XDTGa99TargetType)PyLong_AsUnsignedLong(pResult);
    Py_DECREF(pResult);
    return retVal;
}


- (void)setTargetType:(XDTGa99TargetType)targetType
{
    // TODO: datt is midden defs verwurschtet...
    //PyObject *tt = PyString_FromString([self.class targetTypeAsCString:targetType]);
    //(void)PyObject_SetAttrString(self.pythonInstance, nil, tt);
    //Py_XDECREF(tt);
}


- (BOOL)outputWarnings
{
    PyObject *pResult = PyObject_GetAttrString(self.pythonInstance, "warnings");
    if (NULL == pResult) {
        return NO;
    }

    BOOL retVal = 1 == PyObject_IsTrue(pResult);
    Py_DECREF(pResult);
    return retVal;
}


- (void)setOutputWarnings:(BOOL)outputWarnings
{
    PyObject *pWarnings = PyBool_FromLong(outputWarnings);
    (void)PyObject_SetAttrString(self.pythonInstance, "warnings", pWarnings);
    Py_XDECREF(pWarnings);
}


- (XDTMessage *)messages
{
    if (nil != _messages) {
        [_messages refresh];
        return _messages;
    }

    @synchronized (self) {
        PyObject *messageList = PyObject_GetAttrString(self.pythonInstance, "console");
        if (NULL == messageList) {
            return nil;
        }

        XDTMutableMessage *retVal = [XDTMutableMessage messageWithPythonList:messageList];
        Py_DECREF(messageList);
        if (0 >= retVal.count) {
            return nil;
        }
        [retVal sortByPriorityAscendingType];

        _messages = retVal;
        return _messages;
    }
}


#pragma mark - Method Wrapper


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
    PyObject *pbaseName = basename.asPythonType;
    PyObject *pValueTupel = PyObject_CallMethodObjArgs(self.pythonInstance, methodName, pbaseName, NULL);
    Py_XDECREF(pbaseName);
    Py_XDECREF(methodName);
    if (NULL == pValueTupel) {
        NSLog(@"%s ERROR: assemble(\"%@\") returns NULL!", __FUNCTION__, basename);
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
     */

    [self willChangeValueForKey:NSStringFromSelector(@selector(messages))];
    _messages = nil;
    [self didChangeValueForKey:NSStringFromSelector(@selector(messages))];

    XDTMessage *newMessages = self.messages;
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

    XDTGa99Objcode *retVal = nil;
    PyObject *objectCodeObject = PyTuple_GetItem(pValueTupel, 0);
    if (NULL != objectCodeObject) {
        retVal = [XDTGa99Objcode gplObjectcodeWithPythonInstance:objectCodeObject];
    }
    Py_DECREF(pValueTupel);
    return retVal;
}

@end
