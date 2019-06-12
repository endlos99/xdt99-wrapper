//
//  XDTAs99Symbols.h
//  XDTools99
//
//  Created by Henrik Wedekind on 04.12.16.
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


NS_ASSUME_NONNULL_BEGIN

@interface XDTAs99Symbols : XDTObject

+ (nullable instancetype)symbolsWithPythonInstance:(void *)object;

@property (nullable, readonly) NSDictionary *symbols;
@property (nullable, readonly) NSArray *refdefs;
@property (nullable, readonly) NSDictionary *xops;
@property (nullable, readonly) NSDictionary *locations;

- (void)resetLineCounter;
- (NSUInteger)effectiveLineCounter;

- (BOOL)addSymbolName:(NSString *)name withValue:(NSUInteger)value;
- (BOOL)addLabel:(NSString *)label withLineIndex:(NSUInteger)lineIdx;
- (BOOL)addLabel:(NSString *)label withLineIndex:(NSUInteger)lineIdx usingEffectiveLineCount:(BOOL)realLineCount;
- (BOOL)addLocalLabel:(NSString *)label withLineIndex:(NSUInteger)lineIdx;

- (BOOL)addDef:(NSString *)name;
- (BOOL)addRef:(NSString *)name;
- (BOOL)addXop:(NSString *)name mode:(NSUInteger)mode;

- (NSUInteger)getSymbol:(NSString *)name;
- (NSUInteger)getLocal:(NSString *)name position:(NSUInteger)lpos distance:(NSUInteger)distance;

@end

NS_ASSUME_NONNULL_END
