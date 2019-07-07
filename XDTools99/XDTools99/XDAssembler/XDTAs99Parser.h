//
//  XDTAs99Parser.h
//  XDTools99
//
//  Created by Henrik Wedekind on 30.06.19.
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

#import <XDTObject.h>


@class XDTAs99Symbols, XDTAs99Preprocessor, XDTMessage;


NS_ASSUME_NONNULL_BEGIN

@interface XDTAs99Parser : XDTObject <XDTParserProtocol>

@property (assign) BOOL beStrict;
@property (assign) BOOL useRegisterSymbols;
@property (assign) BOOL outputWarnings;

@property (copy, nullable) NSString *path;
@property (readonly, copy, nullable) XDTAs99Symbols *symbols;
@property (copy, nullable) XDTMessage *messages;
@property (readonly, copy, nullable) XDTAs99Preprocessor *preprocessor;

/**
 Creates an autoreleased instance of XDTAs99Parser with default options
 */
+ (nullable instancetype)parserForPath:(NSString *)path usingRegisterSymbol:(BOOL)useRegisterSymbol strictness:(BOOL)beStrict outputWarnings:(BOOL)outputWarnings;

- (BOOL)openSourceFile:(nullable NSString *)fileName macroBuffer:(nullable NSString *)macroName ops:(nullable NSArray<id> *)ops error:( NSError * _Nullable *)error;

- (BOOL)resume:(NSError **)error;

- (BOOL)stop:(NSError **)error;

/**
 Set the source code where the parser works on.
 */
- (void)setSource:(NSString *)source;

@end


@interface XDTAs99Parser (XDTAs99ParserExtensionMethods)

/**
 Starts the first pass of parsing the Assembler source code for gathering symbols and apply preprocessor.
 @return YES if the pass was successful, otherwise NO
 */
- (BOOL)parseFirstPass;

/**
 Starts the second pass of parsing the Assembler source code for generating code.
 @return YES if the pass was successful, otherwise NO
 */
- (BOOL)parseSecondPass;

@end

NS_ASSUME_NONNULL_END
