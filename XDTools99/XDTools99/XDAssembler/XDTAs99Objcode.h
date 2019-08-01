//
//  XDTAs99Objcode.h
//  XDTools99
//
//  Created by Henrik Wedekind on 03.12.16.
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

typedef NS_ENUM(NSUInteger, XDTGenerateTextMode) {
    XDTGenerateTextModeOutputAssembler = 1,     /* it creates BYTE or DATA instructions to use in assembly or GPL */
    XDTGenerateTextModeOutputBasic = 2,         /* the returned text will contain DATA instructions to use in BASIC */
    XDTGenerateTextModeOutputC = 3,             /* returned text will be formated to use in C/C++ arrays */

    XDTGenerateTextModeOutputMask = 3,          /* Mask for separating the output configuration from the options */

    XDTGenerateTextModeOptionWord = 1 << 2,     /* generates words if set, else bytes */
    XDTGenerateTextModeOptionReverse = 1 << 3,  /* reverse byte order for target platforms with different endianness */
};

@class XDTAs99Symbols;


NS_ASSUME_NONNULL_BEGIN

@interface XDTAs99Objcode : XDTObject

@property (readonly, copy) XDTAs99Symbols *symbols;
@property (assign, getter=isStrict) BOOL strict;

/**
 *
 * There are intentionally no visible/public constructors or initializers for this class!
 *
 **/

+ (const char *)textConfigAsCString:(XDTGenerateTextMode)mode;

- (nullable NSData *)generateDump:(NSError **)error;
- (nullable NSData *)generateObjCode:(BOOL)shouldCompress error:(NSError **)error;
- (nullable NSArray<NSArray<id> *> *)generateRawBinaryAt:(NSUInteger)baseAddr error:(NSError **)error;
- (nullable NSArray<NSArray<id> *> *)generateRawBinaryAt:(NSUInteger)baseAddr withRanges:(NSArray<NSValue *> *)ranges error:(NSError **)error;
- (nullable NSString *)generateTextAt:(NSUInteger)baseAddr withMode:(XDTGenerateTextMode)mode error:(NSError **)error;
- (nullable NSArray<NSData *> *)generateImageAt:(NSUInteger)baseAddr error:(NSError **)error;
- (nullable NSArray<NSData *> *)generateImageAt:(NSUInteger)baseAddr withChunkSize:(NSUInteger)chunkSize error:(NSError **)error;
- (nullable NSData *)generateBasicLoader:(NSError **)error;
- (nullable NSDictionary<NSString *, NSData *> *)generateMESSCartridgeWithName:(NSString *)cartridgeName error:(NSError **)error;

- (nullable NSData *)generateListing:(BOOL)outputSymbols error:(NSError **)error;
- (nullable NSData *)generateSymbols:(BOOL)useEqu error:(NSError **)error;

- (void)enumerateSegmentsUsingBlock:(void (^)(NSUInteger bank, NSUInteger finalLineCount, BOOL reloc, BOOL dummy, NSArray *code))block;

@end

NS_ASSUME_NONNULL_END
