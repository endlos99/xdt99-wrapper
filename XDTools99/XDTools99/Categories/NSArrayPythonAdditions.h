//
//  NSArrayPythonAdditions.h
//  XDTools99
//
//  Created by Henrik Wedekind on 04.12.16.
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

#import <Python/Python.h>


NS_ASSUME_NONNULL_BEGIN
@interface NSArray (NSArrayPythonAdditions)

/**
 Creates and returns an NSArray object with all elements from the given Python tuple.

 @param dataTuple   The Python object that contains a tuple.
 @return A new array with the elements from the Python tuple. If the tuple is empty, a @p nil value will be returned.

 The elements of the created array could have different types and will be converted from thier typical Python classes into compatible Objective-C classes.
 */
+ (nullable instancetype)arrayWithPyTuple:(PyObject *)dataTuple;

/**
 Creates and returns an NSArray object with all elements from the given Python list.

 @param dataList    The Python object that contains a list.
 @return A new array with the elements from the Python list. If the list is empty, a @p nil value will be returned.

 The elements of the created array could have different types and will be converted from thier typical Python classes into compatible Objective-C classes.
 */
+ (nullable instancetype)arrayWithPyList:(PyObject *)dataList;

/**
 Creates and returns an NSArray object with all tuple as an array from the given Python list.

 @param dataList   The Python object that contains a list of tuple.
 @return The returned new array will contain new arrays from the tuple within the Python list. If the list is empty or does not contain tuple as elements, a @p nil value will be returned.

 The elements of the created array will all be of type NSArray, which could have different types and will be converted from thier typical Python classes into compatible Objective-C classes. The effective type is (NSArray<NSArray<id> *> *)
 */
+ (nullable instancetype)arrayWithPyListOfTuple:(PyObject *)dataList;

/**
 Creates and returns an NSArray object with all elements from the given Python list.

 @param dataList    The Python object that contains a list.
 @return A new array with the elements from the Python list. If the list is empty, a @p nil value will be returned.

 The elements getting from the Python list will all have unknown content, packed within a Python string type. For that reason these elements will be converted into NSData objects. The effective type is (NSArray<NSData *> *)
 */
+ (nullable instancetype)arrayWithPyListOfData:(PyObject *)dataList;

/**
 Creates and returns an NSArray object with all elements from the given Python list.

 @param dataList    The Python object that contains a list.
 @return A new array with the elements from the Python list. If the list is empty or the element have the wrong type, a @p nil value will be returned.

 The elements getting from the Python list will all be Python string types. For that reason these elements will be converted into NSString objects with UTF-8 encoding. The effective type is (NSArray<NSString *> *)
 */
+ (nullable instancetype)arrayWithPyListOfString:(PyObject *)dataList;

@end
NS_ASSUME_NONNULL_END
