//
//  NSColorAdditions.m
//  SimpleXDT99IDE
//
//  Created by henrik on 03.07.19.
//  Copyright © 2019 hackmac. All rights reserved.
//

#import "NSColorAdditions.h"


@implementation NSColor (NSColorAdditions)

+ (NSColor *)XDTErrorBackgroundColor
{
    if (@available(macOS 10.13, *)) {
        return [NSColor colorNamed:@"XDTErrorBackgroundColor"];
    }
    return [NSColor colorWithSRGBRed:1.0 green:0.400 blue:0.085 alpha:1.0];
}


+ (NSColor *)XDTErrorTextColor
{
    if (@available(macOS 10.13, *)) {
        return [NSColor colorNamed:@"XDTErrorTextColor"];
    }
    return [NSColor colorWithSRGBRed:0.950 green:0.200 blue:0.025 alpha:1.0];
}


+ (NSColor *)XDTExceptionBackgroundColor
{
    if (@available(macOS 10.13, *)) {
        return [NSColor colorNamed:@"XDTExceptionBackgroundColor"];
    }
    return [NSColor colorWithSRGBRed:0.333 green:0.550 blue:1.0 alpha:1.0];
}


+ (NSColor *)XDTExceptionTextColor
{
    if (@available(macOS 10.13, *)) {
        return [NSColor colorNamed:@"XDTWarningTextColor"];
    }
    return [NSColor colorWithSRGBRed:0.250 green:0.333 blue:0.950 alpha:1.0];
}


+ (NSColor *)XDTSourceBlockCommentColor
{
    if (@available(macOS 10.13, *)) {
        return [NSColor colorNamed:@"XDTSourceBlockCommentColor"];
    }
    return [NSColor secondaryLabelColor];
}


+ (NSColor *)XDTSourceLabelDefinitionColor
{
    if (@available(macOS 10.13, *)) {
        return [NSColor colorNamed:@"XDTSourceLabelDefinitionColor"];
    }
    return [NSColor systemBlueColor];
}


+ (NSColor *)XDTSourceLabelReferenceColor
{
    if (@available(macOS 10.13, *)) {
        return [NSColor colorNamed:@"XDTSourceLabelReferenceColor"];
    }
    return [NSColor colorWithSRGBRed:0.539 green:0.518 blue:1.000 alpha:1.0];
}


+ (NSColor *)XDTSourceLineCommentColor
{
    if (@available(macOS 10.13, *)) {
        return [NSColor colorNamed:@"XDTSourceLineCommentColor"];
    }
    return [NSColor secondaryLabelColor];
}


+ (NSColor *)XDTSourceMacroColor
{
    if (@available(macOS 10.13, *)) {
        return [NSColor colorNamed:@"XDTSourceMacroColor"];
    }
    return [NSColor systemOrangeColor];
}


+ (NSColor *)XDTSourceNumericLiteralColor
{
    if (@available(macOS 10.13, *)) {
        return [NSColor colorNamed:@"XDTSourceNumericLiteralColor"];
    }
    return [NSColor colorWithSRGBRed:0.196 green:0.619 blue:0.169 alpha:1.0];
}


+ (NSColor *)XDTSourcePreProcColor
{
    if (@available(macOS 10.13, *)) {
        return [NSColor colorNamed:@"XDTSourcePreProcColor"];
    }
    return [NSColor systemBrownColor];
}


+ (NSColor *)XDTSourceTextColor
{
    if (@available(macOS 10.13, *)) {
        return [NSColor colorNamed:@"XDTSourceTextColor"];
    }
    return [NSColor textColor];
}


+ (NSColor *)XDTSourceTextualLiteralColor
{
    if (@available(macOS 10.13, *)) {
        return [NSColor colorNamed:@"XDTSourceTextualLiteralColor"];
    }
    return [NSColor systemYellowColor];
}


+ (NSColor *)XDTWarningBackgroundColor
{
    if (@available(macOS 10.13, *)) {
        return [NSColor colorNamed:@"XDTWarningBackgroundColor"];
    }
    return [NSColor colorWithSRGBRed:1.0 green:0.650 blue:0.085 alpha:1.0];
}


+ (NSColor *)XDTWarningTextColor
{
    if (@available(macOS 10.13, *)) {
        return [NSColor colorNamed:@"XDTWarningTextColor"];
    }
    return [NSColor colorWithSRGBRed:0.950 green:0.500 blue:0.025 alpha:1.0];
}

@end
