//
//  XDTGPLAssembler.h
//  XDTools99
//
//  Created by Henrik Wedekind on 18.12.16.
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

#import "XDTObject.h"


#define XDTGPLAssemblerOptionGROM @"XDTGPLAssemblerOptionGROM"
#define XDTGPLAssemblerOptionAORG @"XDTGPLAssemblerOptionAORG"
#define XDTGPLAssemblerOptionStyle @"XDTGPLAssemblerOptionStyle"
#define XDTGPLAssemblerOptionTarget @"XDTGPLAssemblerOptionTarget"


typedef NSUInteger XDTGPLAssemblerSyntaxType;
NS_ENUM(XDTGPLAssemblerSyntaxType) {
    XDTGPLAssemblerSyntaxTypeNativeXDT99,
    XDTGPLAssemblerSyntaxTypeRAGGPL,
    XDTGPLAssemblerSyntaxTypeTIImageTool,
};

typedef NSUInteger XDTGPLAssemblerTargetType;
NS_ENUM(XDTGPLAssemblerTargetType) {
    XDTGPLAssemblerTargetTypePlainByteCode,
    XDTGPLAssemblerTargetTypeHeaderedByteCode,
    XDTGPLAssemblerTargetTypeMESSCartridge,
};


@class XDTGPLObjcode;


NS_ASSUME_NONNULL_BEGIN
@interface XDTGPLAssembler : XDTObject

@property (readonly) NSUInteger gromAddress;
@property (readonly) NSUInteger aorgAddress;
@property (readonly) XDTGPLAssemblerTargetType targetType;
@property (readonly) XDTGPLAssemblerSyntaxType syntaxType;

+ (nullable instancetype)gplAssemblerWithOptions:(NSDictionary<NSString *, NSObject *> *)options includeURL:(NSURL *)url;

- (nullable XDTGPLObjcode *)assembleSourceFile:(NSURL *)srcname error:(NSError **)error;
- (nullable XDTGPLObjcode *)assembleSourceFile:(NSURL *)srcname pathName:(NSURL *)pathName error:(NSError **)error;

@end
NS_ASSUME_NONNULL_END
