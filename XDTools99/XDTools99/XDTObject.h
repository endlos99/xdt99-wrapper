//
//  XDTObject.h
//  XDTools99
//
//  Created by Henrik Wedekind on 05.12.16.
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


#define XDTErrorDomain @"XDTErrorDomain"

typedef NS_ENUM(NSInteger, XDTErrorCode) {
    XDTErrorCodeToolLoggedError = 0,
    XDTErrorCodeToolException = 1,
    XDTErrorCodePythonError = 2,
    XDTErrorCodePythonException = 3,
};


NS_ASSUME_NONNULL_BEGIN

typedef const char * XDTModuleName NS_EXTENSIBLE_STRING_ENUM;

FOUNDATION_EXPORT XDTModuleName const XDTAs99ModuleName;    // XDTAs99ModuleName "xas99"
#define XDTAs99RequiredVersion "2.0.2"

FOUNDATION_EXPORT XDTModuleName const XDTGa99ModuleName;    // XDTGa99ModuleName "xga99"
#define XDTGa99RequiredVersion "2.0.2"

FOUNDATION_EXPORT XDTModuleName const XDTBas99ModuleName;   // XDTBas99ModuleName "xbas99"
#define XDTBas99RequiredVersion "2.0.1"


@class XDTObject;


@protocol XDTConsumerProtocol <NSObject>

@optional
- (void)consumeBlockComment:(NSString *)comment inRange:(NSRange)commentRange;
- (void)consumeLineComment:(NSString *)comment inRange:(NSRange)commentRange;
- (void)consumePreProcDirective:(NSString *)directive inRange:(NSRange)directiveRange;
- (void)consumeDirective:(NSString *)directive inRange:(NSRange)directiveRange;
- (void)consumeNumericLiteral:(NSString *)literal inRange:(NSRange)literalRange;
- (void)consumeTextLiteral:(NSString *)text inRange:(NSRange)textRange;
- (void)consumeFilename:(NSString *)link inRange:(NSRange)linkRange;
- (void)consumeMacro:(NSString *)macro inRange:(NSRange)macroRange;
- (void)consumeLabelDefinition:(NSString *)label inRange:(NSRange)labelRange;
- (void)consumeLabelReference:(NSString *)label inRange:(NSRange)labelRange;

@end


@protocol XDTParserProtocol <NSObject>

/**
 Set the source code where the parser works on.
 */
- (void)setSource:(NSString *)source;

/**
 Subclasses needts to overwrite this method!
 This Method will be called from \p openNestedFiles: before it loads and opens new documents.

 @return    A non nullable set of URL of files this document needs to include.

 Default implementation retruns an empty list.
 */
- (NSOrderedSet<NSURL *> *)includedFiles:(NSError **)error;

/**
 Splits a line of Assembler source code into its components like label, mnemonic, operands and comment and returns thier values within an array.

 @param line    A line of Source code to be split into tits components. Can not be nil.
 @param error   Return by reference an error object. Pass nil if the value is not needed.

 @return An array which contains four elements with the separated components of the given line of source code.\n
 When the line is not a comment line the array is filled with following values:\n
 Element at index 0 contains a label as a NSString.\n
 Element at index 1 contains the mnemonic as a NSString.\n
 Element at index 2 contains the operands as a NSArray.\n
 Element at index 3 contains the comment as a NSString.\n
 If the given line is a comment line, the array is empty. On an error \p nil will be returned and \p error is set.

 This method corresponds to that in the Python class named Parser. It splits a line of Assembler source code into its components like label, mnemonic, operands and a comment. All line components will returned uppercased. The original Python function also returns in its fifths return value a flag that indicates if that line contains a valid statement. But this flag is kipped here, becaus it is redundand. If the line doesn't is one with a statement, i.e. it is a line comment, the returned array will have no items.
 */
@required
- (NSArray<id> *_Nullable)splitLine:(NSString *)line error:(NSError **_Nullable)error;

/**
 Same as \p splitLine:error:, but whithout returning the error by reference.
 Check message property for any arrors.

 @param line    Line of source code to split in its components.
 @return An array which contains four elements with the separated components of the given line of source code.

 For more information see \p splitLine:error:
 */
@required
- (NSArray<id> *_Nullable)splitLine:(NSString *)line;

/**
 Searches in the parsers internal lookup table for the given placeholder \p key and returns the literal.

 @param key The name of the key for the corresponding literal
 @return The literal to the given key. \p Nil if key is an invalid placeholder or literal does not exists.

 */
- (nullable NSString *)literalForPlaceholder:(NSString *)key;

/**
 */
- (nullable NSString *)filename:(NSString *)key error:(NSError **_Nullable)error;

/**
 Parses the given operand of a \p TEXT directive and returns the character as a stirng.
 @param op      The operant of a \p TEXT directive, it can be a string literal or a byte string.
 @param error   Return by reference the Python internal error.
 @return A string of character of the given operand, \p nil if the given operator is syntactical incorrect.
 */
- (nullable NSString *)text:(NSString *)op error:(NSError **_Nullable)error;

@end


@protocol XDTLineScannerProtocol <NSObject>

/**
 Creates and initialize a new instance of a \p XDTLineScanner.

 @param codeLine    The line of assembler source to scan for syntactical components.
 @param parser      An instance of a \p XDTGPLParser or \p XDTParser class.

 */
@required
+ (nullable instancetype)scannerWithParser:(XDTObject<XDTParserProtocol> *)parser symbols:(NSArray<NSString *> *)symbolList;

/**
 Processes the given \p line using \p delegate to consume the processed results.
 @param line        Line of source code to processed.
 @param delegate    The consumer which gets the processed results for further processing.
 */
- (BOOL)processLine:(NSString *)line consumer:(id<XDTConsumerProtocol>)delegate;

@end


@interface XDTObject : NSObject

@property (class, readonly) PyObject *xdtAs99ModuleInstance;
@property (class, readonly) PyObject *xdtGa99ModuleInstance;
@property (class, readonly) PyObject *xdtBas99ModuleInstance;

+ (NSString *)pythonClassName;

+ (BOOL)checkInstanceForPythonObject:(PyObject *)pythonObject;

+ (void)reinitializeWithXDTModulePath:(NSString *)modulePath;

@end


@interface XDTObject (Private)

@property (readonly) PyObject *pythonInstance;

- (instancetype)initWithPythonInstance:(PyObject *_Nullable)object;

@end

NS_ASSUME_NONNULL_END

