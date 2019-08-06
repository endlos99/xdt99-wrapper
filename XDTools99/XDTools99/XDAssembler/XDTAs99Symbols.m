//
//  XDTAs99Symbols.m
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

#import "XDTAs99Symbols.h"

#import <Python/Python.h>

#import "NSDictionaryPythonAdditions.h"
#import "NSArrayPythonAdditions.h"
#import "NSStringPythonAdditions.h"


#define XDTClassNameSymbols "Symbols"


NS_ASSUME_NONNULL_BEGIN

@interface XDTAs99SymbolEntry ()

- initWithValue:(NSInteger)value weakness:(BOOL)isWeak trackingInfo:(XDTAs99SymbolTrackingInfo)info;

@end


@interface XDTAs99Symbols ()

- (nullable instancetype)initWithPythonInstance:(PyObject *)object;

@end

NS_ASSUME_NONNULL_END


#pragma mark -


@implementation XDTAs99SymbolEntry

- (id)initWithValue:(NSInteger)value weakness:(BOOL)isWeak trackingInfo:(XDTAs99SymbolTrackingInfo)info
{
    self = [super init];
    if (nil == self) {
        return nil;
    }

    _value = value;
    _weak = isWeak;
    _trackingInfo = info;

    return self;
}

@end


#pragma mark -


@implementation XDTAs99Symbols

+ (NSString *)pythonClassName
{
    return [NSString stringWithUTF8String:XDTClassNameSymbols];
}


+ (instancetype)symbolsWithPythonInstance:(PyObject *)object
{
    XDTAs99Symbols *retVal = [[XDTAs99Symbols alloc] initWithPythonInstance:object];
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


- (NSDictionary<NSString *,NSNumber *> *)extSymbols
{
    PyObject *extSymbolDict = PyObject_GetAttrString(self.pythonInstance, "exts");
    if (NULL == extSymbolDict) {
        return nil;
    }

    NSDictionary<NSString *, NSNumber *> *retVal = [NSDictionary dictionaryWithPythonDictionary:extSymbolDict];
    Py_DECREF(extSymbolDict);

    return retVal;
}


- (NSDictionary<NSString *, XDTAs99SymbolEntry *> *)symbols
{
    PyObject *symbolDict = PyObject_GetAttrString(self.pythonInstance, "symbols");
    if (NULL == symbolDict) {
        return nil;
    }

    // Values for keys are tripel: symbols[name] = (value, weak, unused)
    NSMutableDictionary<NSString *, id/*NSArray<id> **/> *retVal = [NSMutableDictionary dictionaryWithPythonDictionary:symbolDict];
    Py_DECREF(symbolDict);
    [retVal enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSArray<id> *tuple, BOOL *stop) {
        NSNumber *ti = [tuple objectAtIndex:2];
        XDTAs99SymbolEntry *entry = [[XDTAs99SymbolEntry alloc] initWithValue:[[tuple objectAtIndex:0] integerValue]
                                                                     weakness:[[tuple objectAtIndex:1] boolValue]
                                                                 trackingInfo:(nil == ti)? XDTAs99SymbolTrackingInfoNoTracking : ([ti boolValue])? XDTAs99SymbolTrackingInfoUnused : XDTAs99SymbolTrackingInfoNotUnused];
        [retVal setObject:entry forKey:key];
    }];

    return retVal;
}


- (NSArray<NSString *> *)symbolNames
{
    PyObject *symbolDict = PyObject_GetAttrString(self.pythonInstance, "symbols");
    if (NULL == symbolDict) {
        return nil;
    }

    Py_ssize_t itemCount = PyDict_Size(symbolDict);
    if (0 > itemCount) {
        return nil;
    }
    NSMutableArray<NSString *> *retVal = [NSMutableArray arrayWithCapacity:itemCount];
    PyObject *pKey, *pTuple;
    Py_ssize_t pos = 0;
    // Values for keys are tripel: symbols[name] = (value, weak, unused)
    while (PyDict_Next(symbolDict, &pos, &pKey, &pTuple)) {
        if (NULL != pKey) {
            [retVal addObject:[NSString stringWithPythonString:pKey encoding:NSUTF8StringEncoding]];
        }
    }
    Py_DECREF(symbolDict);

    return retVal;
}


- (NSArray<NSString *> *)refdefs
{
    PyObject *refdefsList = PyObject_GetAttrString(self.pythonInstance, "refdefs");
    if (NULL == refdefsList) {
        return nil;
    }

    NSArray<NSString *> *retVal = [NSArray arrayWithPythonList:refdefsList];
    Py_DECREF(refdefsList);

    return retVal;
}


- (NSDictionary<NSString *, NSNumber *> *)xops
{
    PyObject *xopDict = PyObject_GetAttrString(self.pythonInstance, "xops");
    if (NULL == xopDict) {
        return nil;
    }

    NSDictionary<NSString *, NSNumber *> *retVal = [NSDictionary dictionaryWithPythonDictionary:xopDict];
    Py_DECREF(xopDict);

    return retVal;
}


- (NSDictionary<NSString *, NSNumber *> *)locations
{
    PyObject *locationsList = PyObject_GetAttrString(self.pythonInstance, "locations");
    if (NULL == locationsList) {
        return nil;
    }

    Py_ssize_t itemCount = PyList_Size(locationsList);
    if (0 > itemCount) {
        return nil;
    }
    NSMutableDictionary<NSString *, NSNumber *> *retVal = [NSMutableDictionary dictionaryWithCapacity:itemCount];
    for (int i = 0; i < itemCount; i++) {
        PyObject *itemTupel = PyList_GetItem(locationsList, i);
        PyObject *location = PyTuple_GetItem(itemTupel, 0);
        PyObject *name = PyTuple_GetItem(itemTupel, 1);
        if (NULL != name) {
            [retVal setValue:[NSNumber numberWithLong:PyInt_AsLong(location)] forKey:[NSString stringWithUTF8String:PyString_AsString(name)]];
        }
    }
    Py_DECREF(locationsList);

    return retVal;
}


- (NSArray<NSArray *> *)autoGeneratedConstants
{
    PyObject *refdefsList = PyObject_GetAttrString(self.pythonInstance, "autogens");
    if (NULL == refdefsList) {
        return nil;
    }

    NSArray<NSArray *> *retVal = [NSArray arrayWithPythonList:refdefsList];
    Py_DECREF(refdefsList);

    return retVal;
}


#pragma mark - Method Wrapper


- (void)resetLineCounter
{
    /*
     Function call in Python:
     reset_LC()
     */
    PyObject *methodName = PyString_FromString("reset_LC");
    PyObject *dummy = PyObject_CallMethodObjArgs(self.pythonInstance, methodName, NULL);
    Py_XDECREF(methodName);
    Py_XDECREF(dummy);
}


- (NSUInteger)effectiveLineCounter
{
    /*
     Function call in Python:
     effective_LC()
     */
    PyObject *methodName = PyString_FromString("effective_LC");
    PyObject *lineCountInteger = PyObject_CallMethodObjArgs(self.pythonInstance, methodName, NULL);
    Py_XDECREF(methodName);
    if (NULL == lineCountInteger) {
        return NSNotFound;
    }

    NSUInteger retVal = PyInt_AsLong(lineCountInteger);
    Py_DECREF(lineCountInteger);

    return retVal;
}


- (BOOL)addSymbolValue:(NSInteger)value forName:(NSString *)name
{
    /*
     Function call in Python:
     add_symbol(name, value, weak=False, tracked=False)
     */
    PyObject *methodName = PyString_FromString("add_symbol");
    PyObject *pSymbolName = name.asPythonType;
    PyObject *pSymbolValue = PyInt_FromLong(value);
    PyObject *resultName = PyObject_CallMethodObjArgs(self.pythonInstance, methodName, pSymbolName, pSymbolValue, NULL);
    BOOL retVal = resultName == pSymbolName;
    if (!retVal) {
        Py_XDECREF(resultName);
    }
    Py_XDECREF(pSymbolValue);
    Py_XDECREF(pSymbolName);
    Py_XDECREF(methodName);

    return retVal;
}


- (NSArray<NSString *> *)unusedSymbolNames
{
    /*
     Function call in Python:
     get_unused()
     */
    PyObject *methodName = PyString_FromString("get_unused");
    PyObject *unusedList = PyObject_CallMethodObjArgs(self.pythonInstance, methodName, NULL);
    Py_XDECREF(methodName);

    NSArray *retVal = [NSArray arrayWithPythonListOfString:unusedList];
    Py_DECREF(unusedList);

    return retVal;
}


- (BOOL)addSymbol:(XDTAs99SymbolEntry *)symbolEntry forName:(NSString *)name
{
    /*
     Function call in Python:
     add_symbol(name, value, weak=False, tracked=False)
     */
    PyObject *methodName = PyString_FromString("add_symbol");
    PyObject *pSymbolName = name.asPythonType;
    PyObject *pSymbolValue = PyInt_FromLong(symbolEntry.value);
    PyObject *pSymbolWeakness = PyBool_FromLong(symbolEntry.isWeak);
    PyObject *pSymbolTracked = PyBool_FromLong(XDTAs99SymbolTrackingInfoNoTracking != symbolEntry.trackingInfo);
    PyObject *resultName = PyObject_CallMethodObjArgs(self.pythonInstance, methodName, pSymbolName, pSymbolValue, pSymbolWeakness, pSymbolTracked, NULL);
    BOOL retVal = resultName == pSymbolName;
    if (!retVal) {
        Py_XDECREF(resultName);
    }
    Py_XDECREF(pSymbolTracked);
    Py_XDECREF(pSymbolWeakness);
    Py_XDECREF(pSymbolValue);
    Py_XDECREF(pSymbolName);
    Py_XDECREF(methodName);

    return retVal;
}


- (BOOL)addLineIndex:(NSUInteger)lineIdx forLabel:(NSString *)label
{
    /*
     Function call in Python:
     add_label(lidx, label, realLC=False, tracked=False)
     */
    return [self addLineIndex:lineIdx forLabel:label usingEffectiveLineCount:NO tracked:NO];
}


- (BOOL)addLineIndex:(NSUInteger)lineIdx forLabel:(NSString *)label usingEffectiveLineCount:(BOOL)realLineCount tracked:(BOOL)tracked
{
    /*
     Function call in Python:
     add_label(lidx, label, realLC=False, tracked=False)
     */
    PyObject *methodName = PyString_FromString("add_label");
    PyObject *pLIdx = PyInt_FromLong(lineIdx);
    PyObject *pLabel = label.asPythonType;
    PyObject *pRealLC = PyBool_FromLong(realLineCount);
    PyObject *pTracked = PyBool_FromLong(tracked);
    PyObject *result = PyObject_CallMethodObjArgs(self.pythonInstance, methodName, pLIdx, pLabel, pRealLC, pTracked, NULL);
    BOOL retVal = NULL != result;
    Py_XDECREF(result);
    Py_XDECREF(pTracked);
    Py_XDECREF(pRealLC);
    Py_XDECREF(pLabel);
    Py_XDECREF(pLIdx);
    Py_XDECREF(methodName);

    return retVal;
}


- (BOOL)addLineIndex:(NSUInteger)lineIdx forLocalLabel:(NSString *)label
{
    /*
     Function call in Python:
     add_local_label(lidx, label)
     */
    PyObject *methodName = PyString_FromString("add_local_label");
    PyObject *pLIdx = PyInt_FromLong(lineIdx);
    PyObject *pLabel = label.asPythonType;
    PyObject *result = PyObject_CallMethodObjArgs(self.pythonInstance, methodName, pLIdx, pLabel, NULL);
    BOOL retVal = NULL != result;
    Py_XDECREF(result);
    Py_XDECREF(pLabel);
    Py_XDECREF(pLIdx);
    Py_XDECREF(methodName);

    return retVal;
}


- (BOOL)addDef:(NSString *)name
{
    /*
     Function call in Python:
     add_def(name)
     */
    PyObject *methodName = PyString_FromString("add_def");
    PyObject *pName = name.asPythonType;
    PyObject *result = PyObject_CallMethodObjArgs(self.pythonInstance, methodName, pName, NULL);
    BOOL retVal = NULL != result;
    Py_XDECREF(result);
    Py_XDECREF(pName);
    Py_XDECREF(methodName);

    return retVal;
}


- (BOOL)addRef:(NSString *)name
{
    /*
     Function call in Python:
     add_ref(name)
     */
    PyObject *methodName = PyString_FromString("add_ref");
    PyObject *pName = name.asPythonType;
    PyObject *result = PyObject_CallMethodObjArgs(self.pythonInstance, methodName, pName, NULL);
    BOOL retVal = NULL != result;
    Py_XDECREF(result);
    Py_XDECREF(pName);
    Py_XDECREF(methodName);

    return retVal;
}


- (BOOL)addXop:(NSString *)name usingMode:(NSUInteger)mode
{
    /*
     Function call in Python:
     add_XOP(name, mode)
     */
    PyObject *methodName = PyString_FromString("add_XOP");
    PyObject *pName = name.asPythonType;
    PyObject *pMode = PyInt_FromLong(mode);
    PyObject *result = PyObject_CallMethodObjArgs(self.pythonInstance, methodName, pName, pMode, NULL);
    BOOL retVal = NULL != result;
    Py_XDECREF(result);
    Py_XDECREF(pMode);
    Py_XDECREF(pName);
    Py_XDECREF(methodName);

    return retVal;
}


- (NSInteger)getSymbol:(NSString *)name
{
    /*
     Function call in Python:
     get_symbol(name)
     */
    PyObject *methodName = PyString_FromString("get_symbol");
    PyObject *pName = name.asPythonType;
    PyObject *symbolValueInteger = PyObject_CallMethodObjArgs(self.pythonInstance, methodName, pName, NULL);
    Py_XDECREF(pName);
    Py_XDECREF(methodName);
    if (NULL == symbolValueInteger) {
        return NSNotFound;
    }

    NSInteger retVal = PyInt_AsLong(symbolValueInteger);
    Py_DECREF(symbolValueInteger);
    return retVal;
}


- (NSInteger)getLocal:(NSString *)name position:(NSUInteger)lpos distance:(NSUInteger)distance
{
    /*
     Function call in Python:
     get_local(name, lpos, distance)
     */
    PyObject *methodName = PyString_FromString("get_local");
    PyObject *pName = name.asPythonType;
    PyObject *pLpos = PyInt_FromLong(lpos);
    PyObject *pDistance = PyInt_FromLong(distance);
    PyObject *localValueInteger = PyObject_CallMethodObjArgs(self.pythonInstance, methodName, pName, pLpos, pDistance, NULL);
    Py_XDECREF(pDistance);
    Py_XDECREF(pLpos);
    Py_XDECREF(pName);
    Py_XDECREF(methodName);
    if (NULL == localValueInteger) {
        return NSNotFound;
    }

    NSInteger retVal = PyInt_AsLong(localValueInteger);
    Py_DECREF(localValueInteger);
    return retVal;
}

@end
