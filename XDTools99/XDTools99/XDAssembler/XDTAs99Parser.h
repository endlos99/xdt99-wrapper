//
//  XDTParser.h
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


#define XDTAssemblerVersionRequired "2.0.2"


@class XDTAs99Symbols, XDTMessage;


NS_ASSUME_NONNULL_BEGIN

typedef NSString * XDTAs99ParserOptionKey NS_EXTENSIBLE_STRING_ENUM; /* Type for keys used in the options dictionry */

FOUNDATION_EXPORT XDTAs99ParserOptionKey const XDTAs99ParserOptionRegister;
FOUNDATION_EXPORT XDTAs99ParserOptionKey const XDTAs99ParserOptionStrict;
FOUNDATION_EXPORT XDTAs99ParserOptionKey const XDTAs99ParserOptionWarnings;


@interface XDTAs99Parser : XDTObject <XDTParserProtocol>

@property (readonly, copy) XDTAs99Symbols *symbols;
@property (readonly, nullable) XDTMessage *messages;
@property (copy, nullable) NSString *path;

/**
 Creates an autoreleased instance of XDTAs99Parser

 @param options  A dictionary containig key value pairs to specify options for the parser.
 */
+ (nullable instancetype)parserWithOptions:(NSDictionary<XDTAs99ParserOptionKey,id> *)options;

/**
 Set the source code where the parser works on.
 */
- (void)setSource:(NSString *)source;

/**
 Finds the location of a file with given name

 @param name    the name of the file to search for
 @param error   Return by reference the error. Can set to nil if the information is not nedded.
 @return the path of the located file

 */
- (nullable NSString *)findFile:(NSString *)name error:(NSError **_Nullable)error;

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
