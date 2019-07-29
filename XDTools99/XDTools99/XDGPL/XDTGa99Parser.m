//
//  XDTGPLParser.m
//  XDTools99
//
//  Created by Henrik Wedekind on 02.07.19.
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

#import "XDTGa99Parser.h"

#import <Python/Python.h>

#import "NSStringPythonAdditions.h"
#import "NSErrorPythonAdditions.h"
#import "NSArrayPythonAdditions.h"

#import "XDTLineScanner.h"
#import "XDTAs99Objdummy.h"


#define XDTModuleNameAssembler "xga99"
#define XDTClassNameParser "Parser"


NS_ASSUME_NONNULL_BEGIN

XDTGa99ParserOptionKey const XDTGa99ParserOptionWarnings = @"XDTGa99ParserOptionWarnings";
XDTGa99ParserOptionKey const XDTGa99ParserOptionSyntaxType = @"XDTGa99ParserOptionSyntaxType";


@interface XDTGa99Parser () {
    const PyObject *parserPythonModule;
    PyObject *parserPythonClass;
    PyObject *objdummy;
}

@property BOOL outputWarnings;

- (instancetype)initWithOptions:(NSDictionary<XDTGa99ParserOptionKey, id> *)options forModule:(PyObject *)pModule;

@end

NS_ASSUME_NONNULL_END


@implementation XDTGa99Parser

+ (nullable instancetype)parserWithOptions:(NSDictionary<XDTGa99ParserOptionKey,id> *)options
{
    @synchronized (self) {
        PyObject *pModule = PyImport_ImportModuleNoBlock(XDTModuleNameAssembler);
        if (NULL == pModule) {
            NSLog(@"%s ERROR: Importing module '%s' failed! Python path: %s", __FUNCTION__, XDTModuleNameAssembler, Py_GetPath());
            PyObject *exeption = PyErr_Occurred();
            if (NULL != exeption) {
//            if (nil != error) {
//                *error = [NSError errorWithPythonError:exeption code:-2 RecoverySuggestion:nil];
//            }
                PyErr_Print();
            }
            return nil;
        }

        XDTGa99Parser *retVal = [[XDTGa99Parser alloc] initWithOptions:options forModule:pModule];
        Py_DECREF(pModule);
#if !__has_feature(objc_arc)
        return [retVal autorelease];
#endif
        return retVal;
    }
}


- (instancetype)initWithOptions:(NSDictionary<XDTGa99ParserOptionKey, id> *)options forModule:(PyObject *)pModule
{
    self = [super init];
    if (nil == self) {
        return nil;
    }

    PyObject *pVersion = PyObject_GetAttrString(pModule, "VERSION");
    if (NULL == pVersion || !PyString_Check(pVersion)) {
        NSLog(@"%s ERROR: Cannot get version string of module %s", __FUNCTION__, PyModule_GetName(pModule));
        if (PyErr_Occurred()) {
            PyErr_Print();
        }
        Py_XDECREF(pVersion);
#if !__has_feature(objc_arc)
        [self release];
#endif
        return nil;
    }
    if (0 != strcmp(PyString_AsString(pVersion), XDTGPLAssemblerVersionRequired)) {
        NSLog(@"%s ERROR: Wrong Assembler version %s! Required is %s", __FUNCTION__, PyString_AsString(pVersion), XDTGPLAssemblerVersionRequired);
        Py_XDECREF(pVersion);
#if !__has_feature(objc_arc)
        [self release];
#endif
        return nil;
    }
    Py_XDECREF(pVersion);

    PyObject *pFunc = PyObject_GetAttrString(pModule, XDTClassNameParser);
    if (NULL == pFunc || !PyCallable_Check(pFunc)) {
        NSLog(@"%s ERROR: Cannot find class \"%s\" in module %s", __FUNCTION__, XDTClassNameParser, PyModule_GetName(pModule));
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
    _outputWarnings = [[options valueForKey:XDTGa99ParserOptionWarnings] boolValue];
    NSString *syntaxType = [options valueForKey:XDTGa99ParserOptionSyntaxType];

    /* preparing parameters */
    PyObject *defs = PyList_New(0);
    PyObject *syntax = PyString_FromString([syntaxType cStringUsingEncoding:NSUTF8StringEncoding]);
    PyObject *includePath = PyList_New(0);
    /*for (NSURL *url in urls) {
     PyList_Append(includePath, PyString_FromString([[url path] UTF8String]));
     }*/
    PyObject *outputWarnings = PyBool_FromLong(_outputWarnings);
    PyObject *console = PyList_New(0);

    /* creating parser object:
        parser = Parser(symbols, syntax, include_path=None, warnings=True, console=None)
     */
    PyObject *pArgs = PyTuple_Pack(5, defs, syntax, includePath, outputWarnings, console);
    PyObject *parser = PyObject_CallObject(pFunc, pArgs);
    Py_XDECREF(pArgs);
    Py_XDECREF(pFunc);
    if (NULL == parser) {
        NSLog(@"%s ERROR: calling constructor %s([], %@, [], %@, []) failed!", __FUNCTION__, XDTClassNameParser,
              syntaxType, _outputWarnings? @"true" : @"false");
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

    parserPythonModule = pModule;
    Py_INCREF(parserPythonModule);
    parserPythonClass = parser;
    Py_INCREF(parserPythonClass);

    return self;
}


- (void)dealloc
{
    Py_CLEAR(parserPythonClass);

#if !__has_feature(objc_arc)
    [super dealloc];
#endif
}


#pragma mark - Property Wrapper


/**
 Part of \p XDTParserProtocol
 */
- (id)symbols { return nil; }
/*- (XDTGa99Symbols *)symbols
{
    PyObject *symbols = PyObject_GetAttrString(parserPythonClass, "symbols");
    return [XDTGa99Symbols symbolsWithPythonInstance:symbols];
}*/


- (void)setPath:(NSString *)path
{
    PyStringObject *pathString = [path pythonString];
    PyObject_SetAttrString(parserPythonClass, "path", (PyObject *)pathString);
    /* TODO: Don't know if the reference count is changed after setting the attribute. */
    Py_XDECREF(pathString);
}


- (NSString *)path
{
    PyObject *pathString = PyObject_GetAttrString(parserPythonClass, "path");
    if (NULL == pathString) {
        return nil;
    }

    NSString *retVal = [NSString stringWithPythonString:pathString encoding:NSUTF8StringEncoding];
    Py_DECREF(pathString);

    return retVal;
}


- (void)setSource:(NSString *)source
{
    PyStringObject *sourceString = [source pythonString];
    PyObject_SetAttrString(parserPythonClass, "source", (PyObject *)sourceString);
    /* TODO: Don't know if the reference count is changed after setting the attribute. */
    Py_XDECREF(sourceString);
}


/**
 Part of \p XDTParserProtocol
 */
- (NSString *)literalForPlaceholder:(NSString *)key
{
    if (![key hasPrefix:@"'"] || ![key hasSuffix:@"'"]) {
        return nil;
    }
    
    PyObject *literalList = PyObject_GetAttrString(parserPythonClass, "text_literals");
    if (NULL == literalList) {
        return nil;
    }

    const Py_ssize_t itemCount = PyList_Size(literalList);
    if (0 > itemCount) {
        return nil;
    }
    NSString *retVal = nil;
    int i = [[key substringWithRange:NSMakeRange(1, key.length-2)] intValue];
    PyObject *literal = PyList_GetItem(literalList, i);
    if (NULL != literal) {
        retVal = [NSString stringWithPythonString:literal encoding:NSUTF8StringEncoding];
    }
    Py_DECREF(literalList);

    return retVal;
}


#pragma mark - Method Wrapper


- (NSString *)findFile:(NSString *)name error:(NSError **)error
{
    /*
     Function call in Python:
     find(filename)
     */
    PyObject *methodName = PyString_FromString("find");
    PyObject *pFilename = PyString_FromString([name UTF8String]);
    PyObject *filePath = PyObject_CallMethodObjArgs(parserPythonClass, methodName, pFilename, NULL);
    Py_XDECREF(pFilename);
    Py_XDECREF(methodName);
    if (NULL == filePath) {
        NSLog(@"%s ERROR: find(%@) returns NULL!", __FUNCTION__, name);
        PyObject *exeption = PyErr_Occurred();
        if (NULL != exeption) {
            if (nil != error) {
                *error = [NSError errorWithPythonError:exeption localizedRecoverySuggestion:nil];
            }
            PyErr_Print();
        }
        return nil;
    }
    
    NSString *retVal = [NSString stringWithPythonString:filePath encoding:NSUTF8StringEncoding];
    Py_DECREF(filePath);
    
    return retVal;
}


#pragma mark Extension Methods


- (NSOrderedSet<NSURL *> *)includedFiles:(NSError **)error
{
    NSMutableOrderedSet *retVal = [NSMutableOrderedSet orderedSet];
    
    PyObject *sourceString = PyObject_GetAttrString(parserPythonClass, "source");
    if (NULL == sourceString) {
        if (nil != error) {
            *error = nil;
        }
        return retVal;
    }

    NSString *sourceCode = [NSString stringWithPythonString:sourceString encoding:NSUTF8StringEncoding];
    Py_DECREF(sourceString);

    NSRegularExpression *findCopyDirectives = [NSRegularExpression regularExpressionWithPattern:@"\\s+COPY\\s+\"(\\S{3,})\""
                                                                                        options:NSRegularExpressionCaseInsensitive
                                                                                          error:nil];
    __block NSError *myError = nil;
    [findCopyDirectives enumerateMatchesInString:sourceCode
                                         options:NSMatchingReportCompletion
                                           range:NSMakeRange(0, sourceCode.length)
                                      usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
                                          if (flags & NSMatchingInternalError) {
                                              *stop = YES;
                                          }
                                          if (nil == result) {
                                              return;   /* nothing found */
                                          }

                                          NSString *includingFileName = [sourceCode substringWithRange:[result rangeAtIndex:1]];
                                          NSString *filePath = [self findFile:includingFileName error:&myError];
                                          if (nil == filePath) {
                                              *stop = nil != myError;
                                              return;
                                          }
                                          NSURL *includingURL = [NSURL fileURLWithPath:filePath];
                                          if ([[NSFileManager defaultManager] isReadableFileAtPath:[includingURL path]]) {
                                              [retVal addObject:includingURL];
                                          }
                                      }];
    if (nil != error) {
        *error = myError;
    }

    return retVal;
}


/**
 The method \p parseFirstPass is not finally implemented!
 */
- (BOOL)parse
{
    XDTAs99Objdummy *objdummy = nil;
    /*
     Function call in Python:
     errors, warnings = parse(code)
     */
    PyObject *methodName = PyString_FromString("parse");
    PyObject *lcTracker = NULL;
    PyObject *dummy = PyObject_CallMethodObjArgs(parserPythonClass, methodName, lcTracker, NULL);
    Py_XDECREF(methodName);
    Py_XDECREF(dummy);

    [self willChangeValueForKey:NSStringFromSelector(@selector(messages))];
    //_messages = (XDTMessage *)newMessages;
    [self didChangeValueForKey:NSStringFromSelector(@selector(messages))];

    return YES;
}


/**
 Part of \p XDTParserProtocol
 */
- (NSArray<id> *)splitLine:(NSString *)line error:(NSError **_Nullable)error
{
    /*
     Function call in Python:
     label, mnemonic, operands, comment, is_stmt = line(line)
     */
    PyObject *methodName = PyString_FromString("line");
    PyObject *pLine = PyString_FromString([line UTF8String]);
    PyObject *pValueTupel = PyObject_CallMethodObjArgs(parserPythonClass, methodName, pLine, NULL);
    Py_XDECREF(pLine);
    Py_XDECREF(methodName);
    if (NULL == pValueTupel) {
        NSLog(@"%s ERROR: line(\"%@\") returns NULL!", __FUNCTION__, line);
        PyObject *exeption = PyErr_Occurred();
        if (NULL != exeption) {
            if (nil != error) {
                *error = [NSError errorWithPythonError:exeption localizedRecoverySuggestion:nil];
            }
            PyErr_Print();
        }
        return nil;
    }

    NSMutableArray<id> *retVal = [NSMutableArray arrayWithPyTuple:pValueTupel];
    Py_DECREF(pValueTupel);
    if (![retVal.lastObject boolValue]) {
        /* line contains no statement */
        return @[];
    }

    [retVal removeLastObject];
    return retVal;
}


/**
 Part of \p XDTParserProtocol
 */
- (NSArray<id> *)splitLine:(NSString *)line
{
    return [self splitLine:line error:nil];
}


/**
 Part of \p XDTParserProtocol
 */
- (NSString *)filename:(NSString *)key error:(NSError **)error
{
    /*
     Function call in Python:
     filename = parser.filename(op)
     */
    PyObject *methodName = PyString_FromString("filename");
    PyObject *pKey = PyString_FromString([key UTF8String]);
    PyObject *pFilename = PyObject_CallMethodObjArgs(parserPythonClass, methodName, pKey, NULL);
    Py_XDECREF(pKey);
    Py_XDECREF(methodName);
    if (NULL == pFilename) {
        NSLog(@"%s ERROR: filename(\"%@\") returns NULL!", __FUNCTION__, key);
        PyObject *exeption = PyErr_Occurred();
        if (NULL != exeption) {
            if (nil != error) {
                *error = [NSError errorWithPythonError:exeption localizedRecoverySuggestion:nil];
            }
            PyErr_Print();
        }
        return nil;
    }

    NSString *retVal = [NSString stringWithPythonString:pFilename encoding:NSUTF8StringEncoding];
    Py_DECREF(pFilename);

    return retVal;
}


/**
 Part of \p XDTParserProtocol
 */
- (NSString *)text:(NSString *)key error:(NSError **)error
{
    /*
     Function call in Python:
     text = parser.text(op)
     */
    PyObject *methodName = PyString_FromString("text");
    PyObject *pKey = PyString_FromString([key UTF8String]);
    PyObject *pText = PyObject_CallMethodObjArgs(parserPythonClass, methodName, pKey, NULL);
    Py_XDECREF(pKey);
    Py_XDECREF(methodName);
    if (NULL == pText) {
        NSLog(@"%s ERROR: text(\"%@\") returns NULL!", __FUNCTION__, key);
        PyObject *exeption = PyErr_Occurred();
        if (NULL != exeption) {
            if (nil != error) {
                *error = [NSError errorWithPythonError:exeption localizedRecoverySuggestion:nil];
            }
            PyErr_Print();
        }
        return nil;
    }

    NSString *retVal = nil;
    // since TEXT can have a byte string, which can contains 0x00 (so string terminators), handle that like an byte array.
    if (PyString_Check(pText)) {
        NSUInteger textSize = PyString_Size(pText);
        const char *textString = PyString_AsString(pText);
        retVal = [[NSString alloc] initWithBytes:textString length:textSize encoding:NSASCIIStringEncoding];
    } else {
        NSUInteger textSize = PyByteArray_Size(pText);
        const char *textString = PyByteArray_AsString(pText);
        retVal = [[NSString alloc] initWithBytes:textString length:textSize encoding:NSASCIIStringEncoding];
    }
    Py_DECREF(pText);

    return retVal;
}

@end
