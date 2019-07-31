//
//  XDTAs99Optimizer.m
//  XDTools99
//
//  Created by Henrik Wedekind on 25.07.19.
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

#import "XDTAs99Optimizer.h"

#import <Python/Python.h>

#import "XDTCallback.h"
#import "XDTMessage.h"

#import "XDTAs99Objcode.h"
#import "XDTAs99Parser.h"
#import "XDTAs99Opcodes.h"

#import "NSStringPythonAdditions.h"
#import "NSObjectPythonAdditions.h"


#define XDTClassNameOptimizer "Optimizer"


NS_ASSUME_NONNULL_BEGIN

@interface XDTAs99Optimizer ()

- (instancetype)initWithModule:(PyObject *)pModule;

@end

NS_ASSUME_NONNULL_END


@implementation XDTAs99Optimizer

+ (NSString *)pythonClassName
{
    return [NSString stringWithUTF8String:XDTClassNameOptimizer];
}


static XDTAs99Optimizer *_sharedOptimizer = nil;

+ (instancetype)optimizer
{
    if (nil != _sharedOptimizer) {
        return _sharedOptimizer;
    }

    @synchronized (self) {
        PyObject *pModule = self.xdtAs99ModuleInstance;
        if (NULL == pModule) {
            return nil;
        }

        _sharedOptimizer = [[XDTAs99Optimizer alloc] initWithModule:(PyObject *)pModule];
#if !__has_feature(objc_arc)
        [_sharedOptimizer autorelease];
#endif
    }

    return _sharedOptimizer;
}


- (instancetype)initWithModule:(PyObject *)pModule
{
    assert(NULL != pModule);

    PyObject *directivesClass = PyObject_GetAttrString(pModule, XDTClassNameOptimizer);
    if (NULL == directivesClass || !PyCallable_Check(directivesClass)) {
        NSLog(@"%s ERROR: Cannot find class \"%s\" in module %s", __FUNCTION__, XDTClassNameOptimizer, PyModule_GetName(pModule));
        if (PyErr_Occurred()) {
            PyErr_Print();
        }
        Py_XDECREF(directivesClass);
#if !__has_feature(objc_arc)
        [self release];
#endif
        return nil;
    }

    self = [super initWithPythonInstance:directivesClass];
    Py_DECREF(directivesClass);
    if (nil == self) {
        return nil;
    }

    return self;
}


- (void)dealloc
{
#if !__has_feature(objc_arc)
    [super dealloc];
#endif
}


#pragma mark - Property Wrapper


// No properties declared


#pragma mark - Method Wrapper


- (void)optimizeCode:(XDTAs99Objcode *)code usingParser:(XDTAs99Parser *)parser forMnemonic:(NSString *)mnemonic arguments:(NSArray<NSString *> *)args
{
    /* Typical context before calling the optimizer:
     opcode, fmt, parse1, parse2, timing = Opcodes.sharedOpcodes[mnemonic]
     arg1 = parse1(parser, operands[0]) if parse1 else None
     arg2 = parse2(parser, operands[1]) if parse2 else None
     */
    NSArray<id> *instructionInfo = [XDTAs99Opcodes.sharedOpcodes.instructions objectForKey:mnemonic];
    NSAssert(nil != instructionInfo, @"%s ERROR: Instruction information for mnemonic %@ not found!", __FUNCTION__, mnemonic);
    NSAssert(5 == instructionInfo.count, @"%s ERROR: Incorrect size for tuple of instruction information. Expected %u information properties, but got %lu.", __FUNCTION__, 5, instructionInfo.count);

    NSUInteger opCode = [[instructionInfo objectAtIndex:0] unsignedIntegerValue];
    NSUInteger fmt = [[instructionInfo objectAtIndex:1] unsignedIntegerValue];
    XDTCallback *parseCallback1 = [instructionInfo objectAtIndex:2];
    XDTCallback *parseCallback2 = [instructionInfo objectAtIndex:3];
    //XDTAs99Timing *timing = [instructionInfo objectAtIndex:4];    // not used here

    NSObject *argument1 = nil;
    if ([NSNull.null isNotEqualTo:parseCallback1] && 0 < args.count) {
        NSString *cbArg = [args objectAtIndex:0];
        if ([NSNull.null isNotEqualTo:cbArg] && 0 < cbArg.length) {
            argument1 = [parseCallback1 callWithArguments:parser, cbArg, nil];
        }
    }
    NSObject *argument2 = nil;
    if ([NSNull.null isNotEqualTo:parseCallback2] && 1 < args.count) {
        NSString *cbArg = [args objectAtIndex:1];
        if ([NSNull.null isNotEqualTo:cbArg] && 0 < cbArg.length) {
            argument2 = [parseCallback2 callWithArguments:parser, cbArg, nil];
        }
    }
    [self optimizeCode:code usingParser:parser forMnemonic:mnemonic opCode:opCode format:fmt argument1:argument1 argument2:argument2];
}


- (void)optimizeCode:(XDTAs99Objcode *)code usingParser:(XDTAs99Parser *)parser forMnemonic:(NSString *)mnemonic opCode:(NSUInteger)opCode format:(NSUInteger)fmt argument1:(NSObject *)arg1 argument2:(NSObject *)arg2
{
    XDTMessage *myMessages = parser.messages;

    /*
     Function call in Python:
     process(parser, code, mnemonic, opcode, fmt, arg1, arg2)
     */
    PyObject *methodName = PyString_FromString("process");
    PyObject *pMnemonic = mnemonic.asPythonType;
    PyObject *pOpCode = PyLong_FromLong(opCode);
    PyObject *pFormat = PyLong_FromLong(fmt);
    PyObject *pArg1 = (nil == arg1)? Py_None : arg1.asPythonType;
    PyObject *pArg2 = (nil == arg2)? Py_None : arg2.asPythonType;
    PyObject *result = PyObject_CallMethodObjArgs(self.pythonInstance, methodName, code.pythonInstance, parser.pythonInstance, pMnemonic, pOpCode, pFormat, pArg1, pArg2, NULL);
    if (Py_None != pArg2) {
        Py_XDECREF(pArg2);
    }
    if (Py_None != pArg1) {
        Py_XDECREF(pArg1);
    }
    Py_XDECREF(pFormat);
    Py_XDECREF(pOpCode);
    Py_XDECREF(pMnemonic);
    Py_XDECREF(methodName);
    if (NULL == result) {
        NSLog(@"%s ERROR: process(...) returns NULL!", __FUNCTION__);
        PyObject *exeption = PyErr_Occurred();
        if (NULL != exeption) {
//            if (nil != error) {
//                *error = [NSError errorWithPythonError:exeption code:-2 localizedRecoverySuggestion:nil];
//            }
            PyErr_Print();
        }
        return;
    }

    Py_DECREF(result);

    [myMessages refresh];
    XDTMessage *m = parser.messages;
    if (((nil == myMessages)? 0 : myMessages.count) < m.count) {
        [parser.messages enumerateMessagesUsingBlock:^(NSDictionary<XDTMessageTypeKey,id> *obj, BOOL *stop) {
            // TODO: extract the new messages
        }];
    }
}

@end
