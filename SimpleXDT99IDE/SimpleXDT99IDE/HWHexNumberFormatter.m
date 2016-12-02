//
//  HWHexNumberFormatter.m
//  SimpleXDT99IDE
//
//  Created by Henrik Wedekind on 17.12.16.
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

#import "HWHexNumberFormatter.h"


@implementation HWHexNumberFormatter

- (NSString *)stringForObjectValue:(id)obj
{
    if (nil == obj || ![obj isKindOfClass:[NSNumber class]]) {
        return nil;
    }
    return [NSString stringWithFormat:@"0x%04X", [obj unsignedShortValue]];
}


- (BOOL)getObjectValue:(out id  _Nullable __autoreleasing *)obj forString:(NSString *)string errorDescription:(out NSString *__autoreleasing  _Nullable *)error
{
    NSScanner *scanner = [NSScanner scannerWithString:string];
    unsigned int hexInt = 0;
    /* if you want to convert TI typical representations of hex numbers use the next lines */
    //[scanner scanString:@">" intoString:nil];
    //if ([scanner scanInt:&hexInt] && [scanner isAtEnd]) {
    if ([scanner scanHexInt:&hexInt] && [scanner isAtEnd]) {
        *obj = [NSNumber numberWithUnsignedShort:hexInt];

        return YES;
    }
    if (nil != error) {
        *error = NSLocalizedString(@"Couldn’t convert to hexadicimal", @"Error converting");
    }
    return NO;
}

@end
