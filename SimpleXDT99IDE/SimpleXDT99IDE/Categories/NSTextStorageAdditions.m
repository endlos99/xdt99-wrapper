//
//  NSTextStorageAdditions.m
//  SimpleXDT99IDE
//
//  Created by Henrik on 01.07.19.
//  Copyright © 2019 hackmac. All rights reserved.
//

#import "NSTextStorageAdditions.h"


@implementation NSTextStorage (NSTextStorageAdditions)

- (void)enumerateLines:(NSIndexSet *)lineNumbers usingBlock:(void (^)(NSRange lineRange, NSUInteger lineNumber, BOOL *stop))block
{
    if (0 >= lineNumbers.count) {
        return;
    }

    __block NSUInteger enumeratedLineNumber = 0;
    [self.mutableString enumerateSubstringsInRange:NSMakeRange(0, self.length)
                                           options:NSStringEnumerationByLines + NSStringEnumerationSubstringNotRequired
                                        usingBlock:^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {
                                            if ([lineNumbers containsIndex:++enumeratedLineNumber]) {
                                                block(enclosingRange, enumeratedLineNumber, stop);
                                            }
                                        }];
}


- (void)enumerateLinesUsingBlock:(void (^)(NSRange lineRange, NSUInteger lineNumber, BOOL *stop))block
{
    __block NSUInteger enumeratedLineNumber = 0;
    [self.mutableString enumerateSubstringsInRange:NSMakeRange(0, self.length)
                                           options:NSStringEnumerationByLines + NSStringEnumerationSubstringNotRequired
                                        usingBlock:^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {
                                            block(enclosingRange, ++enumeratedLineNumber, stop);
                                        }];
}

@end
