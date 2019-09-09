//
//  NSTextStorageAdditions.h
//  SimpleXDT99IDE
//
//  Created by Henrik on 01.07.19.
//  Copyright © 2019 hackmac. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSTextStorage (NSTextStorageAdditions)

/**
 Enumerates the lines of the text storage for the specified set of line numbers.

 @param lineNumbers A set of line numbers for that the specified block will be executed.
 @param block       The block executed for the enumeration.\n
    The block takes three arguments:\n
    lineRange\n
        The range of the enumerated line whithin the the receiver.\n
    lineNumber\n
        The line number of the enumerated line. Line numbers are counting started at 1. 0 is not a valid line number.\n
    stop\n
        A reference to a Boolean value that the block can use to stop the enumeration by setting *stop = YES; it should not touch *stop otherwise.
 */
- (void)enumerateLines:(NSIndexSet *)lineNumbers usingBlock:(void (^)(NSRange lineRange, NSUInteger lineNumber, BOOL *stop))block;

/**
 Enumerates the lines of the text storage for all lines.

 @param block       The block executed for the enumeration.\n
    The block takes three arguments:\n
    lineRange\n
        The range of the enumerated line whithin the the receiver.\n
    lineNumber\n
        The line number of the enumerated line. Line numbers are counting started at 1. 0 is not a valid line number.\n
    stop\n
        A reference to a Boolean value that the block can use to stop the enumeration by setting *stop = YES; it should not touch *stop otherwise.
 */
- (void)enumerateLinesUsingBlock:(void (^)(NSRange lineRange, NSUInteger lineNumber, BOOL *stop))block;

/**
 */
- (NSRange)rangeForLineNumber:(NSUInteger)lineNumber;

/**
 */
- (NSRange)lineNumberRangeForTextRange:(NSRange)textRange;

@end

NS_ASSUME_NONNULL_END
