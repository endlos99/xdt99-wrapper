//
//  XDTGa99Syntax.h
//  XDTools99
//
//  Created by Henrik Wedekind on 22.07.19.
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


@class XDTGa99SyntaxVariant;


typedef NS_ENUM(NSUInteger, XDTGa99SyntaxType) {
    XDTGa99SyntaxTypeNativeXDT99,   /* Ryte/RAG syntax variant */
    XDTGa99SyntaxTypeRAGGPL,        /* RAG syntax variant. Obsolete with xga99 v1.8.5 - conbined with the Ryte syntax */
    XDTGa99SyntaxTypeTIImageTool,   /* Syntax variant for the GPL disassembler of TIImageTool */
};


NS_ASSUME_NONNULL_BEGIN

@interface XDTGa99Syntax : XDTObject

+ (instancetype)syntaxWithPythonInstance:(PyObject *)object;

+ (XDTGa99SyntaxVariant *_Nullable)syntaxVariantForType:(XDTGa99SyntaxType)syntaxType error:(NSError **)error;

+ (const char *_Nullable)syntaxTypeAsCString:(XDTGa99SyntaxType)syntaxType;

@end

NS_ASSUME_NONNULL_END
