//
//  XDTGPLAssembler.h
//  XDTools99
//
//  Created by Henrik Wedekind on 18.12.16.
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

#import "XDTObject.h"


#define XDTGPLAssemblerVersionRequired "2.0.2"

typedef NS_ENUM(NSUInteger, XDTGa99SyntaxType) {
    XDTGa99SyntaxTypeNativeXDT99,   /* Ryte/RAG syntax variant */
    XDTGa99SyntaxTypeRAGGPL,        /* RAG syntax variant. Obsolete with xga99 v1.8.5 - conbined with the Ryte syntax */
    XDTGa99SyntaxTypeTIImageTool,   /* Syntax variant for the GPL disassembler of TIImageTool */
};

typedef NS_ENUM(NSUInteger, XDTGa99TargetType) {
    XDTGa99TargetTypePlainByteCode,
    XDTGa99TargetTypeHeaderedByteCode,
    XDTGa99TargetTypeMESSCartridge,
};


@class XDTGa99Objcode, XDTMessage;


NS_ASSUME_NONNULL_BEGIN

typedef NSString * XDTGa99OptionKey NS_EXTENSIBLE_STRING_ENUM; /* Keys for use in the NSDictionry */

FOUNDATION_EXPORT XDTGa99OptionKey const XDTGa99OptionGROM;
FOUNDATION_EXPORT XDTGa99OptionKey const XDTGa99OptionAORG;
FOUNDATION_EXPORT XDTGa99OptionKey const XDTGa99OptionStyle;
FOUNDATION_EXPORT XDTGa99OptionKey const XDTGa99OptionTarget;
FOUNDATION_EXPORT XDTGa99OptionKey const XDTGa99OptionWarnings;


@interface XDTGPLAssembler : XDTObject

@property (readonly) NSString *version;
@property (readonly) NSUInteger gromAddress;
@property (readonly) NSUInteger aorgAddress;
@property (readonly) XDTGa99TargetType targetType;
@property (readonly) XDTGa99SyntaxType syntaxType;
@property (readonly) BOOL outputWarnings;
@property (readonly, nullable) XDTMessage *messages;    /* Object that contains all messages (Error, Warning, etc) after the assembler run */

+ (const char *_Nullable)syntaxTypeAsCString:(XDTGa99SyntaxType)syntaxType;

+ (BOOL)checkRequiredModuleVersion;

+ (nullable instancetype)gplAssemblerWithOptions:(NSDictionary<XDTGa99OptionKey, id> *)options includeURL:(NSURL *)url;

- (nullable XDTGa99Objcode *)assembleSourceFile:(NSURL *)srcname error:(NSError **)error;
- (nullable XDTGa99Objcode *)assembleSourceFile:(NSURL *)srcname pathName:(NSURL *)pathName error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
