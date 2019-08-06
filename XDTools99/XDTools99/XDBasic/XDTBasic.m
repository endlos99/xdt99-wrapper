//
//  XDTBasic.m
//  XDTools99
//
//  Created by Henrik Wedekind on 12.12.16.
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

#import "XDTBasic.h"

#import <Python/Python.h>

#import "NSErrorPythonAdditions.h"
#import "NSArrayPythonAdditions.h"
#import "NSDictionaryPythonAdditions.h"
#import "NSDataPythonAdditions.h"
#import "NSStringPythonAdditions.h"

#import "XDTMessage.h"


#define XDTClassNameBasic "BasicProgram"


NS_ASSUME_NONNULL_BEGIN

@interface XDTBasic () {
    NSArray<NSString *>*_codeLines;
}

- (nullable instancetype)initWithModule:(PyObject *)pModule;

- (BOOL)loadData:(NSData *)data usingLongFormat:(BOOL)useLongFormat error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END


@implementation XDTBasic

+ (NSString *)pythonClassName
{
    return [NSString stringWithUTF8String:XDTClassNameBasic];
}


#pragma mark Initializers

/* This class method initialize this singleton. It takes care of all python module related things. */
+ (instancetype)basic
{
    @synchronized (self) {
        PyObject *pModule = self.xdtBas99ModuleInstance;
        if (NULL == pModule) {
            return nil;
        }

        XDTBasic *retVal = [[XDTBasic alloc] initWithModule:pModule];
#if !__has_feature(objc_arc)
        return [retVal autorelease];
#else
        return retVal;
#endif
    }
}


- (instancetype)initWithModule:(PyObject *)pModule
{
    assert(NULL != pModule);

    PyObject *pFunc = PyObject_GetAttrString(pModule, XDTClassNameBasic);
    if (NULL == pFunc || !PyCallable_Check(pFunc)) {
        NSLog(@"%s ERROR: Cannot find class \"%s\" in module %s", __FUNCTION__, XDTClassNameBasic, PyModule_GetName(pModule));
        if (PyErr_Occurred()) {
            PyErr_Print();
        }
        Py_XDECREF(pFunc);
#if !__has_feature(objc_arc)
        [self release];
#endif
        return nil;
    }

    /* creating basic object:
     basic = BasicProgram(data=None, source=None, long_=False)
     
     Comment: This is a bad constructor, it does not exclusevly do instantiating and allocating, it also already
        work with its instance.   So I won't do that, the initializor is for initializing only. After init, call
        methods for work on the instance.
     Behavior: If data is set, longFlag is also used and data will be loaded. If data is not set but source is set,
        the program code in it will be parsed. If non of these parameter are set, a normal initializing is done.
     */
    PyObject *basicObject = PyObject_CallObject(pFunc, NULL);
    Py_XDECREF(pFunc);
    if (NULL == basicObject) {
        NSLog(@"%s ERROR: calling constructor %@(None, None, False) failed!", __FUNCTION__, pFunc);
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

    self = [super initWithPythonInstance:basicObject];
    if (nil == self) {
        return nil;
    }

    _codeLines = nil;

    return self;
}


- (void)dealloc
{
#if !__has_feature(objc_arc)
    [super dealloc];
#endif
}


#pragma mark - Property Wrapper


- (NSDictionary<NSNumber *, NSArray *> *)lines
{
    PyObject *linesObject = PyObject_GetAttrString(self.pythonInstance, "lines");
    if (NULL == linesObject) {
        return nil;
    }

    NSDictionary *retVal = [NSDictionary dictionaryWithPythonDictionary:linesObject];
    Py_DECREF(linesObject);

    return retVal;
}


- (XDTMessage *)messages
{
    PyObject *warningsObject = PyObject_GetAttrString(self.pythonInstance, "warnings");
    if (NULL == warningsObject) {
        return nil;
    }

    XDTMutableMessage *retVal = nil;
    const Py_ssize_t warningCount = PyList_Size(warningsObject);
    if (0 < warningCount) {
        retVal = [XDTMutableMessage messageWithPythonList:warningsObject treatingAs:XDTMessageTypeWarning];    /* there is no automatic type detection possible, so treat all messages as warnings */
        [retVal sortByPriorityAscendingType];
    }

    Py_DECREF(warningsObject);

    return retVal;
}


#pragma mark - Program to source code conversion Method Wrapper


/* load tokenized BASIC program in internal format */
- (BOOL)loadProgramData:(NSData *)data error:(NSError **)error
{
    return [self loadData:data usingLongFormat:NO error:error];
}


/* load tokenized BASIC program in long format */
- (BOOL)loadLongData:(NSData *)data error:(NSError **)error
{
    return [self loadData:data usingLongFormat:YES error:error];
}


- (BOOL)loadData:(NSData *)data usingLongFormat:(BOOL)useLongFormat error:(NSError **)error
{
    /* calling loader:
     load(data, long_)
     */
    PyObject *methodName = PyString_FromString("load");
    PyObject *pData = data.asPythonType;
    PyObject *pLong = PyBool_FromLong(useLongFormat);
    PyObject *pNonValue = PyObject_CallMethodObjArgs(self.pythonInstance, methodName, pData, pLong, NULL);
    Py_XDECREF(pLong);
    Py_XDECREF(pData);
    Py_XDECREF(methodName);
    if (NULL == pNonValue) {
        NSLog(@"%s ERROR: load(%@, %s) returns NULL!", __FUNCTION__, data, useLongFormat? "true" : "false");
        PyObject *exeption = PyErr_Occurred();
        if (NULL != exeption) {
            if (nil != error) {
                *error = [NSError errorWithPythonError:exeption localizedRecoverySuggestion:nil];
            }
            PyErr_Print();
        }
        return NO;
    }

    assert(Py_None == pNonValue);
    return YES;
}


/* load tokenized BASIC program in merge format */
- (BOOL)loadMergedData:(NSData *)data error:(NSError **)error
{
    /* calling loader:
     merge(data)
     */
    PyObject *methodName = PyString_FromString("merge");
    PyObject *pData = data.asPythonType;
    PyObject *pNonValue = PyObject_CallMethodObjArgs(self.pythonInstance, methodName, pData, NULL);
    Py_XDECREF(pData);
    Py_XDECREF(methodName);
    if (NULL == pNonValue) {
        NSLog(@"%s ERROR: merge(%@) returns NULL!", __FUNCTION__, data);
        PyObject *exeption = PyErr_Occurred();
        if (NULL != exeption) {
            if (nil != error) {
                *error = [NSError errorWithPythonError:exeption localizedRecoverySuggestion:nil];
            }
            PyErr_Print();
        }
        return NO;
    }

    assert(Py_None == pNonValue);
    return YES;
}


/* textual representation of token sequence */
- (NSString *)getSource:(NSError **)error
{
    /* calling:
     text = get_source()
     */
    PyObject *methodName = PyString_FromString("get_source");
    PyObject *pSourceCode = PyObject_CallMethodObjArgs(self.pythonInstance, methodName, NULL);
    Py_XDECREF(methodName);
    if (NULL == pSourceCode) {
        NSLog(@"%s ERROR: get_source() returns NULL!", __FUNCTION__);
        PyObject *exeption = PyErr_Occurred();
        if (NULL != exeption) {
            if (nil != error) {
                *error = [NSError errorWithPythonError:exeption localizedRecoverySuggestion:nil];
            }
            PyErr_Print();
        }
        return nil;
    }

    NSString *retVal = [NSString stringWithPythonString:pSourceCode encoding:NSUTF8StringEncoding];
    Py_DECREF(pSourceCode);
    return retVal;
}


- (NSData *)getImageUsingLongFormat:(BOOL)useLongFormat error:(NSError **)error
{
    /* calling:
     data = get_image(long_=opts.long_, protected=opts.protect)
     */
    PyObject *methodName = PyString_FromString("get_image");
    PyObject *pLongOpt = PyBool_FromLong(useLongFormat);
    PyObject *pProtectOpt = PyBool_FromLong(_protect);
    PyObject *pProgramData = PyObject_CallMethodObjArgs(self.pythonInstance, methodName, pLongOpt, pProtectOpt, NULL);
    Py_XDECREF(pProtectOpt);
    Py_XDECREF(pLongOpt);
    Py_XDECREF(methodName);
    if (NULL == pProgramData) {
        NSLog(@"%s ERROR: get_image(%s, %s) returns NULL!", __FUNCTION__, useLongFormat? "true" : "false", _protect? "true" : "false");
        PyObject *exeption = PyErr_Occurred();
        if (NULL != exeption) {
            if (nil != error) {
                *error = [NSError errorWithPythonError:exeption localizedRecoverySuggestion:nil];
            }
            PyErr_Print();
        }
        return nil;
    }

    NSData *imageData = [NSData dataWithPythonString:pProgramData];
    Py_DECREF(pProgramData);
    return imageData;
}


#pragma mark - Source code to program conversion Method Wrapper


/* parse and tokenize BASIC source code */
- (BOOL)parseSourceCode:(NSString *)sourceCode error:(NSError **)error
{
    if (0 == [sourceCode length]) {
        return YES; // an empty source code always parsed into an empty result
    }

    /* preparing source code matching Pythons data structure */
    NSArray<NSString *> *lines = [sourceCode componentsSeparatedByCharactersInSet:NSCharacterSet.newlineCharacterSet];
    PyObject *pLinesList = PyList_New(0);
    if (NULL == pLinesList) {
        return NO;
    }
    for (NSString *line in lines) {
        NSString *trimmedLine = [line stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
        PyObject *pLine = trimmedLine.asPythonType;
        PyList_Append(pLinesList, pLine);
    }

    if (_join) {
        /* calling static method join:
         lines = BasicProgram.join(lines, min_lino_delta=1, max_lino_delta=delta)
         */
        /* TODO: Make the line delta (here fixed to the default value of 3) configurable by UI */
        PyObject *methodName = PyString_FromString("join");
        PyObject *pMinLineDelta = PyInt_FromLong(1);
        PyObject *pMaxLineDelta = PyInt_FromLong(_lineDelta);
        PyObject *joinedLines = PyObject_CallMethodObjArgs(self.pythonInstance, methodName, pLinesList, pMinLineDelta, pMaxLineDelta, NULL);
        Py_XDECREF(pMaxLineDelta);
        Py_XDECREF(pMinLineDelta);
        Py_XDECREF(methodName);
        if (NULL == joinedLines) {  /* if result is null, the line delta could be wrong configured. */
            NSLog(@"%s ERROR: join(%@, 10) returns NULL!", __FUNCTION__, lines);
            PyObject *exeption = PyErr_Occurred();
            if (NULL != exeption) {
                if (nil != error) {
                    NSBundle *myBundle = [NSBundle bundleForClass:[self class]];
                    *error = [NSError errorWithPythonError:exeption localizedRecoverySuggestion:NSLocalizedStringFromTableInBundle(@"Choose another value for the Line Delta, unwrap lines by hand in the integrated source code editor or fix the source file with an external text editor application and reload the file.", nil, myBundle, @"Recovery suggestion for an error object, to choose an other Line Delta for the JOIN operation of the xbas99.")];
                }
                PyErr_Print();
            }
            return NO;
        }
        Py_DECREF(pLinesList);
        pLinesList = joinedLines;
    }

    /* calling parser:
     parse(lines)
     */
    PyObject *methodName = PyString_FromString("parse");
    PyObject *pNonValue = PyObject_CallMethodObjArgs(self.pythonInstance, methodName, pLinesList, NULL);
    Py_DECREF(pLinesList);
    Py_XDECREF(methodName);
    if (NULL == pNonValue) {
        NSLog(@"%s ERROR: parse(%@) returns NULL!", __FUNCTION__, lines);
        PyObject *exeption = PyErr_Occurred();
        if (NULL != exeption) {
            if (nil != error) {
                *error = [NSError errorWithPythonError:exeption localizedRecoverySuggestion:nil];
            }
            PyErr_Print();
        }
        return NO;
    }

    assert(Py_None == pNonValue);
    Py_DECREF(pNonValue);
    return YES;
}


- (BOOL)saveProgramFormatFile:(NSURL *)fileURL error:(NSError **)error
{
    return [self saveFile:fileURL usingLongFormat:NO error:error];
}


- (BOOL)saveLongFormatFile:(NSURL *)fileURL error:(NSError **)error
{
    return [self saveFile:fileURL usingLongFormat:YES error:error];
}


- (BOOL)saveFile:(NSURL *)fileURL usingLongFormat:(BOOL)useLongFormat error:(NSError **)error
{
    NSData *fileData = [self getImageUsingLongFormat:useLongFormat error:error];
    if (nil == fileData || (nil != error && nil != *error)) {
        return NO;
    }
    return [fileData writeToURL:fileURL atomically:YES];
}


- (BOOL)saveMergedFormatFile:(NSURL *)fileURL error:(NSError **)error
{
    if (nil != error) {
        NSBundle *myBundle = [NSBundle bundleForClass:[self class]];
        *error = [NSError errorWithDomain:XDTErrorDomain code:XDTErrorCodeToolException
                                 userInfo:@{
                                            NSLocalizedDescriptionKey: NSLocalizedStringFromTableInBundle(@"Operation not supported", nil, myBundle, @"Description for an error object, discribing that there is an unsupported operation."),
                                            NSLocalizedFailureReasonErrorKey: NSLocalizedStringFromTableInBundle(@"Program creation in MERGE format is not supported by the current version of xbas99.", nil, myBundle, @"Reason for an error object, which explains that the MERGE operation is not available in the current version of xdt99.")
                                            }];
    }
    return NO;
}


- (NSString *)dumpTokenList:(NSError **)error
{
    /* calling:
     result = dump_tokens()
     */
    PyObject *methodName = PyString_FromString("dump_tokens");
    PyObject *pDumpString = PyObject_CallMethodObjArgs(self.pythonInstance, methodName, NULL);
    Py_XDECREF(methodName);
    if (NULL == pDumpString) {
        NSLog(@"%s ERROR: dump_tokens() returns NULL!", __FUNCTION__);
        PyObject *exeption = PyErr_Occurred();
        if (NULL != exeption) {
            if (nil != error) {
                *error = [NSError errorWithPythonError:exeption localizedRecoverySuggestion:nil];
            }
            PyErr_Print();
        }
        return nil;
    }

    NSString *retVal = [NSString stringWithPythonString:pDumpString encoding:NSUTF8StringEncoding];
    Py_DECREF(pDumpString);
    return retVal;
}

@end
