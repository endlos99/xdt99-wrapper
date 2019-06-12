//
//  XDTAssembler.h
//  XDTools99
//
//  Created by Henrik Wedekind on 01.12.16.
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

#import "XDTObject.h"


#define XDTAssemblerVersionRequired "2.0.2"


typedef NS_ENUM(NSUInteger, XDTAs99TargetType) {
    XDTAs99TargetTypeObjectCode,       /* The format used by the Editor/Assembler Option 3 */
    XDTAs99TargetTypeProgramImage,     /* The format used by the Editor/Assembler Option 5 */
    XDTAs99TargetTypeMESSCartridge,    /* Create an RPK cartridge file that can be used with the MESS emulator */
    XDTAs99TargetTypeRawBinary,        /* An image format without any metadata, i.e. suitable for burning EPROMs */
    XDTAs99TargetTypeTextBinaryAsm,    /* Text file with binary values, useful for including it into foreign Assembler source source */
    XDTAs99TargetTypeTextBinaryBas,    /* Text file with binary values, useful for including it into foreign Basic source source */
    XDTAs99TargetTypeTextBinaryC,      /* Text file with binary values, useful for including it into foreign C/C++ source source */
    XDTAs99TargetTypeEmbededXBasic,    /* This format wraps a XBasic program around the generated code */
};


@class XDTAs99Objcode;


NS_ASSUME_NONNULL_BEGIN

typedef NSString * XDTAs99OptionKey NS_EXTENSIBLE_STRING_ENUM; /* Keys for use in the NSDictionry */

FOUNDATION_EXPORT XDTAs99OptionKey const XDTAs99OptionRegister;   /* (NSNumber) A BOOL to enable R notaion for registers */
FOUNDATION_EXPORT XDTAs99OptionKey const XDTAs99OptionStrict;     /* (NSNumber) A BOOL to indicate the strict mode */
FOUNDATION_EXPORT XDTAs99OptionKey const XDTAs99OptionTarget;     /* (NSNumber) A XDTAs99TargetType to choose the generated result */
FOUNDATION_EXPORT XDTAs99OptionKey const XDTAs99OptionWarnings;   /* (NSNumber) A BOOL to indicate that warning messages should be generated */


@interface XDTAssembler : XDTObject

@property (readonly) NSString *version;
@property (readonly) BOOL beStrict;
@property (readonly) BOOL useRegisterSymbols;
@property (readonly) BOOL outputWarnings;
@property (readonly) NSArray<NSString *> *warnings;
@property (readonly) XDTAs99TargetType targetType;

+ (BOOL)checkRequiredModuleVersion;

+ (nullable instancetype)assemblerWithOptions:(NSDictionary<XDTAs99OptionKey, id> *)options includeURL:(NSURL *)url;

- (nullable XDTAs99Objcode *)assembleSourceFile:(NSURL *)srcFile error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
