//
//  NSColorAdditions.m
//  SimpleXDT99IDE
//
//  Created by henrik on 03.07.19.
//  Copyright © 2019 hackmac. All rights reserved.
//

#import "NSColorAdditions.h"


@implementation NSColor (NSColorAdditions)

+ (NSColor *)XDTErrorTextColor
{
    if (@available(macOS 10.13, *)) {
        return [NSColor colorNamed:@"XDTErrorTextColor"];
    }
    return [NSColor colorWithSRGBRed:0.950 green:0.200 blue:0.025 alpha:1.0];
}


+ (NSColor *)XDTExceptionTextColor
{
    if (@available(macOS 10.13, *)) {
        return [NSColor colorNamed:@"XDTWarningTextColor"];
    }
    return [NSColor colorWithSRGBRed:0.250 green:0.333 blue:0.950 alpha:1.0];
}


+ (NSColor *)XDTWarningTextColor
{
    if (@available(macOS 10.13, *)) {
        return [NSColor colorNamed:@"XDTWarningTextColor"];
    }
    return [NSColor colorWithSRGBRed:0.950 green:0.500 blue:0.025 alpha:1.0];
}

@end
