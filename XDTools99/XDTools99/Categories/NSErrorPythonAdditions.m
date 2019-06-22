//
//  NSErrorPythonAdditions.m
//  XDTools99
//
//  Created by Henrik Wedekind on 05.12.16.
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

#import "NSErrorPythonAdditions.h"
#import "NSStringPythonAdditions.h"

#import "XDTObject.h"


@implementation NSError (NSErrorPythonAdditions)

+ (instancetype)errorWithPythonError:(PyObject *)error localizedRecoverySuggestion:(NSString *)recoverySuggestion
{
    return [self errorWithPythonError:error localizedRecoverySuggestion:recoverySuggestion clearErrorIndicator:NO];
}


+ (instancetype)errorWithPythonError:(PyObject *)error localizedRecoverySuggestion:(NSString *)recoverySuggestion clearErrorIndicator:(BOOL)clearIndicator
{
    XDTErrorCode errorCode = XDTErrorCodePythonException;
    NSString *errorString = nil;
    NSString *errorDescription = nil;

    NSBundle *myBundle = [NSBundle bundleForClass:[self class]];
    if (PyString_Check(error)) {
        /* The error is just a simple error message */
        errorCode = XDTErrorCodePythonError;
        errorString = [NSString stringWithUTF8String:PyString_AsString(error)];
        errorDescription = NSLocalizedStringFromTableInBundle(@"Python error occured!", nil, myBundle, @"Description for an error object, discribing that there is an error occured.");
    } else if (PyExceptionClass_Check(error)) {
        /* Or the error can be an exception, so fetch more information here. */
        errorCode = XDTErrorCodePythonException;
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
        errorDescription = NSLocalizedStringFromTableInBundle(@"Python exception occured!", nil, myBundle, @"Description for an error object, discribing that there is an exception occured.");
    } else {
        /* unknow Python class, don't know how to generate strings */
        return nil;
    }

    NSDictionary *errorDict = nil;
    if (nil == recoverySuggestion) {
        errorDict = @{
                      NSLocalizedDescriptionKey: errorDescription,
                      NSLocalizedFailureReasonErrorKey: errorString /* can not localize all possible error messages which came from Python */
                      };
    } else {
        errorDict = @{
                      NSLocalizedDescriptionKey: errorDescription,
                      NSLocalizedFailureReasonErrorKey: errorString,/* can not localize all possible error messages which came from Python */
                      NSLocalizedRecoverySuggestionErrorKey: recoverySuggestion /* the recovery suggestion should be already translated */
                      };
    }
    return [NSError errorWithDomain:XDTErrorDomain code:errorCode userInfo:errorDict];
}

@end
