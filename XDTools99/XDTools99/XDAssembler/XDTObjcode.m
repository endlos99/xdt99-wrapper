//
//  XDTObjcode.m
//  SimpleXDT99
//
//  Created by Henrik Wedekind on 03.12.16.
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

#import "XDTObjcode.h"

#import "NSArrayPythonAdditions.h"
#import "NSDataPythonAdditions.h"
#import "NSErrorPythonAdditions.h"
#import "XDTSymbols.h"


#define XDTClassNameObjcode "Objcode"


NS_ASSUME_NONNULL_BEGIN
@interface XDTObjcode () {
    PyObject *objectcodePythonClass;
}

+ (nullable instancetype)objectcodeWithPythonInstance:(void *)object;

- (nullable instancetype)initWithPythonInstance:(PyObject *)object;

@end
NS_ASSUME_NONNULL_END


@implementation XDTObjcode

#pragma mark Initializers

/**
 *
 * The visibility of all allocators / initializers are effectivly package private!
 * They are only visible for the XDTAssembler. Objects of this class are created by calling any of
 * the assembleSourceFile: methods from an instance of the XDTAssembler class.
 *
 **/


+ (nullable instancetype)objectcodeWithPythonInstance:(void *)object
{
    XDTObjcode *retVal = [[XDTObjcode alloc] initWithPythonInstance:(PyObject *)object];
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


- (XDTSymbols *)symbols
{
    PyObject *symbolObject = PyObject_GetAttrString(objectcodePythonClass, "symbols");
    XDTSymbols *codeSymbols = [XDTSymbols symbolsWithPythonInstance:symbolObject];
    Py_XDECREF(symbolObject);

    return codeSymbols;
}


- (void)setSymbols:(XDTSymbols *)symbols
{
    // TODO: Implement function
}


#pragma mark - Generator Method Wrapper


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


- (NSData *)generateObjCode:(BOOL)shouldCompress error:(NSError **)error
{
    /*
     Function call in Python:
     genObjCode(compressed=False)
     */
    PyObject *methodName = PyString_FromString("genObjCode");
    PyObject *pCompressed = PyBool_FromLong(shouldCompress);
    PyObject *binaryString = PyObject_CallMethodObjArgs(objectcodePythonClass, methodName, pCompressed, NULL);
    Py_XDECREF(pCompressed);
    Py_XDECREF(methodName);
    if (NULL == binaryString) {
        NSLog(@"%s ERROR: genObjCode(%@) returns NULL!", __FUNCTION__, shouldCompress? @"true" : @"false");
        PyObject *exeption = PyErr_Occurred();
        if (NULL != exeption) {
            if (nil != error) {
                *error = [NSError errorWithPythonError:exeption RecoverySuggestion:nil];
            }
            PyErr_Print();
        }
        return nil;
    }

    NSData *retVal = [NSData dataWithPythonString:binaryString];
    Py_DECREF(binaryString);

    return retVal;
}


- (NSArray<NSArray<id> *> *)generateRawBinaryAt:(NSUInteger)baseAddr error:(NSError **)error
{
    /*
     Function call in Python:
     (addr, bank, blob) = genBinaries(baseAddr, saves=None)
     */
    PyObject *methodName = PyString_FromString("genBinaries");
    PyObject *pBaseAddr = PyInt_FromLong(baseAddr);
    PyObject *binaryList = PyObject_CallMethodObjArgs(objectcodePythonClass, methodName, pBaseAddr, NULL);
    Py_XDECREF(pBaseAddr);
    Py_XDECREF(methodName);
    if (NULL == binaryList) {
        NSLog(@"%s ERROR: genBinaries(0x%lxd) returns NULL!", __FUNCTION__, baseAddr);
        PyObject *exeption = PyErr_Occurred();
        if (NULL != exeption) {
            if (nil != error) {
                *error = [NSError errorWithPythonError:exeption RecoverySuggestion:nil];
            }
            PyErr_Print();
        }
        return nil;
    }

    NSArray<NSArray<id> *> *retVal = [NSArray arrayWithPyListOfTuple:binaryList];
    Py_DECREF(binaryList);

    return retVal;
}


- (NSArray<NSArray<id> *> *)generateRawBinaryAt:(NSUInteger)baseAddr withRanges:(NSArray<NSValue *> *)ranges error:(NSError **)error
{
    /*
     Function call in Python:
     (addr, bank, blob) = genBinaries(baseAddr, saves)
     */
    PyObject *methodName = PyString_FromString("genBinaries");
    PyObject *pBaseAddr = PyInt_FromLong(baseAddr);
    PyObject *pSaves = NULL;    // TODO: PyInt_FromLong(saves);
    PyObject *binaryList = PyObject_CallMethodObjArgs(objectcodePythonClass, methodName, pBaseAddr, pSaves, NULL);
    Py_XDECREF(pSaves);
    Py_XDECREF(pBaseAddr);
    Py_XDECREF(methodName);
    if (NULL == binaryList) {
        NSLog(@"%s ERROR: genBinaries(0x%lxd) returns NULL!", __FUNCTION__, baseAddr);
        PyObject *exeption = PyErr_Occurred();
        if (NULL != exeption) {
            if (nil != error) {
                *error = [NSError errorWithPythonError:exeption RecoverySuggestion:nil];
            }
            PyErr_Print();
        }
        return nil;
    }

    NSArray<NSArray<id> *> *retVal = [NSArray arrayWithPyListOfTuple:binaryList];
    Py_DECREF(binaryList);

    return retVal;
}


- (NSArray<NSData *> *)generateImageAt:(NSUInteger)baseAddr error:(NSError **)error
{
    return [self generateImageAt:baseAddr withChunkSize:0x2000 error:error];
}


- (NSArray<NSData *> *)generateImageAt:(NSUInteger)baseAddr withChunkSize:(NSUInteger)chunkSize error:(NSError **)error
{
    /*
     Function call in Python:
     genImage(baseAddr, chunkSize=0x2000)
     */
    PyObject *methodName = PyString_FromString("genImage");
    PyObject *pBaseAddr = PyInt_FromLong(baseAddr);
    PyObject *pChunkSize = PyInt_FromLong(chunkSize);
    PyObject *imageList = PyObject_CallMethodObjArgs(objectcodePythonClass, methodName, pBaseAddr, pChunkSize, NULL);
    Py_XDECREF(pChunkSize);
    Py_XDECREF(pBaseAddr);
    Py_XDECREF(methodName);
    if (NULL == imageList) {
        NSLog(@"%s ERROR: genImage(0x%lxd, 0x%lxd) returns NULL!", __FUNCTION__, baseAddr, chunkSize);
        PyObject *exeption = PyErr_Occurred();
        if (NULL != exeption) {
            if (nil != error) {
                *error = [NSError errorWithPythonError:exeption RecoverySuggestion:nil];
            }
            PyErr_Print();
        }
        return nil;
    }

    NSArray<NSData *> *retVal = [NSArray arrayWithPyListOfString:imageList];
    Py_DECREF(imageList);

    return retVal;
}


- (NSData *)generateJumpstart:(NSError **)error
{
    /*
     Function call in Python:
     genJumpstart()
     */
    PyObject *methodName = PyString_FromString("genJumpstart");
    PyObject *diskImageString = PyObject_CallMethodObjArgs(objectcodePythonClass, methodName, NULL);
    Py_XDECREF(methodName);
    if (NULL == diskImageString) {
        NSLog(@"%s ERROR: genJumpstart() returns NULL!", __FUNCTION__);
        PyObject *exeption = PyErr_Occurred();
        if (NULL != exeption) {
            if (nil != error) {
                *error = [NSError errorWithPythonError:exeption RecoverySuggestion:nil];
            }
            PyErr_Print();
        }
        return nil;
    }

    NSData *retVal = [NSData dataWithPythonString:diskImageString];
    Py_XDECREF(diskImageString);

    return retVal;
}


- (NSData *)generateBasicLoader:(NSError **)error
{
    /*
     Function call in Python:
     genXbLoader()
     */
    PyObject *methodName = PyString_FromString("genXbLoader");
    PyObject *basicString = PyObject_CallMethodObjArgs(objectcodePythonClass, methodName, NULL);
    Py_XDECREF(methodName);
    if (NULL == basicString) {
        NSLog(@"%s ERROR: genXbLoader() returns NULL!", __FUNCTION__);
        PyObject *exeption = PyErr_Occurred();
        if (NULL != exeption) {
            if (nil != error) {
                *error = [NSError errorWithPythonError:exeption RecoverySuggestion:nil];
            }
            PyErr_Print();
        }
        return nil;
    }

    NSData *retVal = [NSData dataWithPythonString:basicString];
    Py_DECREF(basicString);

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
     In the Python class all methods which generates output calling self.prepare() before they do their actual work,
     but the only generator which does not call prepare is the list generator. A bug?
     So, for here just call prepare by hand.
     
     Function call in Python:
     prepare()
     */
    PyObject *methodName = PyString_FromString("prepare");
    PyObject *pNonValue = PyObject_CallMethodObjArgs(objectcodePythonClass, methodName, NULL);
    Py_XDECREF(methodName);
    if (NULL == pNonValue) {
        return nil;
    }

    /*
     Function call in Python:
     genList(gensymbols)
     */
    methodName = PyString_FromString("genList");
    PyObject *pOutputSymbols = PyBool_FromLong(outputSymbols);
    PyObject *listingString = PyObject_CallMethodObjArgs(objectcodePythonClass, methodName, pOutputSymbols, NULL);
    Py_XDECREF(pOutputSymbols);
    Py_XDECREF(methodName);
    if (NULL == listingString) {
        NSLog(@"%s ERROR: genList(%@) returns NULL!", __FUNCTION__, outputSymbols? @"true" : @"false");
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
        NSLog(@"%s ERROR: genSymbols(%@) returns NULL!", __FUNCTION__, useEqu? @"true" : @"false");
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
