//
//  XDTGa99Symbols.h
//  XDTools99
//
//  Created by Henrik Wedekind on 16.07.19.
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


NS_ASSUME_NONNULL_BEGIN

@interface XDTGa99Symbols : XDTObject

+ (nullable instancetype)symbolsWithPythonInstance:(void *)object;

@property (nullable, readonly, copy) NSDictionary<NSString *, NSNumber *> *symbols;
@property (nullable, readonly, copy) NSArray<NSString *> *symbolList;

@end

NS_ASSUME_NONNULL_END
