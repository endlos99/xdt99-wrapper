//
//  XDTAs99Parser.m
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
#import "XDTAs99Preprocessor.h"


#define XDTClassNameParser "Parser"


NS_ASSUME_NONNULL_BEGIN

@interface XDTAs99Parser () {
    //PyObject *_objdummy;
}

- (instancetype)initWithModule:(PyObject *)pModule path:(NSString *)path usingRegisterSymbol:(BOOL)useRegisterSymbol strictness:(BOOL)beStrict outputWarnings:(BOOL)outputWarnings;

@end

NS_ASSUME_NONNULL_END


@implementation XDTAs99Parser

+ (NSString *)pythonClassName
{
    return [NSString stringWithUTF8String:XDTClassNameParser];
}


+ (nullable instancetype)parserForPath:(NSString *)path usingRegisterSymbol:(BOOL)useRegisterSymbol strictness:(BOOL)beStrict outputWarnings:(BOOL)outputWarnings
{
    @synchronized (self) {
        PyObject *pModule = self.xdtAs99ModuleInstance;
        if (NULL == pModule) {
            return nil;
        }

        XDTAs99Parser *retVal = [[XDTAs99Parser alloc] initWithModule:pModule path:path usingRegisterSymbol:useRegisterSymbol strictness:beStrict outputWarnings:outputWarnings];
#if !__has_feature(objc_arc)
        return [retVal autorelease];
#else
        return retVal;
#endif
    }
}


- (instancetype)initWithModule:(PyObject *)pModule path:(NSString *)path usingRegisterSymbol:(BOOL)useRegisterSymbol strictness:(BOOL)beStrict outputWarnings:(BOOL)outputWarnings
{
    assert(NULL != pModule);

    /*
     Create instance of the Symbol class which will be passed as a parameter for the constructor of Parser()
     */
    PyObject *pSymbolsFunc = PyObject_GetAttrString(pModule, XDTAs99Symbols.pythonClassName.UTF8String);
    if (NULL == pSymbolsFunc || !PyCallable_Check(pSymbolsFunc)) {
        NSLog(@"%s ERROR: Cannot find class \"%s\" in module %s", __FUNCTION__, XDTAs99Symbols.pythonClassName.UTF8String, PyModule_GetName(pModule));
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
    PyObject *pDefs = PyList_New(0);
    PyObject *pPath = (nil == path)? PyString_FromString(".") : path.asPythonType;
    PyObject *pIncludePath = PyList_New(0);
    /*for (NSURL *url in urls) {
     PyList_Append(includePath, PyString_FromString([[url path] UTF8String]));
     }*/
    PyObject *pStrictMode = PyBool_FromLong(beStrict);
    PyObject *pOutputWarnings = PyBool_FromLong(outputWarnings);
    PyObject *pAddRegisters = PyBool_FromLong(useRegisterSymbol);
    PyObject *pConsole = PyList_New(0);

    /* creating symbols object:
        symbols = Symbols(add_registers=self.optr, add_defs=self.defs)
     */
    PyObject *pSymbolsArgs = PyTuple_Pack(2, pAddRegisters, pDefs);
    PyObject *pSymbols = PyObject_CallObject(pSymbolsFunc, pSymbolsArgs);
    Py_XDECREF(pSymbolsArgs);
    Py_DECREF(pSymbolsFunc);

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
    PyObject *pArgs = PyTuple_Pack(7, pSymbols, pPath, pIncludePath, pStrictMode, pOutputWarnings, pAddRegisters, pConsole);
    PyObject *parser = PyObject_CallObject(pFunc, pArgs);
    Py_XDECREF(pArgs);
    Py_XDECREF(pFunc);
    if (NULL == parser) {
        NSLog(@"%s ERROR: calling constructor %s([], [], %s, %s, %s, []) failed!", __FUNCTION__, XDTClassNameParser,
              self.beStrict? "true" : "false", outputWarnings? "true" : "false", useRegisterSymbol? "true" : "false");
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

    self = [super initWithPythonInstance:parser];
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
    PyObject *pResult = PyObject_GetAttrString(self.pythonInstance, "use_R");
    if (NULL == pResult) {
        return NO;
    }

    return 1 == PyObject_IsTrue(pResult);
}


- (void)setUseRegisterSymbols:(BOOL)useRegisterSymbols
{
    PyObject *pUseR = PyBool_FromLong(useRegisterSymbols);
    (void)PyObject_SetAttrString(self.pythonInstance, "use_R", pUseR);
    Py_XDECREF(pUseR);
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
    (void)PyObject_SetAttrString(self.pythonInstance, "strict", pStrict);
    Py_XDECREF(pStrict);
}


- (BOOL)outputWarnings
{
    PyObject *pResult = PyObject_GetAttrString(self.pythonInstance, "warnings_enabled");
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
    (void)PyObject_SetAttrString(self.pythonInstance, "warnings_enabled", pWarnings);
    Py_XDECREF(pWarnings);
}


/**
 Part of \p XDTParserProtocol
 */
- (XDTAs99Symbols *)symbols
{
    PyObject *pSymbolObject = PyObject_GetAttrString(self.pythonInstance, "symbols");
    if (NULL == pSymbolObject) {
        return nil;
    }

    XDTAs99Symbols *codeSymbols = [XDTAs99Symbols symbolsWithPythonInstance:pSymbolObject];
    Py_DECREF(pSymbolObject);
    return codeSymbols;
}


- (void)setPath:(NSString *)path
{
    PyObject *pathString = (nil == path)? Py_None : path.asPythonType;
    (void)PyObject_SetAttrString(self.pythonInstance, "path", pathString);
    if (Py_None != pathString) {
        Py_XDECREF(pathString);
    }
}


- (NSString *)path
{
    PyObject *pathString = PyObject_GetAttrString(self.pythonInstance, "path");
    if (NULL == pathString) {
        return nil;
    }

    NSString *retVal = [NSString stringWithPythonString:pathString encoding:NSUTF8StringEncoding];
    Py_DECREF(pathString);
    return retVal;
}


- (XDTAs99Preprocessor *)preprocessor
{
    if (NULL == self.pythonInstance) {
        return nil;
    }
    PyObject *pPrep = PyObject_GetAttrString(self.pythonInstance, "prep");
    if (NULL == pPrep) {
        return nil;
    }
    
    XDTAs99Preprocessor *retVal = [XDTAs99Preprocessor preprocessorWithPythonInstance:pPrep];
    Py_DECREF(pPrep);
    return retVal;
}


- (void)setSource:(NSString *)source
{
    PyObject *sourceString = (nil == source)? Py_None : source.asPythonType;
    (void)PyObject_SetAttrString(self.pythonInstance, "source", sourceString);
    if (Py_None != sourceString) {
        Py_XDECREF(sourceString);
    }
}


/**
 Part of \p XDTParserProtocol
 */
- (NSString *)literalForPlaceholder:(NSString *)key
{
    if (NULL == self.pythonInstance || ![key hasPrefix:@"'"] || ![key hasSuffix:@"'"]) {
        return nil;
    }

    PyObject *literalList = PyObject_GetAttrString(self.pythonInstance, "text_literals");
    if (NULL == literalList) {
        return nil;
    }

    const Py_ssize_t itemCount = PyList_Size(literalList);
    if (0 > itemCount) {
        Py_DECREF(literalList);
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


- (BOOL)openSourceFile:(NSString *)fileName macroBuffer:(NSString *)macroName ops:(NSArray<id> *)ops error:(NSError **)error
{
    /*
     Function call in Python:
     open(filename, macro, ops)
     */
    PyObject *methodName = PyString_FromString("open");
    PyObject *pFilename = (nil == fileName)? Py_None : fileName.asPythonType;
    PyObject *pMacro = (nil == macroName)? Py_None : macroName.asPythonType;
    PyObject *pOps = ops.asPythonType;
    PyObject *pResult = PyObject_CallMethodObjArgs(self.pythonInstance, methodName, pFilename, pMacro, pOps, NULL);
    Py_XDECREF(pOps);
    Py_XDECREF(pMacro);
    Py_XDECREF(pFilename);
    Py_XDECREF(methodName);
    NSLog(@"%s ERROR: open(\"%@\", \"%@\", @[%@]) returns NULL!", __FUNCTION__, fileName, macroName, ops);
    if (NULL == pResult) {
        PyObject *exeption = PyErr_Occurred();
        if (NULL != exeption) {
            if (nil != error) {
                *error = [NSError errorWithPythonError:exeption localizedRecoverySuggestion:nil];
            }
            PyErr_Print();
        }
        return NO;
    }

    Py_DECREF(pResult);
    return YES;
}


- (BOOL)resume:(NSError **)error
{
    /*
     Function call in Python:
     resume()
     */
    PyObject *methodName = PyString_FromString("resume");
    PyObject *pResult = PyObject_CallMethodObjArgs(self.pythonInstance, methodName, NULL);
    Py_XDECREF(methodName);
    NSLog(@"%s ERROR: resume() returns NULL!", __FUNCTION__);
    if (NULL == pResult) {
        PyObject *exeption = PyErr_Occurred();
        if (NULL != exeption) {
            if (nil != error) {
                *error = [NSError errorWithPythonError:exeption localizedRecoverySuggestion:nil];
            }
            PyErr_Print();
        }
        return NO;
    }
    
    BOOL retVal = 1 == PyObject_IsTrue(pResult);
    Py_DECREF(pResult);
    return retVal;
}


- (BOOL)stop:(NSError **)error
{
    /*
     Function call in Python:
     stop()
     */
    PyObject *methodName = PyString_FromString("stop");
    PyObject *pResult = PyObject_CallMethodObjArgs(self.pythonInstance, methodName, NULL);
    Py_XDECREF(methodName);
    NSLog(@"%s ERROR: resume() returns NULL!", __FUNCTION__);
    if (NULL == pResult) {
        PyObject *exeption = PyErr_Occurred();
        if (NULL != exeption) {
            if (nil != error) {
                *error = [NSError errorWithPythonError:exeption localizedRecoverySuggestion:nil];
            }
            PyErr_Print();
        }
        return NO;
    }

    Py_DECREF(pResult);
    return YES;
}


- (NSString *)findFile:(NSString *)name error:(NSError **_Nullable)error
{
    /*
     Function call in Python:
     find(filename)
     */
    PyObject *methodName = PyString_FromString("find");
    PyObject *pFilename = name.asPythonType;
    PyObject *filePath = PyObject_CallMethodObjArgs(self.pythonInstance, methodName, pFilename, NULL);
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
    PyObject *dummy = PyObject_CallMethodObjArgs(self.pythonInstance, methodName, lcTracker, NULL);
    Py_XDECREF(methodName);
    Py_XDECREF(lcTracker);
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
    PyObject *lineCountInteger = PyObject_CallMethodObjArgs(self.pythonInstance, methodName, NULL);
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
    PyObject *pLine = line.asPythonType;
    PyObject *pValueTupel = PyObject_CallMethodObjArgs(self.pythonInstance, methodName, pLine, NULL);
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

    NSMutableArray<id> *retVal = [NSMutableArray arrayWithPythonTuple:pValueTupel];
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
    PyObject *pKey = key.asPythonType;
    PyObject *pFilename = PyObject_CallMethodObjArgs(self.pythonInstance, methodName, pKey, NULL);
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
    PyObject *pKey = key.asPythonType;
    PyObject *pText = PyObject_CallMethodObjArgs(self.pythonInstance, methodName, pKey, NULL);
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

    PyObject *sourceString = PyObject_GetAttrString(self.pythonInstance, "source");
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
