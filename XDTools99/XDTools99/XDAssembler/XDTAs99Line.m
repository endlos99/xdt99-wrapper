//
//  XDTAs99Line.m
//  XDTools99
//
//  Created by Henrik Wedekind on 17.07.19.
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

#import "XDTAs99Line.h"

#import <Python/Python.h>

#import "NSStringPythonAdditions.h"


#define XDTClassNameLine "Line"


NS_ASSUME_NONNULL_BEGIN

@interface XDTAs99Line ()

- (instancetype)initWithPythonInstance:(PyObject *)object;

@end

NS_ASSUME_NONNULL_END


@implementation XDTAs99Line

+ (NSString *)pythonClassName
{
    return [NSString stringWithUTF8String:XDTClassNameLine];
}


+ (instancetype)lineWithPythonInstance:(PyObject *)object
{
    XDTAs99Line *retVal = [[XDTAs99Line alloc] initWithPythonInstance:object];
#if !__has_feature(objc_arc)
    [retVal autorelease];
#endif
    return retVal;
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


- (NSUInteger)lineNo
{
    PyObject *lineNo = PyObject_GetAttrString(self.pythonInstance, "lino");
    if (NULL == lineNo) {
        return NSNotFound;
    }

    NSUInteger retVal = PyLong_AsUnsignedLong(lineNo);
    return retVal;
}


- (NSString *)line
{
    PyObject *line = PyObject_GetAttrString(self.pythonInstance, "line");
    if (NULL == line) {
        return nil;
    }

    NSString *retVal = [NSString stringWithPythonString:line encoding:NSUTF8StringEncoding];
    return retVal;
}


- (BOOL)isEos
{
    PyObject *isEos = PyObject_GetAttrString(self.pythonInstance, "eos");
    if (NULL == isEos) {
        return NO;
    }

    BOOL retVal = 1 == PyObject_IsTrue(isEos);
    return retVal;
}


#pragma mark - Method Wrapper


// Currently no method wrapper for accessors of Objdummy implemented

@end
