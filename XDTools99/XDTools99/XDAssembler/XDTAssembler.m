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

#import <Python/Python.h>

#import "NSErrorPythonAdditions.h"
#import "NSArrayPythonAdditions.h"
#import "NSStringPythonAdditions.h"

#import "XDTMessage.h"
#import "XDTAs99Objcode.h"


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

+ (const char *)targetTypeAsCString:(XDTAs99TargetType)targetType;

@end

NS_ASSUME_NONNULL_END


NS_ASSUME_NONNULL_BEGIN

@interface XDTAssembler () {
    XDTMessage *_messages;
}

@property (readonly, nullable) const char *targetTypeAsCString;

- (nullable instancetype)initWithModule:(PyObject *)pModule includeURL:(NSArray<NSURL *> *)url target:(XDTAs99TargetType) targetType usingRegisterSymbol:(BOOL)useRegisterSymbol strictness:(BOOL)beStrict outputWarnings:(BOOL)outputWarnings;

@end

NS_ASSUME_NONNULL_END


@implementation XDTAssembler

+ (NSString *)pythonClassName
{
    return [NSString stringWithUTF8String:XDTClassNameAssembler];
}


#pragma mark Initializers

/* This class method initialize this singleton. It takes care of all python module related things. */
+ (instancetype)assemblerWithIncludeURL:(NSURL *)url target:(XDTAs99TargetType)targetType usingRegisterSymbol:(BOOL)useRegisterSymbol strictness:(BOOL)beStrict outputWarnings:(BOOL)outputWarnings
{
    assert(nil != url);

    @synchronized (self) {
        PyObject *pModule = self.xdtAs99ModuleInstance;
        if (NULL == pModule) {
            return nil;
        }

        BOOL isDirectory;
        if ([[NSFileManager defaultManager] fileExistsAtPath:[url path] isDirectory:&isDirectory]) {
            if (!isDirectory) {
                url = [url URLByDeletingLastPathComponent];
            }
        }
        XDTAssembler *retVal = [[XDTAssembler alloc] initWithModule:pModule includeURL:@[url] target:targetType usingRegisterSymbol:useRegisterSymbol strictness:beStrict outputWarnings:outputWarnings];
#if !__has_feature(objc_arc)
        return [retVal autorelease];
#endif
        return retVal;
    }
}


- (instancetype)initWithModule:(PyObject *)pModule includeURL:(NSArray<NSURL *> *)urls target:(XDTAs99TargetType)targetType usingRegisterSymbol:(BOOL)useRegisterSymbol strictness:(BOOL)beStrict outputWarnings:(BOOL)outputWarnings
{
    assert(NULL != pModule);
    assert(nil != urls);

    PyObject *pFunc = PyObject_GetAttrString(pModule, XDTClassNameAssembler);
    if (NULL == pFunc || !PyCallable_Check(pFunc)) {
        NSLog(@"%s ERROR: Cannot find class \"%s\" in module %s", __FUNCTION__, XDTClassNameAssembler, PyModule_GetName(pModule));
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
    PyObject *pTarget = PyString_FromString([XDTAssembler targetTypeAsCString:targetType]);
    PyObject *pOptrR = PyBool_FromLong(useRegisterSymbol);
    PyObject *pDefs = PyList_New(0);
    PyObject *pIncludes = PyList_New(0);
    if (0 >= urls.count) {
        PyList_Append(pIncludes, @".".asPythonType);
    } else {
        for (NSURL *url in urls) {
            PyList_Append(pIncludes, url.path.asPythonType);
        }
    }
    PyObject *pStrict = PyBool_FromLong(beStrict);
    PyObject *pWarnings = PyBool_FromLong(outputWarnings);

    /* creating assembler object:
        asm = Assembler(target=target,
                        optr=opts.optr,
                        defs=opts.defs or [],
                        includes=inclpath,
                        strict=opts.strict,
                        warnings=not opts.nowarn)
     */
    PyObject *pArgs = PyTuple_Pack(6, pTarget, pOptrR, pDefs, pIncludes, pStrict, pWarnings);
    PyObject *assembler = PyObject_CallObject(pFunc, pArgs);
    Py_XDECREF(pArgs);
    Py_DECREF(pFunc);
    if (NULL == assembler) {
        NSLog(@"%s ERROR: calling constructor %s(\"%s\", %s, [], %@, %s, %s) failed!", __FUNCTION__, XDTClassNameAssembler,
              [XDTAssembler targetTypeAsCString:targetType], useRegisterSymbol? "true" : "false", (0 >= urls)? @"." : urls, beStrict? "true" : "false", outputWarnings? "true" : "false");
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

    self = [super initWithPythonInstance:assembler];
    Py_DECREF(assembler);
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


- (BOOL)useRegisterSymbols
{
    PyObject *pResult = PyObject_GetAttrString(self.pythonInstance, "optr");
    if (NULL == pResult) {
        return NO;
    }

    BOOL retVal = 1 == PyObject_IsTrue(pResult);
    Py_DECREF(pResult);
    return retVal;
}


- (void)setUseRegisterSymbols:(BOOL)useRegisterSymbols
{
    PyObject *pOptR = PyBool_FromLong(useRegisterSymbols);
    (void)PyObject_SetAttrString(self.pythonInstance, "optr", pOptR);
    Py_XDECREF(pOptR);
}


- (BOOL)beStrict
{
    PyObject *pResult = PyObject_GetAttrString(self.pythonInstance, "strict");
    if (NULL == pResult) {
        return NO;
    }

    BOOL retVal = 1 == PyObject_IsTrue(pResult);
    Py_DECREF(pResult);
    return retVal;
}


- (void)setBeStrict:(BOOL)beStrict
{
    PyObject *pStrict = PyBool_FromLong(beStrict);
    PyObject_SetAttrString(self.pythonInstance, "strict", pStrict);
    Py_XDECREF(pStrict);
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
    PyObject_SetAttrString(self.pythonInstance, "warnings", pWarnings);
    Py_XDECREF(pWarnings);
}


- (const char *)targetTypeAsCString
{
    return [XDTAssembler targetTypeAsCString:_targetType];
}


+ (const char *)targetTypeAsCString:(XDTAs99TargetType)targetType
{
    switch (targetType) {
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


- (XDTMessage *)messages
{
    if (nil != _messages) {
        [_messages refresh];
        return _messages;
    }

    PyObject *messageList = PyObject_GetAttrString(self.pythonInstance, "console");
    if (NULL == messageList) {
        return nil;
    }

    XDTMutableMessage *retVal = [XDTMutableMessage messageWithPythonList:messageList];
    Py_DECREF(messageList);
    if (nil == retVal || 0 >= retVal.count) {
        return nil;
    }
    [retVal sortByPriorityAscendingType];

    _messages = retVal;
    return _messages;
}


#pragma mark - Method Wrapper


- (XDTAs99Objcode *)assembleSourceCode:(NSString *)srcCode error:(NSError **)error
{
    NSURL *fileURL = [NSURL fileURLWithPath:NSTemporaryDirectory() isDirectory:YES];
    [NSFileManager.defaultManager createDirectoryAtURL:fileURL withIntermediateDirectories:NO attributes:nil error:error];

    fileURL = [[fileURL URLByAppendingPathComponent:@"sourceCode"] URLByAppendingPathExtension:@"a99"];
    [NSFileManager.defaultManager removeItemAtURL:fileURL error:error];
    [srcCode writeToURL:fileURL atomically:YES encoding:NSUTF8StringEncoding error:error];

    return [self assembleSourceFile:fileURL error:error];
}
- (XDTAs99Objcode *)nix:(NSString *)srcCode error:(NSError **)error {
    NSString *dirName = @".";

    /* calling assembler:
     code, errors = asm.assemble(dirname, srcCode)
     */
    PyObject *methodName = PyString_FromString("assemble_text");
    PyObject *pDirName = dirName.asPythonType;
    PyObject *pSrcCode = srcCode.asPythonType;
    PyObject *pValueTupel = PyObject_CallMethodObjArgs(self.pythonInstance, methodName, pDirName, pSrcCode, NULL);
    Py_XDECREF(pSrcCode);
    Py_XDECREF(pDirName);
    Py_XDECREF(methodName);
    if (NULL == pValueTupel) {
        NSLog(@"%s ERROR: assemble(\"%@\", \"%@...\") returns NULL!", __FUNCTION__, dirName, [srcCode substringToIndex:12]);
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
     Don't need to process the dedicated error return value. So skip the item at index 1 of the value tupel.
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
                                        NSLocalizedDescriptionKey: NSLocalizedStringFromTableInBundle(@"Error occured while assembling given source code", nil, myBundle, @"Description for an error object, discribing that the Assembler faild assembling a given source code."),
                                        NSLocalizedFailureReasonErrorKey: [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"Assembler ends with %ld found error(s).", nil, myBundle, @"Reason for an error object, why the Assembler stopped abnormally."), errCount],
                                        NSLocalizedRecoverySuggestionErrorKey: NSLocalizedStringFromTableInBundle(@"For more information see messages in the log view. Please check your code and all assembler options and try again.", nil, myBundle, @"Recovery suggestion for an error object, when the Assembler terminates abnormally.")
                                        };
            *error = [NSError errorWithDomain:XDTErrorDomain code:-1 userInfo:errorDict];
        }
        NSLog(@"Assembler found %ld error(s) while assembling '%@...'", errCount, [srcCode substringToIndex:12]);
    }

    XDTAs99Objcode *retVal = nil;
    PyObject *objectCodeObject = PyTuple_GetItem(pValueTupel, 0);
    if (NULL != objectCodeObject) {
        retVal = [XDTAs99Objcode objectcodeWithPythonInstance:objectCodeObject];
    }
    Py_DECREF(pValueTupel);

    return retVal;
}


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
    PyObject *pDirName = dirName.asPythonType;
    PyObject *pbaseName = baseName.asPythonType;
    PyObject *pValueTupel = PyObject_CallMethodObjArgs(self.pythonInstance, methodName, pDirName, pbaseName, NULL);
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
     Don't need to process the dedicated error return value. So skip the item at index 1 of the value tupel.
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
                                        NSLocalizedDescriptionKey: [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"Error occured while assembling '%@'", nil, myBundle, @"Description for an error object, discribing that the Assembler faild assembling a given file name."), baseName],
                                        NSLocalizedFailureReasonErrorKey: [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"Assembler ends with %ld found error(s).", nil, myBundle, @"Reason for an error object, why the Assembler stopped abnormally."), errCount],
                                        NSLocalizedRecoverySuggestionErrorKey: NSLocalizedStringFromTableInBundle(@"For more information see messages in the log view. Please check your code and all assembler options and try again.", nil, myBundle, @"Recovery suggestion for an error object, when the Assembler terminates abnormally.")
                                        };
            *error = [NSError errorWithDomain:XDTErrorDomain code:XDTErrorCodeToolLoggedError userInfo:errorDict];
        }
        NSLog(@"Assembler found %ld error(s) while assembling '%@'", errCount, baseName);
    }

    XDTAs99Objcode *retVal = nil;
    PyObject *objectCodeObject = PyTuple_GetItem(pValueTupel, 0);
    if (NULL != objectCodeObject) {
        retVal = [XDTAs99Objcode objectcodeWithPythonInstance:objectCodeObject];
    }
    Py_DECREF(pValueTupel);

    return retVal;
}

@end
