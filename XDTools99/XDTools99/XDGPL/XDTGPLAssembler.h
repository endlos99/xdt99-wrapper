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

#import "XDTGa99Syntax.h"


typedef NS_ENUM(NSUInteger, XDTGa99TargetType) {
    XDTGa99TargetTypePlainByteCode,
    XDTGa99TargetTypeHeaderedByteCode,
    XDTGa99TargetTypeMESSCartridge,
};


@class XDTGa99Objcode, XDTMessage;


NS_ASSUME_NONNULL_BEGIN

@interface XDTGPLAssembler : XDTObject

@property (readonly) NSString *version;
@property (assign) NSUInteger gromAddress;
@property (assign) NSUInteger aorgAddress;
@property (assign) XDTGa99TargetType targetType;
@property (assign) XDTGa99SyntaxType syntaxType;
@property (assign) BOOL outputWarnings;
@property (readonly, nullable) XDTMessage *messages;    /* Object that contains all messages (Error, Warning, etc) after the assembler run */

+ (nullable instancetype)gplAssemblerWithIncludeURL:(NSURL *)url grom:(NSUInteger)gromAddress aorg:(NSUInteger)aorgAddress target:(XDTGa99TargetType)targetType syntax:(XDTGa99SyntaxType)syntaxType outputWarnings:(BOOL)outputWarnings;

- (nullable XDTGa99Objcode *)assembleSourceFile:(NSURL *)srcname error:(NSError **)error;
- (nullable XDTGa99Objcode *)assembleSourceFile:(NSURL *)srcname pathName:(NSURL *)pathName error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
