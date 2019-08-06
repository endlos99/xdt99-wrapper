//
//  NSStringPythonAdditions.h
//  XDTools99
//
//  Created by Henrik Wedekind on 17.11.17.
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

#import <Foundation/Foundation.h>

#import <Python/object.h>


NS_ASSUME_NONNULL_BEGIN

@interface NSString (NSStringPythonAdditions)

+ (nullable instancetype)stringWithPythonString:(PyObject *)pyObj encoding:(NSStringEncoding)enc;

- (PyObject *)asPythonType;

@end

NS_ASSUME_NONNULL_END
