//
//  XDTLineScanner.m
//  XDTools99
//
//  Created by Henrik Wedekind on 02.07.19.
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

#import "XDTLineScanner.h"

#import "XDTAs99Symbols.h"
#import "XDTAs99Parser.h"


NS_ASSUME_NONNULL_BEGIN

@interface XDTLineScanner () {
    // temporary variables used while processing line through processLine:
    NSString *_processingLine;
    NSArray<id> *_processingLineComponents;
}

@property (retain) XDTObject<XDTParserProtocol> *parser;
@property (retain) NSArray<NSString *> *symbolList;

- (nullable instancetype)initWithParser:(XDTObject<XDTParserProtocol> *)parser symbols:(NSArray<NSString *> *)symbolList;

- (NSRange)rangeForComments:(BOOL *)isBlockComment;
- (NSRange)rangeForPreProcDirective:(BOOL *)hasParameter;
- (NSRange)rangeForMacro;
- (NSRange)rangeForFilename;
- (NSRange)rangeForText:(BOOL *)isStringLiteral;
- (NSRange)rangeForLiteral;
- (NSRange)rangeForLabelDefinition;
- (void)enumerateRangesForLabelReferencesWithBlock:(void (^)(NSRange labelReferenceRange))block;
- (void)enumerateRangesForLiteralsWithBlock:(void (^)(NSRange literalRange))block;

@end

NS_ASSUME_NONNULL_END


@implementation XDTLineScanner

static const NSArray<NSString *> *_directivesPreProc0, *_directivesPreProc1, *_directivesWithData, *_ignored;


+ (void)initialize
{
    _ignored = @[@"EVEN", @"PSEG", @"PEND", @"CSEG", @"CEND", @"DSEG", @"DEND", @"UNL", @"LIST", @"PAGE", @"TITL", @"LOAD", @"SREF"];
    _directivesPreProc0 = @[@".ENDM", @".ENDIF", @".ELSE"]; // preprocessor directives without parameter
    _directivesPreProc1 = @[@"COPY", @".DEFM", @".IFDEF", @".IFNDEF", @".IFEQ", @".IFNE", @".IFGT", @".IFGE", @".PRINT", @".ERROR"];    // preprocessor directives with parameter
    _directivesWithData = @[@"DATA", @"BYTE", @"TEXT", @"STRI", @"FLOA", @"END"];
}


+ (instancetype)scannerWithParser:(XDTAs99Parser *)parser symbols:(NSArray<NSString *> *)symbolList
{
    if (![parser conformsToProtocol:@protocol(XDTParserProtocol)]) {
        return nil;
    }
    XDTLineScanner *retVal = [[XDTLineScanner alloc] initWithParser:parser symbols:symbolList];
#if !__has_feature(objc_arc)
    return [retVal autorelease];
#else
    return retVal;
#endif
}


- (instancetype)initWithParser:(XDTAs99Parser *)parser symbols:(NSArray<NSString *> *)symbolList
{
    self = [super init];
    if (nil == self) {
        return nil;
    }

    self.parser = parser;
    self.symbolList = symbolList;

    return self;
}


- (void)dealloc
{
#if !__has_feature(objc_arc)
    [_parser release];
    [super dealloc];
#endif
}


#pragma mark -


- (BOOL)processLine:(NSString *)line consumer:(id<XDTConsumerProtocol>)delegate
{
    _processingLineComponents = [_parser splitLine:line];
    if (nil == _processingLineComponents) {
        _processingLine = nil;
        return NO;
    }
    _processingLine = line;

    /*
     line comments
     */
    BOOL isBlockComment = NO;
    NSRange commentRange = [self rangeForComments:&isBlockComment];
    if (0 < commentRange.length) {
        if (isBlockComment && [delegate respondsToSelector:@selector(consumeBlockComment:inRange:)]) {
            [delegate consumeBlockComment:_processingLine inRange:commentRange];
        }
        if (!isBlockComment && [delegate respondsToSelector:@selector(consumeLineComment:inRange:)]) {
            [delegate consumeLineComment:_processingLine inRange:commentRange];
        }
        if (NSEqualRanges(commentRange, NSMakeRange(0, _processingLine.length))) {
            /* if it was a full line comment, there is nothing left to check, so return */
            return YES;
        }
    }

    /*
     label
     */
    NSRange labelDefinitionRange = self.rangeForLabelDefinition;
    if (0 < labelDefinitionRange.length) {
        if ([delegate respondsToSelector:@selector(consumeLabelDefinition:inRange:)]) {
            [delegate consumeLabelDefinition:_processingLine inRange:labelDefinitionRange];
        }
    }
    if ([delegate respondsToSelector:@selector(consumeLabelReference:inRange:)]) {
        [self enumerateRangesForLabelReferencesWithBlock:^(NSRange labelReferenceRange) {
            [delegate consumeLabelReference:self->_processingLine inRange:labelReferenceRange];
        }];
    }

    /*
     preprocessor directives
     */
    BOOL hasParameter;
    NSRange preProcDirectiveRange = [self rangeForPreProcDirective:&hasParameter];
    if (0 < preProcDirectiveRange.length) {
        if ([delegate respondsToSelector:@selector(consumePreProcDirective:inRange:)]) {
            [delegate consumePreProcDirective:_processingLine inRange:preProcDirectiveRange];
        }
        if (hasParameter) {
            /*
             directive with parameter
             */
            if (NSOrderedSame == [@"COPY" caseInsensitiveCompare:[_processingLine substringWithRange:preProcDirectiveRange]]) {
                NSRange filenameRange = self.rangeForFilename;
                if (0 < filenameRange.length) {
                    if ([delegate respondsToSelector:@selector(consumeFilename:inRange:)]) {
                        // include the quotes of the file name
                        filenameRange.location--;
                        filenameRange.length += 2;
                        [delegate consumeFilename:_processingLine inRange:filenameRange];
                    }
                }
            } else {
                if ([delegate respondsToSelector:@selector(consumeNumericLiteral:inRange:)]) {
                    [self enumerateRangesForLiteralsWithBlock:^(NSRange literalRange) {
                        [delegate consumeNumericLiteral:self->_processingLine inRange:literalRange];
                    }];
                }
            }
        }
    } else {
        NSRange directiveRange = self.rangeForDirectiveWithData;
        if (0 < directiveRange.length) {
            if ([delegate respondsToSelector:@selector(consumeDirective:inRange:)]) {
                [delegate consumeDirective:_processingLine inRange:directiveRange];
            }
            NSString *directive = [_processingLine substringWithRange:directiveRange];
            if (NSOrderedSame == [@"TEXT" caseInsensitiveCompare:directive] ||
                NSOrderedSame == [@"STRI" caseInsensitiveCompare:directive]) {
                BOOL isStringLiteral = YES;
                NSRange textRange = [self rangeForText:&isStringLiteral];
                if (0 < textRange.length) {
                    if ([delegate respondsToSelector:@selector(consumeTextLiteral:inRange:)]) {
                        if (isStringLiteral) {
                            // include the quotes of the text string
                            textRange.location--;
                            textRange.length += 2;
                        }
                        [delegate consumeTextLiteral:_processingLine inRange:textRange];
                    }
                }
            } else {
                if ([delegate respondsToSelector:@selector(consumeNumericLiteral:inRange:)]) {
                    [self enumerateRangesForLiteralsWithBlock:^(NSRange literalRange) {
                        [delegate consumeNumericLiteral:self->_processingLine inRange:literalRange];
                    }];
                }
            }
        } else {
            /*
             macro menmonics
             */
            preProcDirectiveRange = self.rangeForMacro;
            if (0 < preProcDirectiveRange.length) {
                if ([delegate respondsToSelector:@selector(consumeMacro:inRange:)]) {
                    [delegate consumeMacro:_processingLine inRange:preProcDirectiveRange];
                }
            } else {

            }
        }
    }

    /*
     Other components like operands or label are colored in other ways.
     */

    return YES;
}


#pragma mark - private methods


- (NSRange)rangeForComments:(BOOL *)isBlockComment
{
    /*
     full line comments
     */
    if (0 >= _processingLineComponents.count) {
        *isBlockComment = YES;
        return NSMakeRange(0, _processingLine.length);
    }

    /*
     inline comments
     */
    NSData *commentComponent = [_processingLineComponents objectAtIndex:3];
    if ([[NSNull null] isNotEqualTo:commentComponent] && 0 < commentComponent.length) {
        NSRange commentRange;
        commentRange.length = commentComponent.length + 1;
        commentRange.location = _processingLine.length - commentRange.length;
        *isBlockComment = NO;
        return commentRange;
    }

    return NSMakeRange(NSNotFound, 0);
}


- (NSRange)rangeForPreProcDirective:(nonnull BOOL *)hasParameter
{
    if (0 >= _processingLineComponents.count) {
        return NSMakeRange(NSNotFound, 0);
    }

    NSData *mnemonicComponent = [_processingLineComponents objectAtIndex:1];
    if (nil == mnemonicComponent || 0 >= mnemonicComponent.length) {
        return NSMakeRange(NSNotFound, 0);
    }

    NSString *mnemonic = [[NSString alloc] initWithData:mnemonicComponent encoding:NSUTF8StringEncoding];
    if ([_directivesPreProc0 containsObject:mnemonic]) {
        NSRange mnemonicRange = [_processingLine rangeOfString:mnemonic options:NSCaseInsensitiveSearch];
        *hasParameter = NO;
        return mnemonicRange;
    }
    if ([_directivesPreProc1 containsObject:mnemonic]) {
        NSRange mnemonicRange = [_processingLine rangeOfString:mnemonic options:NSCaseInsensitiveSearch];
        *hasParameter = YES;
        return mnemonicRange;
    }

    return NSMakeRange(NSNotFound, 0);
}


- (NSRange)rangeForDirectiveWithData
{
    if (0 >= _processingLineComponents.count) {
        return NSMakeRange(NSNotFound, 0);
    }

    NSData *directiveComponent = [_processingLineComponents objectAtIndex:1];
    if (nil == directiveComponent || 0 >= directiveComponent.length) {
        return NSMakeRange(NSNotFound, 0);
    }

    NSString *directive = [[NSString alloc] initWithData:directiveComponent encoding:NSUTF8StringEncoding];
    if ([_directivesWithData containsObject:directive]) {
        NSRange directiveRange = [_processingLine rangeOfString:directive options:NSCaseInsensitiveSearch];
        return directiveRange;
    }

    return NSMakeRange(NSNotFound, 0);
}


- (NSRange)rangeForMacro
{
    if (0 >= _processingLineComponents.count) {
        return NSMakeRange(NSNotFound, 0);
    }

    NSData *mnemonicComponent = [_processingLineComponents objectAtIndex:1];
    if (nil == mnemonicComponent || 0 >= mnemonicComponent.length) {
        return NSMakeRange(NSNotFound, 0);
    }

    NSString *mnemonic = [[NSString alloc] initWithData:mnemonicComponent encoding:NSUTF8StringEncoding];
    if ([mnemonic hasPrefix:@"."] && ![_directivesPreProc0 containsObject:mnemonic] && ![_directivesPreProc1 containsObject:mnemonic]) {
        NSRange mnemonicRange = [_processingLine rangeOfString:mnemonic options:NSCaseInsensitiveSearch];
        return mnemonicRange;
    }

    return NSMakeRange(NSNotFound, 0);
}


- (NSRange)rangeForFilename
{
    if (0 >= _processingLineComponents.count) {
        return NSMakeRange(NSNotFound, 0);
    }

    NSArray<NSData *> *operands = [_processingLineComponents objectAtIndex:2];
    NSString *firstOperand = [[NSString alloc] initWithData:operands.firstObject encoding:NSUTF8StringEncoding];

    NSString *filename = [_parser filename:firstOperand error:nil];
    if (nil == filename) {
        NSLog(@"No filename for placeholder \"%@\" found!", firstOperand);
        return NSMakeRange(NSNotFound, 0);
    }
    firstOperand = filename;

    NSRange filenameRange = [_processingLine rangeOfString:firstOperand options:NSCaseInsensitiveSearch];

    return filenameRange;
}


- (NSRange)rangeForText:(BOOL *)isStringLiteral
{
    if (0 >= _processingLineComponents.count) {
        return NSMakeRange(NSNotFound, 0);
    }

    NSArray<NSData *> *operands = [_processingLineComponents objectAtIndex:2];

    NSString *firstOperand = [[NSString alloc] initWithData:operands.firstObject encoding:NSUTF8StringEncoding];
    NSString *lastOperand = (operands.firstObject == operands.lastObject)? firstOperand : [[NSString alloc] initWithData:operands.lastObject encoding:NSUTF8StringEncoding];
    /* this is a workaround for a buggy Python parser */
    if (0 >= lastOperand.length) {
        lastOperand = firstOperand;
    }

    *isStringLiteral = ![lastOperand hasPrefix:@">"];
    NSString *value = *isStringLiteral? [_parser literalForPlaceholder:lastOperand] : [_parser text:lastOperand error:nil];
    if (nil == value) {
        NSLog(@"Operand \"%@\" is syntactical incorrect!", lastOperand);
        return NSMakeRange(NSNotFound, 0);
    }
    if (*isStringLiteral) {
        if (firstOperand == lastOperand) {
            firstOperand = value;
        }
        lastOperand = value;
    }

    NSRange textRange = [_processingLine rangeOfString:firstOperand options:NSCaseInsensitiveSearch];

    return textRange;
}


- (NSRange)rangeForLiteral
{
    if (0 >= _processingLineComponents.count) {
        return NSMakeRange(NSNotFound, 0);
    }

    NSArray<NSData *> *operands = [_processingLineComponents objectAtIndex:2];

    NSString *firstOperand = [[NSString alloc] initWithData:operands.firstObject encoding:NSUTF8StringEncoding];
    NSString *lastOperand = (operands.firstObject == operands.lastObject)? firstOperand : [[NSString alloc] initWithData:operands.lastObject encoding:NSUTF8StringEncoding];
    /* this is a workaround for a buggy Python parser */
    if (0 >= lastOperand.length) {
        lastOperand = firstOperand;
    }

    NSString *literal = [_parser literalForPlaceholder:lastOperand];
    if (nil == literal) {
        NSLog(@"No literal for placeholder \"%@\" found!", lastOperand);
        return NSMakeRange(NSNotFound, 0);
    }
    if (firstOperand == lastOperand) {
        firstOperand = literal;
    }
    lastOperand = literal;

    NSRange operandsRange = [_processingLine rangeOfString:lastOperand options:NSCaseInsensitiveSearch];
    /* this is for a buggy (GPL-)Assembler parser when operands comming from splitLine: cannot be found in the line of code. */
    if (NSNotFound > operandsRange.location) {
        if (firstOperand != lastOperand) {
            NSUInteger operandsEndLocation = operandsRange.location + operandsRange.length;
            operandsRange = [_processingLine rangeOfString:firstOperand options:NSCaseInsensitiveSearch];
            operandsRange.length = operandsEndLocation - operandsRange.location;
        }
        return operandsRange;
    } else {
        NSLog(@"%@ is not found in the line \"%@\"", lastOperand, _processingLine);
    }

    return NSMakeRange(NSNotFound, 0);
}


- (NSRange)rangeForLabelDefinition
{
    if (0 >= _processingLineComponents.count) {
        return NSMakeRange(NSNotFound, 0);
    }

    NSData *labelComponent = [_processingLineComponents objectAtIndex:0];
    if (nil != labelComponent && 0 < labelComponent.length) {
        NSString *label = [[NSString alloc] initWithData:labelComponent encoding:NSUTF8StringEncoding];
        NSRange labelRange = [_processingLine rangeOfString:label options:NSCaseInsensitiveSearch];
        return labelRange;
    }

    return NSMakeRange(NSNotFound, 0);
}


- (void)enumerateRangesForLabelReferencesWithBlock:(void (^)(NSRange labelReferenceRange))block
{
    if (2 >= _processingLineComponents.count) {
        return;
    }

    NSArray<NSData *> *labelReferences = [_processingLineComponents objectAtIndex:2];
    [labelReferences enumerateObjectsUsingBlock:^(NSData *labelRef, NSUInteger idx, BOOL *stop) {
        NSString *labelReference = [[NSString alloc] initWithData:labelRef encoding:NSUTF8StringEncoding];
        /* this is a workaround for a buggy Python parser */
        if (nil == labelReference || 0 >= labelReference.length) {
            return;
        }

        NSString *label = [self->_parser literalForPlaceholder:labelReference];
        if (nil == label) {
            label = labelReference;
        }

        NSRange offsetRange = [label rangeOfString:@"@" options:NSCaseInsensitiveSearch];
        if (offsetRange.location == NSNotFound) {
            offsetRange.location = 0;
        }
        if (![self->_symbolList containsObject:[label substringFromIndex:NSMaxRange(offsetRange)]]) {
            return;
        }

        NSRange labelRange = [self->_processingLine rangeOfString:label options:NSCaseInsensitiveSearch
                                                            range:NSMakeRange(1, self->_processingLine.length-1)];
        if (0 < labelRange.length) {
            block(labelRange);
        }
    }];
}


- (void)enumerateRangesForLiteralsWithBlock:(void (^)(NSRange literalRange))block
{
    if (2 >= _processingLineComponents.count) {
        return;
    }

    NSArray<NSData *> *operands = [_processingLineComponents objectAtIndex:2];

    [operands enumerateObjectsUsingBlock:^(NSData *operand, NSUInteger idx, BOOL *stop) {
        NSString *firstOperand = [[NSString alloc] initWithData:operand encoding:NSUTF8StringEncoding];
        /* this is a workaround for a buggy Python parser */
        if (nil == firstOperand || 0 >= firstOperand.length) {
            return;
        }

        NSString *literal = [self->_parser literalForPlaceholder:firstOperand];
        if (nil == literal) {
            literal = firstOperand;
        }

        NSRange offsetRange = [literal rangeOfString:@"@" options:NSCaseInsensitiveSearch];
        if (offsetRange.location == NSNotFound) {
            offsetRange.location = 0;
        }
        if ([self->_symbolList containsObject:[literal substringFromIndex:NSMaxRange(offsetRange)]]) {
            return;
        }

        NSRange literalRange = [self->_processingLine rangeOfString:literal options:NSCaseInsensitiveSearch
                                                              range:NSMakeRange(1, self->_processingLine.length-1)];
        if (0 < literalRange.length) {
            block(literalRange);
        }
    }];
}

@end
