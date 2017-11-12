//
//  NSErrorPythonAdditions.m
//  SimpleXDT99
//
//  Created by Henrik Wedekind on 05.12.16.
//
//  XDTools99.framework a collection of Objective-C wrapper for xdt99
//  Copyright © 2016 Henrik Wedekind (aka hackmac). All rights reserved.
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

#import "XDTObject.h"


@implementation NSError (NSErrorPythonAdditions)

+ (instancetype)errorWithPythonError:(PyObject *)error code:(NSInteger)code RecoverySuggestion:(NSString *)recoverySuggestion
{
    NSString *errorString = nil;
    NSString *errorDescription = nil;

    if (PyString_Check(error)) {
        /* The error is just a simple error message */
        errorString = [NSString stringWithUTF8String:PyString_AsString(error)];
        errorDescription = @"Python error occured!";
    } else {
        /* Or the error can be an exception, so fetch more information here. */
        PyObject *ptype = NULL;
        PyObject *pvalue = NULL;
        PyObject *ptraceback = NULL;
        PyErr_Fetch(&ptype, &pvalue, &ptraceback);
        errorString = [NSString stringWithFormat:@"Python Exception: \"%s\"", PyString_AsString(pvalue)];
        Py_XDECREF(ptype);
        Py_XDECREF(pvalue);
        Py_XDECREF(ptraceback);
        errorDescription = @"Python exception occured!";
    }

    NSDictionary *errorDict = nil;
    if (nil == recoverySuggestion) {
        errorDict = @{
                      NSLocalizedDescriptionKey: errorDescription,
                      NSLocalizedFailureReasonErrorKey: errorString
                      };
    } else {
        errorDict = @{
                      NSLocalizedDescriptionKey: errorDescription,
                      NSLocalizedFailureReasonErrorKey: errorString,
                      NSLocalizedRecoverySuggestionErrorKey: recoverySuggestion
                      };
    }
    return [NSError errorWithDomain:XDTErrorDomain code:code userInfo:errorDict];
}

@end
