//
//  HighlighterDelegate.h
//  SimpleXDT99IDE
//
//  Created by Henrik Wedekind on 30.06.19.
//
//  SimpleXDT99IDE a simple IDE based on xdt99 that shows how to use the XDTools99.framework
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

#import <Cocoa/Cocoa.h>

#import <XDTools99/XDTools99.h>


NS_ASSUME_NONNULL_BEGIN

@interface HighlighterDelegate : NSObject <NSTextStorageDelegate, XDTConsumerProtocol>

+ (instancetype)highlighterWithLineScanner:(NSObject<XDTLineScannerProtocol> *)lineScanner;

- (void)processAttributesOfText:(NSMutableAttributedString *)text inRange:(NSRange)lineRange;

@end

NS_ASSUME_NONNULL_END
