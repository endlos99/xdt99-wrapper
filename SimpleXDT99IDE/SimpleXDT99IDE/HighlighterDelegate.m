//
//  HighlighterDelegate.m
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

#import "HighlighterDelegate.h"

#import "NSColorAdditions.h"


NS_ASSUME_NONNULL_BEGIN

@interface HighlighterDelegate () {
    NSMutableAttributedString *_processingText;
    NSRange _processingRange;
}

@property (retain) NSObject<XDTLineScannerProtocol> *lineScanner;

- (instancetype)initWithLineScanner:(NSObject<XDTLineScannerProtocol> *)lineScanner;

@end

NS_ASSUME_NONNULL_END


@implementation HighlighterDelegate

+ (instancetype)highlighterWithLineScanner:(NSObject<XDTLineScannerProtocol> *)lineScanner
{
    HighlighterDelegate *retVal = [[HighlighterDelegate alloc] initWithLineScanner:lineScanner];
#if !__has_feature(objc_arc)
    [retVal autorelease];
#endif
    return retVal;
}


- (instancetype)initWithLineScanner:(NSObject<XDTLineScannerProtocol> *)lineScanner
{
    if (![lineScanner conformsToProtocol:@protocol(XDTLineScannerProtocol)]) {
        return nil;
    }
    self = [super init];
    if (nil == self) {
        return nil;
    }

    self.lineScanner = lineScanner;

    return self;
}


- (void)dealloc
{
#if !__has_feature(objc_arc)
    [_lineScanner release];

    [super dealloc];
#endif
}


- (void)processAttributesOfText:(NSMutableAttributedString *)text inRange:(NSRange)lineRange
{
    if (0 >= lineRange.length || 0 >= text.length || nil == _lineScanner) {
        return;
    }
    NSString *lineString = [text.mutableString substringWithRange:lineRange];

    // First reset the whole line with standard color and font.
    [text setAttributes:@{NSForegroundColorAttributeName: [NSColor XDTSourceTextColor],
                          NSFontAttributeName: [NSFont fontWithName:@"Menlo" size:0.0]} range:lineRange];

    _processingText = text;
    _processingRange = lineRange;
    (void)[_lineScanner processLine:lineString consumer:self];
}


#pragma mark - Protocol implementation of NSTextStorageDelegate


- (void)textStorage:(NSTextStorage *)textStorage didProcessEditing:(NSTextStorageEditActions)editedMask range:(NSRange)editedRange changeInLength:(NSInteger)delta
{
    if (0 == (NSTextStorageEditedCharacters & editedMask) ||
        nil == _lineScanner || 0 >= textStorage.length || textStorage.length <= editedRange.length) {
        return;
    }

    [textStorage beginEditing];
    NSRange editedLineRange = [textStorage.mutableString lineRangeForRange:editedRange];
    // For that case, that multiple lines are pasted into the source code, just iterate all lines separately.
    [textStorage.mutableString enumerateSubstringsInRange:editedLineRange
                                                  options:NSStringEnumerationByLines + NSStringEnumerationSubstringNotRequired
                                               usingBlock:^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {
                                                   NSRange lineRange = [textStorage.mutableString lineRangeForRange:substringRange];
                                                   [self processAttributesOfText:textStorage inRange:lineRange];
                                               }];
    [textStorage endEditing];
}


#pragma mark - Protocol implementation of XDTConsumerProtocol


- (void)consumeBlockComment:(NSString *)comment inRange:(NSRange)commentRange
{
    commentRange.location = _processingRange.location + commentRange.location;
    [_processingText addAttribute:NSForegroundColorAttributeName value:[NSColor XDTSourceBlockCommentColor] range:commentRange];
}


- (void)consumeLineComment:(NSString *)comment inRange:(NSRange)commentRange
{
    commentRange.location = _processingRange.location + commentRange.location;
    [_processingText addAttribute:NSForegroundColorAttributeName value:[NSColor XDTSourceLineCommentColor] range:commentRange];
}


- (void)consumePreProcDirective:(NSString *)directive inRange:(NSRange)directiveRange
{
    directiveRange.location += _processingRange.location;
    [_processingText addAttribute:NSForegroundColorAttributeName value:[NSColor XDTSourcePreProcColor] range:directiveRange];
}


/*- (void)consumeDirective:(NSString *)directive inRange:(NSRange)directiveRange
{

}*/


- (void)consumeNumericLiteral:(NSString *)literal inRange:(NSRange)literalRange
{
    literalRange.location += _processingRange.location;
    [_processingText addAttribute:NSForegroundColorAttributeName value:[NSColor XDTSourceNumericLiteralColor] range:literalRange];
}


- (void)consumeFilename:(NSString *)link inRange:(NSRange)linkRange
{
    NSURLComponents *urlComponents = [NSURLComponents new];
    // xdt99:/asmacs.asm?line=1
    urlComponents.scheme = @"xdt99";
    NSRange pathRange = {linkRange.location+1, linkRange.length-2};
    urlComponents.path = [link substringWithRange:pathRange];

    pathRange.location += _processingRange.location;
    [_processingText addAttributes:@{
                                     //NSForegroundColorAttributeName:[NSColor XDTSourceTextualLiteralColor],  /* This takes no effect! TODO: To find out how to change the default link color. */
                                     NSLinkAttributeName: urlComponents.URL,
                                     NSToolTipAttributeName: [NSString stringWithFormat:NSLocalizedString(@"Opens '%@' in a new tabbed window.", @"Tool tip text for a linked include file."), urlComponents.path]
                                     } range:pathRange];
    linkRange.location += _processingRange.location;
    [_processingText addAttribute:NSForegroundColorAttributeName value:[NSColor XDTSourceTextualLiteralColor] range:linkRange];
}


- (void)consumeTextLiteral:(NSString *)text inRange:(NSRange)textRange
{
    textRange.location += _processingRange.location;
    [_processingText addAttribute:NSForegroundColorAttributeName value:[NSColor XDTSourceTextualLiteralColor] range:textRange];
}


- (void)consumeMacro:(NSString *)macro inRange:(NSRange)macroRange
{
    macroRange.location += _processingRange.location;
    [_processingText addAttribute:NSForegroundColorAttributeName value:[NSColor XDTSourceMacroColor] range:macroRange];
}


- (void)consumeLabelDefinition:(NSString *)label inRange:(NSRange)labelRange
{
    labelRange.location += _processingRange.location;
    [_processingText addAttribute:NSForegroundColorAttributeName value:[NSColor XDTSourceLabelDefinitionColor] range:labelRange];
}


- (void)consumeLabelReference:(NSString *)label inRange:(NSRange)labelRange
{
    labelRange.location += _processingRange.location;
    [_processingText addAttribute:NSForegroundColorAttributeName value:[NSColor XDTSourceLabelReferenceColor] range:labelRange];
}

@end
