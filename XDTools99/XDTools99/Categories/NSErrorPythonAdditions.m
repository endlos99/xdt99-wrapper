//
//  NSErrorPythonAdditions.m
//  SimpleXDT99
//
//  Created by Henrik Wedekind on 05.12.16.
//
//  XDTools99.framework a collection of Objective-C wrapper for xdt99
//  Copyright © 2016-2017 Henrik Wedekind (aka hackmac). All rights reserved.
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

#import "NSErrorPythonAdditions.h"
#import "NSStringPythonAdditions.h"

#import "XDTObject.h"


@implementation NSError (NSErrorPythonAdditions)

+ (instancetype)errorWithPythonError:(PyObject *)error code:(NSInteger)code RecoverySuggestion:(NSString *)recoverySuggestion
{
    return [self errorWithPythonError:error code:code RecoverySuggestion:recoverySuggestion clearErrorIndicator:NO];
}


+ (instancetype)errorWithPythonError:(PyObject *)error code:(NSInteger)code RecoverySuggestion:(NSString *)recoverySuggestion clearErrorIndicator:(BOOL)clearIndicator
{
    NSString *errorString = nil;
    NSString *errorDescription = nil;

    if (PyString_Check(error)) {
        /* The error is just a simple error message */
        errorString = [NSString stringWithUTF8String:PyString_AsString(error)];
        errorDescription = @"Python error occured!";
    } else if (PyExceptionClass_Check(error)) {
        /* Or the error can be an exception, so fetch more information here. */
        PyTypeObject *eType = NULL;
        PyObject *eObject = NULL;
        PyTracebackObject *eTraceBack = NULL;
        PyErr_Fetch((PyObject **)&eType, &eObject, (PyObject **)&eTraceBack);
        PyErr_NormalizeException((PyObject **)&eType, &eObject, (PyObject **)&eTraceBack);
        errorString = [NSString stringWithFormat:@"Exception %s: \"%@\"",
                       PyExceptionClass_Name(error), [NSString stringWithPythonString:eObject encoding:NSUTF8StringEncoding]];
        /* If the exception will not be handle here, restore it. */
        if (clearIndicator) {
            Py_XDECREF(eType);
            Py_XDECREF(eObject);
            Py_XDECREF(eTraceBack);
        } else {
            // When using PyErr_Restore() there is no need to use Py_XDECREF for these 3 pointers
            PyErr_Restore((PyObject *)eType, eObject, (PyObject *)eTraceBack);
        }
        errorDescription = @"Python exception occured!";
    } else {
        /* unknow Python class, don't know how to generate strings */
        return nil;
    }

    NSDictionary *errorDict = nil;
    if (nil == recoverySuggestion) {
        errorDict = @{
                      NSLocalizedDescriptionKey: errorDescription,
                      NSLocalizedRecoverySuggestionErrorKey: errorString
                      };
    } else {
        errorDict = @{
                      NSLocalizedDescriptionKey: errorDescription,
                      NSLocalizedRecoverySuggestionErrorKey: [NSString stringWithFormat:@"%@\n%@", errorString, recoverySuggestion]
                      };
    }
    return [NSError errorWithDomain:XDTErrorDomain code:code userInfo:errorDict];
}

@end
