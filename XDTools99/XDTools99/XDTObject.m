//
//  XDTObject.m
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

#import "XDTObject.h"

#include <Python/Python.h>


@implementation XDTObject

/* This initializer setup python related things. */
+ (void)initialize
{
    @synchronized (self) {
        Py_Initialize();

        NSString *pyModulePath = [NSString stringWithFormat:@"%s:%@", Py_GetPath(), [[NSBundle bundleForClass:[self class]] resourcePath]];
        PySys_SetPath((char *)pyModulePath.UTF8String);
    }
}


/* This calss method is deprecated from macOS 10.8 on, but where should it be placed else? */
+ (void)finalize
{
    Py_Finalize();
}

@end
