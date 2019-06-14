//
//  XDTGPLObjcode.m
//  XDTools99
//
//  Created by Henrik Wedekind on 18.12.16.
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

#import "XDTGPLObjcode.h"

#import "NSArrayPythonAdditions.h"
#import "NSDataPythonAdditions.h"
#import "NSErrorPythonAdditions.h"


#define XDTClassNameObjcode "Objcode"


NS_ASSUME_NONNULL_BEGIN
@interface XDTGPLObjcode () {
    PyObject *objectcodePythonClass;
}

+ (nullable instancetype)gplObjectcodeWithPythonInstance:(void *)object;

- (nullable instancetype)initWithPythonInstance:(PyObject *)object;

@end
NS_ASSUME_NONNULL_END


@implementation XDTGPLObjcode

#pragma mark Initializers

/**
 *
 * The visibility of all allocators / initializers are effectivly package private!
 * They are only visible for the XDTGPLAssembler. Objects of this class are created by calling any of
 * the assembleSourceFile: methods from an instance of the XDTGPLAssembler class.
 *
 **/


+ (instancetype)gplObjectcodeWithPythonInstance:(void *)object
{
    XDTGPLObjcode *retVal = [[XDTGPLObjcode alloc] initWithPythonInstance:(PyObject *)object];
#if !__has_feature(objc_arc)
    [retVal autorelease];
#endif
    return retVal;
}


- (instancetype)initWithPythonInstance:(PyObject *)object
{
    self = [super init];
    if (nil == self) {
        return nil;
    }

    objectcodePythonClass = object;
    Py_INCREF(objectcodePythonClass);

    return self;
}


- (void)dealloc
{
    Py_CLEAR(objectcodePythonClass);
#if !__has_feature(objc_arc)
    [super dealloc];
#endif
}


#pragma mark - Property Wrapper


- (NSData *)generateDump:(NSError **)error
{
    // TODO: Implement function
    NSLog(@"%s ERROR: genDump() not implemented in wrapper class!", __FUNCTION__);
    //PyObject *exeption = PyErr_Occurred();
    //if (NULL != exeption) {
        if (nil != error) {
            NSDictionary *errorDict = @{
                          NSLocalizedDescriptionKey: @"Unimplemented method",
                          NSLocalizedRecoverySuggestionErrorKey: @"generateDump: is not implemented for now."
                          };
            *error = [NSError errorWithDomain:XDTErrorDomain code:XDTErrorCodeToolException userInfo:errorDict];
            //*error = [NSError errorWithPythonError:exeption RecoverySuggestion:nil];
        }
    //    PyErr_Print();
    //}
    return nil;
}


- (NSArray<NSArray<id> *> *)generateByteCode:(NSError **)error
{
    /*
     Function call in Python:
     groms = self.genByteCode()
     */
    PyObject *methodName = PyString_FromString("genByteCode");
    PyObject *gromList = PyObject_CallMethodObjArgs(objectcodePythonClass, methodName, NULL);
    Py_XDECREF(methodName);
    if (NULL == gromList) {
        NSLog(@"%s ERROR: genByteCode() returns NULL!", __FUNCTION__);
        PyObject *exeption = PyErr_Occurred();
        if (NULL != exeption) {
            if (nil != error) {
                *error = [NSError errorWithPythonError:exeption RecoverySuggestion:nil];
            }
            PyErr_Print();
        }
        return nil;
    }

    NSArray<NSArray<id> *> *retVal = [NSArray arrayWithPyListOfTuple:gromList];
    Py_DECREF(gromList);

    return retVal;
}


- (NSData *)generateImageWithName:(NSString *)cartridgeName error:(NSError **)error
{
    if (nil == cartridgeName || [cartridgeName length] == 0) {
        return nil;
    }
    /*
     Function call in Python:
     image = self.genImage(name)
     */
    PyObject *methodName = PyString_FromString("genImage");
    PyObject *pCartName = PyString_FromString([cartridgeName UTF8String]);
    PyObject *cartImage = PyObject_CallMethodObjArgs(objectcodePythonClass, methodName, pCartName, NULL);
    Py_XDECREF(pCartName);
    Py_XDECREF(methodName);
    if (NULL == cartImage) {
        NSLog(@"%s ERROR: genImage(\"%@\") returns NULL!", __FUNCTION__, cartridgeName);
        PyObject *exeption = PyErr_Occurred();
        if (NULL != exeption) {
            if (nil != error) {
                *error = [NSError errorWithPythonError:exeption RecoverySuggestion:nil];
            }
            PyErr_Print();
        }
        return nil;
    }

    NSData *retVal = [NSData dataWithPythonString:cartImage];

    Py_DECREF(cartImage);

    return retVal;
}


/*
 This method returns a NSDictionary with the content for three files, which should be written into a Zip file:
 - cartridgeName + ".bin": NSData
 - layout.xml: NSString
 - meta-inf.xml: NSString
 */
- (NSDictionary<NSString *, NSData *> *)generateMESSCartridgeWithName:(NSString *)cartridgeName error:(NSError **)error
{
    if (nil == cartridgeName || [cartridgeName length] == 0) {
        return nil;
    }
    /*
     Function call in Python:
     data, layout, metainf = code.genCart(name)
     */
    PyObject *methodName = PyString_FromString("genCart");
    PyObject *pCartName = PyString_FromString([cartridgeName UTF8String]);
    PyObject *cartTuple = PyObject_CallMethodObjArgs(objectcodePythonClass, methodName, pCartName, NULL);
    Py_XDECREF(pCartName);
    Py_XDECREF(methodName);
    if (NULL == cartTuple) {
        NSLog(@"%s ERROR: genCart(\"%@\") returns NULL!", __FUNCTION__, cartridgeName);
        PyObject *exeption = PyErr_Occurred();
        if (NULL != exeption) {
            if (nil != error) {
                *error = [NSError errorWithPythonError:exeption RecoverySuggestion:nil];
            }
            PyErr_Print();
        }
        return nil;
    }

    Py_ssize_t tupleCount = PyTuple_Size(cartTuple);
    if (3 != tupleCount) {
        Py_DECREF(cartTuple);
        return nil;
    }
    PyObject *cartData = PyTuple_GetItem(cartTuple, 0);
    PyObject *cartLayout = PyTuple_GetItem(cartTuple, 1);
    PyObject *cartMetaInf = PyTuple_GetItem(cartTuple, 2);

    NSString *cartridgeFileName = [cartridgeName stringByAppendingPathExtension:@"bin"];
    NSDictionary<NSString *, NSData *> *retVal =@{
                                                  cartridgeFileName: [NSData dataWithPythonString:cartData],
                                                  @"layout.xml": [NSData dataWithPythonString:cartLayout],
                                                  @"meta-inf.xml": [NSData dataWithPythonString:cartMetaInf]
                                                  };

    Py_DECREF(cartTuple);

    return retVal;
}


- (NSData *)generateListing:(BOOL)outputSymbols error:(NSError **)error
{
    /*
     Function call in Python:
     genList(gensymbols)
     */
    PyObject *methodName = PyString_FromString("genList");
    PyObject *pOutputSymbols = PyBool_FromLong(outputSymbols);
    PyObject *listingString = PyObject_CallMethodObjArgs(objectcodePythonClass, methodName, pOutputSymbols, NULL);
    Py_XDECREF(pOutputSymbols);
    Py_XDECREF(methodName);
    if (NULL == listingString) {
        NSLog(@"%s ERROR: genList(\"%@\") returns NULL!", __FUNCTION__, outputSymbols? @"true" : @"false");
        PyObject *exeption = PyErr_Occurred();
        if (NULL != exeption) {
            if (nil != error) {
                *error = [NSError errorWithPythonError:exeption RecoverySuggestion:nil];
            }
            PyErr_Print();
        }
        return nil;
    }

    NSData *retVal = [NSData dataWithPythonString:listingString];
    Py_DECREF(listingString);

    return retVal;
}


- (NSData *)generateSymbols:(BOOL)useEqu error:(NSError **)error
{
    /*
     Function call in Python:
     genSymbols(useEqu)
     */
    PyObject *methodName = PyString_FromString("genSymbols");
    PyObject *pUseEqu = PyBool_FromLong(useEqu);
    PyObject *symbolsString = PyObject_CallMethodObjArgs(objectcodePythonClass, methodName, pUseEqu, NULL);
    Py_XDECREF(pUseEqu);
    Py_XDECREF(methodName);
    if (NULL == symbolsString) {
        NSLog(@"%s ERROR: genSymbols(\"%@\") returns NULL!", __FUNCTION__, useEqu? @"true" : @"false");
        PyObject *exeption = PyErr_Occurred();
        if (NULL != exeption) {
            if (nil != error) {
                *error = [NSError errorWithPythonError:exeption RecoverySuggestion:nil];
            }
            PyErr_Print();
        }
        return nil;
    }

    NSData *retVal = [NSData dataWithPythonString:symbolsString];
    Py_DECREF(symbolsString);

    return retVal;
}

@end
