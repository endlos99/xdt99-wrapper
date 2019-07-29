//
//  XDTAs99Objcode.m
//  XDTools99
//
//  Created by Henrik Wedekind on 03.12.16.
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

#import "XDTAs99Objcode.h"

#import "NSStringPythonAdditions.h"
#import "NSArrayPythonAdditions.h"
#import "NSDataPythonAdditions.h"
#import "NSErrorPythonAdditions.h"
#import "XDTAs99Symbols.h"


#define XDTClassNameObjcode "Objcode"


NS_ASSUME_NONNULL_BEGIN

@interface XDTAs99Objcode () {
    PyObject *objectcodePythonClass;
}

+ (nullable instancetype)objectcodeWithPythonInstance:(void *)object;

- (nullable instancetype)initWithPythonInstance:(PyObject *)object;

- (nullable PyObject *)generateBinariesAt:(NSUInteger)baseAddr error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END


@implementation XDTAs99Objcode

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
    XDTAs99Objcode *retVal = [[XDTAs99Objcode alloc] initWithPythonInstance:(PyObject *)object];
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


- (XDTAs99Symbols *)symbols
{
    PyObject *symbolObject = PyObject_GetAttrString(objectcodePythonClass, "symbols");
    XDTAs99Symbols *codeSymbols = [XDTAs99Symbols symbolsWithPythonInstance:symbolObject];
    Py_XDECREF(symbolObject);

    return codeSymbols;
}


#pragma mark - Generator Method Wrapper


- (NSData *)generateDump:(NSError **)error
{
    // TODO: Implement function
    NSLog(@"%s ERROR: genDump() not implemented in wrapper class!", __FUNCTION__);
    //PyObject *exeption = PyErr_Occurred();
    //if (NULL != exeption) {
    if (nil != error) {
        NSBundle *myBundle = [NSBundle bundleForClass:[self class]];
        NSDictionary *errorDict = @{
                                    NSLocalizedDescriptionKey: NSLocalizedStringFromTableInBundle(@"Unimplemented method", nil, myBundle, @"Description for an error object, discribing that there is a missing implementation fo a function."),
                                    NSLocalizedRecoverySuggestionErrorKey: [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"%@: is not implemented for now. Please implement it.", nil, myBundle, @"Recovery suggestion for an error object, which explains which given function needs to be implemented."), @"generateDump"]
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
     generate_object_code(compressed=False)
     */
    PyObject *methodName = PyString_FromString("generate_object_code");
    PyObject *pCompressed = PyBool_FromLong(shouldCompress);
    PyObject *binaryString = PyObject_CallMethodObjArgs(objectcodePythonClass, methodName, pCompressed, NULL);
    Py_XDECREF(pCompressed);
    Py_XDECREF(methodName);
    if (NULL == binaryString) {
        NSLog(@"%s ERROR: generate_object_code(%s) returns NULL!", __FUNCTION__, shouldCompress? "true" : "false");
        PyObject *exeption = PyErr_Occurred();
        if (NULL != exeption) {
            if (nil != error) {
                *error = [NSError errorWithPythonError:exeption localizedRecoverySuggestion:nil];
            }
            PyErr_Print();
        }
        return nil;
    }

    NSData *retVal = [NSData dataWithPythonString:binaryString];
    Py_DECREF(binaryString);

    return retVal;
}


- (PyObject *)generateBinariesAt:(NSUInteger)baseAddr error:(NSError **)error
{
    /*
     Function call in Python:
     (addr, bank, blob) = generate_binaries(baseAddr, saves=None)
     */
    PyObject *methodName = PyString_FromString("generate_binaries");
    PyObject *pBaseAddr = PyInt_FromLong(baseAddr);
    PyObject *binaryList = PyObject_CallMethodObjArgs(objectcodePythonClass, methodName, pBaseAddr, NULL);
    Py_XDECREF(pBaseAddr);
    Py_XDECREF(methodName);
    if (NULL == binaryList) {
        NSLog(@"%s ERROR: generate_binaries(0x%lxd) returns NULL!", __FUNCTION__, baseAddr);
        PyObject *exeption = PyErr_Occurred();
        if (NULL != exeption) {
            if (nil != error) {
                *error = [NSError errorWithPythonError:exeption localizedRecoverySuggestion:nil];
            }
            PyErr_Print();
        }
    }

    return binaryList;
}


- (NSArray<NSArray<id> *> *)generateRawBinaryAt:(NSUInteger)baseAddr error:(NSError **)error
{
    NSArray<NSArray<id> *> *retVal = nil;
    PyObject *binaryList = [self generateBinariesAt:baseAddr error:error];
    if (NULL != binaryList) {
        retVal = [NSArray arrayWithPyListOfTuple:binaryList];
        Py_DECREF(binaryList);
    }

    return retVal;
}


- (NSArray<NSArray<id> *> *)generateRawBinaryAt:(NSUInteger)baseAddr withRanges:(NSArray<NSValue *> *)ranges error:(NSError **)error
{
    /*
     Function call in Python:
     (addr, bank, blob) = generate_binaries(baseAddr, saves)
     */
    PyObject *methodName = PyString_FromString("generate_binaries");
    PyObject *pBaseAddr = PyInt_FromLong(baseAddr);
    PyObject *pSaves = NULL;    // TODO: PyInt_FromLong(saves);
    PyObject *binaryList = PyObject_CallMethodObjArgs(objectcodePythonClass, methodName, pBaseAddr, pSaves, NULL);
    Py_XDECREF(pSaves);
    Py_XDECREF(pBaseAddr);
    Py_XDECREF(methodName);
    if (NULL == binaryList) {
        NSLog(@"%s ERROR: generate_binaries(0x%lxd) returns NULL!", __FUNCTION__, baseAddr);
        PyObject *exeption = PyErr_Occurred();
        if (NULL != exeption) {
            if (nil != error) {
                *error = [NSError errorWithPythonError:exeption localizedRecoverySuggestion:nil];
            }
            PyErr_Print();
        }
        return nil;
    }

    NSArray<NSArray<id> *> *retVal = [NSArray arrayWithPyListOfTuple:binaryList];
    Py_DECREF(binaryList);

    return retVal;
}


- (NSString *)generateTextAt:(NSUInteger)baseAddr withMode:(XDTGenerateTextMode)mode error:(NSError **)error
{
    PyObject *binaryList = [self generateBinariesAt:baseAddr error:error];
    if (NULL == binaryList || (nil != error && nil != *error)) {
        Py_XDECREF(binaryList);
        return nil;
    }

    const Py_ssize_t dataCount = PyTuple_Size(binaryList);
    if (2 > dataCount) {
        Py_DECREF(binaryList);
        return nil;
    }
    PyObject *binaryData = PyTuple_GetItem(binaryList, 0);   // second item (bank_count) is not used
    if (NULL == binaryData) {
        Py_DECREF(binaryList);
        return nil;
    }

    char *textConfig = "";
    switch (mode) {
        case XDTGenerateTextModeOutputAssembler + XDTGenerateTextModeOptionWord + XDTGenerateTextModeOptionReverse:
            textConfig = "a4r";
            break;
        case XDTGenerateTextModeOutputAssembler + XDTGenerateTextModeOptionWord:
            textConfig = "a4";
            break;
        case XDTGenerateTextModeOutputAssembler + XDTGenerateTextModeOptionReverse:
            textConfig = "a2r";
            break;
        case XDTGenerateTextModeOutputAssembler:
            textConfig = "a2";
            break;

        case XDTGenerateTextModeOutputBasic + XDTGenerateTextModeOptionWord + XDTGenerateTextModeOptionReverse:
            textConfig = "b4r";
            break;
        case XDTGenerateTextModeOutputBasic + XDTGenerateTextModeOptionWord:
            textConfig = "b4";
            break;
        case XDTGenerateTextModeOutputBasic + XDTGenerateTextModeOptionReverse:
            textConfig = "b2r";
            break;
        case XDTGenerateTextModeOutputBasic:
            textConfig = "b2";
            break;

        case XDTGenerateTextModeOutputC + XDTGenerateTextModeOptionWord + XDTGenerateTextModeOptionReverse:
            textConfig = "c4r";
            break;
        case XDTGenerateTextModeOutputC + XDTGenerateTextModeOptionWord:
            textConfig = "c4";
            break;
        case XDTGenerateTextModeOutputC + XDTGenerateTextModeOptionReverse:
            textConfig = "c2r";
            break;
        case XDTGenerateTextModeOutputC:
            textConfig = "c2";
            break;

        default:
            break;
    }

    /*
     Function call in Python:
     text = generate_text(data, mode)
     */
    PyObject *methodName = PyString_FromString("generate_text");
    PyObject *pMode = PyString_FromString(textConfig);
    PyObject *dataText = PyObject_CallMethodObjArgs(objectcodePythonClass, methodName, binaryData, pMode, NULL);
    Py_DECREF(binaryData);
    Py_XDECREF(pMode);
    Py_XDECREF(methodName);

    if (NULL == dataText) {
        NSLog(@"%s ERROR: generate_text(%p, \"%s\") returns NULL!", __FUNCTION__, binaryList, textConfig);
        PyObject *exeption = PyErr_Occurred();
        if (NULL != exeption) {
            if (nil != error) {
                *error = [NSError errorWithPythonError:exeption localizedRecoverySuggestion:nil];
            }
            PyErr_Print();
        }
        return nil;
    }

    NSString *retVal = [NSString stringWithPythonString:dataText encoding:NSUTF8StringEncoding];
    Py_DECREF(dataText);
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
     generate_image(baseAddr, chunkSize=0x2000)
     */
    PyObject *methodName = PyString_FromString("generate_image");
    PyObject *pBaseAddr = PyInt_FromLong(baseAddr);
    PyObject *pChunkSize = PyInt_FromLong(chunkSize);
    PyObject *imageList = PyObject_CallMethodObjArgs(objectcodePythonClass, methodName, pBaseAddr, pChunkSize, NULL);
    Py_XDECREF(pChunkSize);
    Py_XDECREF(pBaseAddr);
    Py_XDECREF(methodName);
    if (NULL == imageList) {
        NSLog(@"%s ERROR: generate_image(0x%lxd, 0x%lxd) returns NULL!", __FUNCTION__, baseAddr, chunkSize);
        PyObject *exeption = PyErr_Occurred();
        if (NULL != exeption) {
            if (nil != error) {
                *error = [NSError errorWithPythonError:exeption localizedRecoverySuggestion:nil];
            }
            PyErr_Print();
        }
        return nil;
    }

    NSArray<NSData *> *retVal = [NSArray arrayWithPyListOfData:imageList];
    Py_DECREF(imageList);

    return retVal;
}


- (NSData *)generateBasicLoader:(NSError **)error
{
    /*
     Function call in Python:
     generate_XB_loader()
     */
    PyObject *methodName = PyString_FromString("generate_XB_loader");
    PyObject *basicString = PyObject_CallMethodObjArgs(objectcodePythonClass, methodName, NULL);
    Py_XDECREF(methodName);
    if (NULL == basicString) {
        NSLog(@"%s ERROR: generate_XB_loader() returns NULL!", __FUNCTION__);
        PyObject *exeption = PyErr_Occurred();
        if (NULL != exeption) {
            if (nil != error) {
                *error = [NSError errorWithPythonError:exeption localizedRecoverySuggestion:nil];
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
     data, layout, metainf = code.generate_cartridge(name)
     */
    PyObject *methodName = PyString_FromString("generate_cartridge");
    PyObject *pCartName = PyString_FromString([cartridgeName UTF8String]);
    PyObject *cartTuple = PyObject_CallMethodObjArgs(objectcodePythonClass, methodName, pCartName, NULL);
    Py_XDECREF(pCartName);
    Py_XDECREF(methodName);
    if (NULL == cartTuple) {
        NSLog(@"%s ERROR: generate_cartridge(\"%@\") returns NULL!", __FUNCTION__, cartridgeName);
        PyObject *exeption = PyErr_Occurred();
        if (NULL != exeption) {
            if (nil != error) {
                *error = [NSError errorWithPythonError:exeption localizedRecoverySuggestion:nil];
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
     generate_list(gensymbols)
     */
    methodName = PyString_FromString("generate_list");
    PyObject *pOutputSymbols = PyBool_FromLong(outputSymbols);
    PyObject *listingString = PyObject_CallMethodObjArgs(objectcodePythonClass, methodName, pOutputSymbols, NULL);
    Py_XDECREF(pOutputSymbols);
    Py_XDECREF(methodName);
    if (NULL == listingString) {
        NSLog(@"%s ERROR: generate_list(%s) returns NULL!", __FUNCTION__, outputSymbols? "true" : "false");
        PyObject *exeption = PyErr_Occurred();
        if (NULL != exeption) {
            if (nil != error) {
                *error = [NSError errorWithPythonError:exeption localizedRecoverySuggestion:nil];
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
     generate_symbols(useEqu)
     */
    PyObject *methodName = PyString_FromString("generate_symbols");
    PyObject *pUseEqu = PyBool_FromLong(useEqu);
    PyObject *symbolsString = PyObject_CallMethodObjArgs(objectcodePythonClass, methodName, pUseEqu, NULL);
    Py_XDECREF(pUseEqu);
    Py_XDECREF(methodName);
    if (NULL == symbolsString) {
        NSLog(@"%s ERROR: generate_symbols(%s) returns NULL!", __FUNCTION__, useEqu? "true" : "false");
        PyObject *exeption = PyErr_Occurred();
        if (NULL != exeption) {
            if (nil != error) {
                *error = [NSError errorWithPythonError:exeption localizedRecoverySuggestion:nil];
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
