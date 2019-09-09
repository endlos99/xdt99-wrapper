//
//  XDTGPLParser.h
//  XDTools99
//
//  Created by Henrik Wedekind on 02.07.19.
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

#import "XDTObject.h"

#import "XDTGPLAssembler.h"


@class XDTGPLObjcode, XDTGa99SyntaxVariant, XDTMessage;


NS_ASSUME_NONNULL_BEGIN

@interface XDTGa99Parser : XDTObject <XDTParserProtocol>

@property (assign) BOOL outputWarnings;
@property (copy, nullable) XDTGa99SyntaxVariant *syntaxVariant;
@property (copy, nullable) NSString *path;
@property (readonly, nullable) XDTMessage *messages;

/**
 Creates an autoreleased instance of XDTParser with default options
 */
+ (nullable instancetype)parserForPath:(NSString *)path usingSyntaxType:(XDTGa99SyntaxType)syntaxType outputWarnings:(BOOL)outputWarnings;

/**
 Set the source code where the parser works on.
 */
- (void)setSource:(NSString *)source;

@end


@interface XDTGa99Parser (XDTGa99ParserExtensionMethods)


/**
 Starts parsing the GPL-Assembler source code for gathering symbols and apply preprocessor and for generating code.

 @return YES if the pass was successful, otherwise NO

 Errors can be obtained through the property \p messages.
 */
- (BOOL)parse;

@end

NS_ASSUME_NONNULL_END
