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
#import "XDTGa99SyntaxVariant.h"
#import "XDTAs99Objdummy.h"


#define XDTClassNameParser "Parser"


NS_ASSUME_NONNULL_BEGIN

@interface XDTGa99Parser () {
    PyObject *objdummy;
}

- (instancetype)initWithModule:(PyObject *)pModule syntaxType:(XDTGa99SyntaxType)syntaxType outputWarnings:(BOOL)outputWarnings;

@end

NS_ASSUME_NONNULL_END


@implementation XDTGa99Parser

+ (NSString *)pythonClassName
{
    return [NSString stringWithUTF8String:XDTClassNameParser];
}


+ (nullable instancetype)parserWithSyntaxType:(XDTGa99SyntaxType)syntaxType outputWarnings:(BOOL)outputWarnings
{
    @synchronized (self) {
        PyObject *pModule = self.xdtGa99ModuleInstance;
        if (NULL == pModule) {
            return nil;
        }

        XDTGa99Parser *retVal = [[XDTGa99Parser alloc] initWithModule:pModule syntaxType:syntaxType outputWarnings:outputWarnings];
#if !__has_feature(objc_arc)
        return [retVal autorelease];
#endif
        return retVal;
    }
}


- (instancetype)initWithModule:(PyObject *)pModule syntaxType:(XDTGa99SyntaxType)syntaxType outputWarnings:(BOOL)outputWarnings
{
    assert(NULL != pModule);
    
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

    /* preparing parameters */
    PyObject *pDefs = PyList_New(0);
    PyObject *pSyntaxType = PyString_FromString([XDTGa99Syntax syntaxTypeAsCString:syntaxType]);
    PyObject *pIncludePath = PyList_New(0);
    /*for (NSURL *url in urls) {
     PyList_Append(includePath, PyString_FromString([[url path] UTF8String]));
     }*/
    PyObject *pOutputWarnings = PyBool_FromLong(outputWarnings);
    PyObject *pConsole = PyList_New(0);

    /* creating parser object:
        parser = Parser(symbols, syntax, include_path=None, warnings=True, console=None)
     */
    PyObject *pArgs = PyTuple_Pack(5, pDefs, pSyntaxType, pIncludePath, pOutputWarnings, pConsole);
    PyObject *pParser = PyObject_CallObject(pFunc, pArgs);
    Py_XDECREF(pArgs);
    Py_XDECREF(pFunc);
    if (NULL == pParser) {
        NSLog(@"%s ERROR: calling constructor %s([], %s, [], %s, []) failed!", __FUNCTION__, XDTClassNameParser,
              [XDTGa99Syntax syntaxTypeAsCString:syntaxType], outputWarnings? "true" : "false");
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

    self = [super initWithPythonInstance:pParser];
    Py_DECREF(pParser);
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


- (XDTGa99SyntaxVariant *)syntaxVariant
{
    PyObject *pResult = PyObject_GetAttrString(self.pythonInstance, "syntax");
    if (NULL == pResult) {
        return nil;
    }

    XDTGa99SyntaxVariant *retVal = [XDTGa99SyntaxVariant syntaxVariantWithPythonInstance:pResult];
    Py_XDECREF(pResult);
    return retVal;
}


- (void)setSyntaxVariant:(XDTGa99SyntaxVariant *)syntaxVariant
{
    (void)PyObject_SetAttrString(self.pythonInstance, "syntax", syntaxVariant.pythonInstance);
}


- (BOOL)outputWarnings
{
    PyObject *pResult = PyObject_GetAttrString(self.pythonInstance, "warnings_enabled");
    if (NULL == pResult) {
        return NO;
    }

    BOOL retVal = 1 == PyObject_IsTrue(pResult);
    Py_XDECREF(pResult);
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
- (id)symbols { return nil; }   // TODO: 
/*- (XDTGa99Symbols *)symbols
{
    PyObject *symbols = PyObject_GetAttrString(self.pythonInstance, "symbols");
    return [XDTGa99Symbols symbolsWithPythonInstance:symbols];
}*/


- (void)setPath:(NSString *)path
{
    PyObject *pathString = path.asPythonType;
    (void)PyObject_SetAttrString(self.pythonInstance, "path", pathString);
    Py_XDECREF(pathString);
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


- (void)setSource:(NSString *)source
{
    PyObject *sourceString = source.asPythonType;
    (void)PyObject_SetAttrString(self.pythonInstance, "source", sourceString);
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


- (NSString *)findFile:(NSString *)name error:(NSError **)error
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
    PyObject *dummy = PyObject_CallMethodObjArgs(self.pythonInstance, methodName, lcTracker, NULL);
    Py_XDECREF(dummy);
    Py_XDECREF(lcTracker);
    Py_XDECREF(methodName);

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

@end
