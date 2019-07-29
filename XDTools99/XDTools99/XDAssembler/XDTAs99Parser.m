//
//  XDTParser.m
//  XDTools99
//
//  Created by Henrik Wedekind on 30.06.19.
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

#import "XDTAs99Parser.h"

#import <Python/Python.h>

#import "NSStringPythonAdditions.h"
#import "NSErrorPythonAdditions.h"
#import "NSArrayPythonAdditions.h"

#import "XDTLineScanner.h"
#import "XDTAs99Symbols.h"
#import "XDTAs99Objdummy.h"


#define XDTModuleNameAssembler "xas99"
#define XDTClassNameParser "Parser"

#define XDTClassNameSymbols "Symbols"   /* defined in XDTSymbols.m */


NS_ASSUME_NONNULL_BEGIN

XDTAs99ParserOptionKey const XDTAs99ParserOptionRegister = @"XDTAs99ParserOptionRegister";
XDTAs99ParserOptionKey const XDTAs99ParserOptionStrict = @"XDTAs99ParserOptionStrict";
XDTAs99ParserOptionKey const XDTAs99ParserOptionWarnings = @"XDTAs99ParserOptionWarnings";


@interface XDTAs99Parser () {
    const PyObject *parserPythonModule;
    PyObject *parserPythonClass;
    //PyObject *_objdummy;
}

@property BOOL beStrict;
@property BOOL useRegisterSymbols;
@property BOOL outputWarnings;

- (instancetype)initWithOptions:(NSDictionary<XDTAs99ParserOptionKey, id> *)options forModule:(PyObject *)pModule;

@end

NS_ASSUME_NONNULL_END


@implementation XDTAs99Parser

+ (nullable instancetype)parserWithOptions:(NSDictionary<XDTAs99ParserOptionKey,id> *)options
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

        XDTAs99Parser *retVal = [[XDTAs99Parser alloc] initWithOptions:options forModule:pModule];
        Py_DECREF(pModule);
#if !__has_feature(objc_arc)
        return [retVal autorelease];
#else
        return retVal;
#endif
    }
}


- (instancetype)initWithOptions:(NSDictionary<XDTAs99ParserOptionKey, id> *)options forModule:(PyObject *)pModule
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
    if (0 != strcmp(PyString_AsString(pVersion), XDTAssemblerVersionRequired)) {
        NSLog(@"%s ERROR: Wrong Assembler version %s! Required is %s", __FUNCTION__, PyString_AsString(pVersion), XDTAssemblerVersionRequired);
        Py_XDECREF(pVersion);
#if !__has_feature(objc_arc)
        [self release];
#endif
        return nil;
    }
    Py_XDECREF(pVersion);

    /* reading options from dictionary */
    _beStrict = [[options valueForKey:XDTAs99ParserOptionStrict] boolValue];
    _useRegisterSymbols = [[options valueForKey:XDTAs99ParserOptionRegister] boolValue];
    _outputWarnings = [[options valueForKey:XDTAs99ParserOptionWarnings] boolValue];

    /*
     Create instance of the Symbol class which will be passed as a parameter for the constructor of Parser()
     */
    PyObject *pSymbolsFunc = PyObject_GetAttrString(pModule, XDTClassNameSymbols);
    if (NULL == pSymbolsFunc || !PyCallable_Check(pSymbolsFunc)) {
        NSLog(@"%s ERROR: Cannot find class \"%s\" in module %s", __FUNCTION__, XDTClassNameSymbols, PyModule_GetName(pModule));
        if (PyErr_Occurred()) {
            PyErr_Print();
        }
        Py_XDECREF(pSymbolsFunc);
#if !__has_feature(objc_arc)
        [self release];
#endif
        return nil;
    }

    /* preparing parameters */
    PyObject *defs = PyList_New(0);
    PyObject *path = PyString_FromString(".");
    PyObject *includePath = PyList_New(0);
    /*for (NSURL *url in urls) {
     PyList_Append(includePath, PyString_FromString([[url path] UTF8String]));
     }*/
    PyObject *strictMode = PyBool_FromLong(_beStrict);
    PyObject *outputWarnings = PyBool_FromLong(_outputWarnings);
    PyObject *addRegisters = PyBool_FromLong(_useRegisterSymbols);
    PyObject *console = PyList_New(0);

    /* creating symbols object:
        symbols = Symbols(add_registers=self.optr, add_defs=self.defs)
     */
    PyObject *pSymbolsArgs = PyTuple_Pack(2, addRegisters, defs);
    PyObject *symbols = PyObject_CallObject(pSymbolsFunc, pSymbolsArgs);
    Py_XDECREF(pSymbolsArgs);
    Py_XDECREF(pSymbolsFunc);

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

    /* creating parser object:
        parser = Parser(symbols, path=path, includes=self.includes, strict=self.strict, warnings=self.warnings,
                        use_R=self.optr, console=self.console)
     */
    PyObject *pArgs = PyTuple_Pack(7, symbols, path, includePath, strictMode, outputWarnings, addRegisters, console);
    PyObject *parser = PyObject_CallObject(pFunc, pArgs);
    Py_XDECREF(pArgs);
    Py_XDECREF(pFunc);
    if (NULL == parser) {
        NSLog(@"%s ERROR: calling constructor %s([], [], %@, %@, %@, []) failed!", __FUNCTION__, XDTClassNameParser,
              _beStrict? @"true" : @"false", _outputWarnings? @"true" : @"false", _useRegisterSymbols? @"true" : @"false");
        PyObject *exeption = PyErr_Occurred();
        if (NULL != exeption) {
//            if (nil != error) {
//                *error = [NSError errorWithPythonError:exeption code:-2 localizedRecoverySuggestion:nil];
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
- (XDTAs99Symbols *)symbols
{
    PyObject *symbolObject = PyObject_GetAttrString(parserPythonClass, "symbols");
    XDTAs99Symbols *codeSymbols = [XDTAs99Symbols symbolsWithPythonInstance:symbolObject];
    Py_XDECREF(symbolObject);

    return codeSymbols;
}


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


- (NSString *)findFile:(NSString *)name error:(NSError **_Nullable)error
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
        NSLog(@"%s ERROR: find(\"%@\") returns NULL!", __FUNCTION__, name);
    if (NULL == filePath) {
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


/**
 The method \p parseFirstPass is not finally implemented!
 */
- (BOOL)parseFirstPass
{
    XDTAs99Objdummy *objdummy = nil;
    /*
     Function call in Python:
     source, errors = pass_1(dummy)
     */
    PyObject *methodName = PyString_FromString("pass_1");
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
 The method \p parseSecondPass is not finally implemented!
 */
- (BOOL)parseSecondPass
{
    /*
     Function call in Python:
     errors = pass_2(source, code, errors)
     */
    PyObject *methodName = PyString_FromString("pass_2");
    PyObject *lineCountInteger = PyObject_CallMethodObjArgs(parserPythonClass, methodName, NULL);
    Py_XDECREF(methodName);
    if (NULL == lineCountInteger) {
        return NO;
    }

    NSUInteger retVal = PyInt_AsLong(lineCountInteger);
    Py_DECREF(lineCountInteger);

    [self willChangeValueForKey:NSStringFromSelector(@selector(messages))];
    //_messages = (XDTMessage *)newMessages;
    [self didChangeValueForKey:NSStringFromSelector(@selector(messages))];
    
    return YES;
}


/**
 Part of \p XDTParserProtocol
 */
- (NSArray<id> *)splitLine:(NSString *)line error:(NSError **)error
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


#pragma mark - Extension Methods


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

@end
