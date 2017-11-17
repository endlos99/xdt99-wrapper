//
//  XDTAssembler.h
//  TIDisk-Manager
//
//  Created by Henrik Wedekind on 01.12.16.
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

#import <Foundation/Foundation.h>

#import "XDTObject.h"


#define XDTAssemblerOptionRegister @"XDTAssemblerOptionRegister"
#define XDTAssemblerOptionStrict @"XDTAssemblerOptionStrict"
#define XDTAssemblerOptionTarget @"XDTAssemblerOptionTarget"


typedef NSUInteger XDTAssemblerTargetType;
NS_ENUM(XDTAssemblerTargetType) {
    XDTAssemblerTargetTypeObjectCode,       /* The format used by the Editor/Assembler Option 3 */
    XDTAssemblerTargetTypeProgramImage,     /* The format used by the Editor/Assembler Option 5 */
    XDTAssemblerTargetTypeMESSCartridge,    /* Create an RPK cartridge file that can be used with the MESS emulator */
    XDTAssemblerTargetTypeRawBinary,        /* An image format without any metadata, i.e. suitable for burning EPROMs */
    XDTAssemblerTargetTypeTextBinary,       /* Text file with binary values, useful for including it into some foreign source source */
    XDTAssemblerTargetTypeEmbededXBasic,    /* This format wraps a XBasic program around the generated code */
    XDTAssemblerTargetTypeJumpstart,        /* Executed by the Jumpstart cartridge included with xdt99 */
};


@class XDTObjcode;


NS_ASSUME_NONNULL_BEGIN
@interface XDTAssembler : XDTObject

@property (readonly) BOOL beStrict;
@property (readonly) BOOL useRegisterSymbols;
@property (readonly) XDTAssemblerTargetType targetType;

+ (nullable instancetype)assemblerWithOptions:(NSDictionary<NSString *, NSObject *> *)options includeURL:(NSURL *)url;

- (nullable XDTObjcode *)assembleSourceFile:(NSURL *)srcname error:(NSError **)error;
- (nullable XDTObjcode *)assembleSourceFile:(NSURL *)srcname pathName:(NSURL *)pathName error:(NSError **)error;

@end
NS_ASSUME_NONNULL_END
