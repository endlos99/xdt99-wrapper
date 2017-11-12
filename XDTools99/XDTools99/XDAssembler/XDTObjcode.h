//
//  XDTObjcode.h
//  SimpleXDT99
//
//  Created by Henrik Wedekind on 03.12.16.
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


@class XDTSymbols;


NS_ASSUME_NONNULL_BEGIN
@interface XDTObjcode : XDTObject

@property (retain) XDTSymbols *symbols;

/**
 *
 * There are intentionally no visible/public constructors or initializers for this class!
 *
 **/

- (nullable NSData *)generateDump;
- (nullable NSData *)generateObjCode:(BOOL)shouldCompress;
- (nullable NSArray<NSArray<id> *> *)generateRawBinaryAt:(NSUInteger)baseAddr;
- (nullable NSArray<NSArray<id> *> *)generateRawBinaryAt:(NSUInteger)baseAddr withRanges:(NSArray<NSValue *> *)ranges;
- (nullable NSArray<NSData *> *)generateImageAt:(NSUInteger)baseAddr;
- (nullable NSArray<NSData *> *)generateImageAt:(NSUInteger)baseAddr withChunkSize:(NSUInteger)chunkSize;
- (nullable NSData *)generateBasicLoader;
- (nullable NSData *)generateJumpstart;
- (nullable NSDictionary<NSString *, NSData *> *)generateMESSCartridgeWithName:(NSString *)cartridgeName;

- (nullable NSData *)generateListing;

@end
NS_ASSUME_NONNULL_END
