//
//  NSSetPythonAdditions.h
//  XDTools99
//
//  Created by henrik on 22.06.19.
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

#import <Foundation/Foundation.h>

#import <Python/Python.h>


NS_ASSUME_NONNULL_BEGIN

@interface NSSet (NSSetPythonAdditions)

+ (nullable NSSet<id> *)setWithPyTuple:(PyObject *)dataTuple;
+ (nullable NSSet<id> *)setWithPyList:(PyObject *)dataTuple;
+ (nullable NSSet<NSArray<id> *> *)setWithPyListOfTuple:(PyObject *)dataList;
+ (nullable NSSet<NSData *> *)setWithPyListOfData:(PyObject *)dataList;
+ (nullable NSSet<NSString *> *)setWithPyListOfString:(PyObject *)dataList;

@end

NS_ASSUME_NONNULL_END
