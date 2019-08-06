//
//  XDTGa99Syntax.m
//  XDTools99
//
//  Created by Henrik Wedekind on 22.07.19.
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

#import "XDTGa99Syntax.h"

#import <Python/Python.h>

#import "NSErrorPythonAdditions.h"

#import "XDTGa99SyntaxVariant.h"


#define XDTClassNameSyntax "Syntax"


NS_ASSUME_NONNULL_BEGIN

@interface XDTGa99Syntax ()

- (instancetype)initWithPythonInstance:(PyObject *)object;

@end

NS_ASSUME_NONNULL_END


@implementation XDTGa99Syntax

+ (NSString *)pythonClassName
{
    return [NSString stringWithUTF8String:XDTClassNameSyntax];
}


#pragma mark Initializers


+ (instancetype)syntaxWithPythonInstance:(PyObject *)object
{
    XDTGa99Syntax *retVal = [[XDTGa99Syntax alloc] initWithPythonInstance:object];
#if !__has_feature(objc_arc)
    return [retVal autorelease];
#else
    return retVal;
#endif
}


- (instancetype)initWithPythonInstance:(PyObject *)object
{
    self = [super initWithPythonInstance:object];
    if (nil == self) {
        return nil;
    }

    // nothing to do here

    return self;
}


- (void)dealloc
{
#if !__has_feature(objc_arc)
    [super dealloc];
#endif
}


#pragma mark - Property Wrapper


#pragma mark - Method Wrapper


+ (XDTGa99SyntaxVariant *)syntaxVariantForType:(XDTGa99SyntaxType)syntaxType error:(NSError **)error
{
    // get(syntaxType)
    PyObject *methodName = PyString_FromString("get");
    PyObject *pSyntaxType = PyString_FromString([self syntaxTypeAsCString:syntaxType]);
    PyObject *pResult = PyObject_CallMethodObjArgs(self.xdtGa99ModuleInstance, methodName, pSyntaxType, NULL);
    Py_XDECREF(pSyntaxType);
    Py_XDECREF(methodName);
    if (NULL == pResult) {
        NSLog(@"%s ERROR: get(%s) returns NULL!", __FUNCTION__, [self syntaxTypeAsCString:syntaxType]);
        PyObject *exeption = PyErr_Occurred();
        if (NULL != exeption) {
            if (nil != error) {
                *error = [NSError errorWithPythonError:exeption localizedRecoverySuggestion:nil];
            }
            PyErr_Print();
        }
        return nil;
    }

    XDTGa99SyntaxVariant *retVal = [XDTGa99SyntaxVariant syntaxVariantWithPythonInstance:pResult];
    Py_DECREF(pResult);
    return retVal;
}


#pragma mark - Helper Methods


+ (const char *)syntaxTypeAsCString:(XDTGa99SyntaxType)syntaxType
{
    switch (syntaxType) {
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

@end
