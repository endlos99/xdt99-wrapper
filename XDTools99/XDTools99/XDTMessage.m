//
//  XDTMessage.m
//  XDTools99
//
//  Created by Henrik Wedekind on 19.06.19.
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

#import "XDTMessage.h"

#import "NSSetPythonAdditions.h"


NS_ASSUME_NONNULL_BEGIN

XDTMessageTypeKey const XDTMessageFileURL = @"XDTMessageFileURL";
XDTMessageTypeKey const XDTMessagePassNumber = @"XDTMessagePassNumber";
XDTMessageTypeKey const XDTMessageLineNumber = @"XDTMessageLineNumber";
XDTMessageTypeKey const XDTMessageCodeLine = @"XDTMessageCodeLine";
XDTMessageTypeKey const XDTMessageText = @"XDTMessageText";
XDTMessageTypeKey const XDTMessageType = @"XDTMessageType";


static NSRegularExpression *warningRegex;
static NSRegularExpression *errorRegex;
static NSRegularExpression *basicRegex;

static NSArray<NSSortDescriptor *> *sortDescriptorsAscendingType;
static NSArray<NSSortDescriptor *> *sortDescriptorsDecendingType;


@interface XDTMessage () {
    @protected
    NSMutableOrderedSet<NSDictionary<XDTMessageTypeKey, id> *> *_messages;
    NSArray<NSSortDescriptor *> *_usedSortDescriptors;
}

- (instancetype)initWithPythonList:(PyObject *)messageList treatingAs:(XDTMessageTypeValue)type;
- (instancetype)initWithSet:(NSOrderedSet<NSDictionary<XDTMessageTypeKey, id> *> *)messageArray;

@end

NS_ASSUME_NONNULL_END


@implementation XDTMessage

+ (void)initialize
{
    if (self == [XDTMessage class]) {
        /*
         > test﻿.asm <2> 0004 - Warning: Treating as register﻿, did you intend an﻿ @address﻿﻿﻿﻿﻿﻿?
         */
        warningRegex = [NSRegularExpression regularExpressionWithPattern:@">\\s(.+)\\s<(\\d+)>\\s(\\d{4})\\s-\\sWarning:\\s(.+)\n" options:0 error:nil];
        /*
         > gaops.gpl <1> 0028 -         STx   @>8391,@>8302
         ***** Syntax error
         */
        errorRegex = [NSRegularExpression regularExpressionWithPattern:@">\\s(.+)\\s<(\\d+)>\\s(\\d{4})\\s-\\s(.+)\n(.*)\n" options:0 error:nil];
        /*
         Missing line number: [15] GOTO 500
         */
        basicRegex = [NSRegularExpression regularExpressionWithPattern:@"(.+):\\s\\[(\\d+)\\]\\s(.*)" options:0 error:nil];
        sortDescriptorsAscendingType = @[
                                         [NSSortDescriptor sortDescriptorWithKey:[NSString stringWithFormat:@"self.%@.path", XDTMessageFileURL] ascending:YES],
                                         [NSSortDescriptor sortDescriptorWithKey:XDTMessageLineNumber ascending:YES],
                                         [NSSortDescriptor sortDescriptorWithKey:XDTMessagePassNumber ascending:YES],
                                         [NSSortDescriptor sortDescriptorWithKey:XDTMessageType ascending:YES],
                                         ];
        sortDescriptorsDecendingType = @[
                                         [NSSortDescriptor sortDescriptorWithKey:[NSString stringWithFormat:@"self.%@.path", XDTMessageFileURL] ascending:YES],
                                         [NSSortDescriptor sortDescriptorWithKey:XDTMessageLineNumber ascending:YES],
                                         [NSSortDescriptor sortDescriptorWithKey:XDTMessagePassNumber ascending:YES],
                                         [NSSortDescriptor sortDescriptorWithKey:XDTMessageType ascending:NO],
                                         ];
    }
}


+ (instancetype)messageWithPythonList:(PyObject *)messageList
{
    return [self messageWithPythonList:messageList treatingAs:XDTMessageTypeAll];
}


+ (instancetype)messageWithPythonList:(PyObject *)messageList treatingAs:(XDTMessageTypeValue)type
{
    id retVal = [[[self class] alloc] initWithPythonList:messageList treatingAs:type];
#if !__has_feature(objc_arc)
    return [retVal autorelease];
#else
    return retVal;
#endif
}


- (instancetype)initWithPythonList:(PyObject *)messageList treatingAs:(XDTMessageTypeValue)treatingType
{
    assert(NULL != messageList);

    self = [super init];
    if (nil == self) {
        return nil;
    }

    _messages = nil;
    const Py_ssize_t messageCount = PyList_Size(messageList);
    if (0 >= messageCount) {
        return self;
    }

    /* Check if the messageList comes from xbas99, which delivers its messages in an array of strings, not an array of tuples like the other does. */
    NSMutableOrderedSet<NSDictionary<XDTMessageTypeKey, id> *> *newMessages = [NSMutableOrderedSet orderedSetWithCapacity:messageCount];
    NSSet<NSString *> *messageStrings = [NSSet setWithPythonListOfString:messageList];
    if (nil != messageStrings && 0 < messageStrings.count) {
        // I'm still the old and ugly style of message exchange, that xbas99 still uses.
        [messageStrings enumerateObjectsUsingBlock:^(NSString *obj, BOOL *stop) {
            NSDictionary<XDTMessageTypeKey, id> *msg = nil;

            NSRange range = NSMakeRange(0, [obj length]);
            NSTextCheckingResult *match = [warningRegex firstMatchInString:obj options:0 range:range];
            if (nil != match) {
                /* Assembler warnings */
                msg = @{
                        XDTMessageFileURL: [NSURL fileURLWithPath:[obj substringWithRange:[match rangeAtIndex:1]]],
                        XDTMessagePassNumber: [NSNumber numberWithUnsignedInteger:[[obj substringWithRange:[match rangeAtIndex:2]] integerValue]],
                        XDTMessageLineNumber: [NSNumber numberWithUnsignedInteger:[[obj substringWithRange:[match rangeAtIndex:3]] integerValue]],
                        //XDTMessageCodeLine:nil;
                        XDTMessageText: [obj substringWithRange:[match rangeAtIndex:4]],
                        XDTMessageType: [NSNumber numberWithUnsignedInteger:(XDTMessageTypeAll != treatingType)? treatingType : XDTMessageTypeWarning]
                        };
            } else {
                match = [errorRegex firstMatchInString:obj options:0 range:range];
                if (nil != match) {
                    /* Assembler errors */
                    msg = @{
                            XDTMessageFileURL: [NSURL fileURLWithPath:[obj substringWithRange:[match rangeAtIndex:1]]],
                            XDTMessagePassNumber: [NSNumber numberWithUnsignedInteger:[[obj substringWithRange:[match rangeAtIndex:2]] integerValue]],
                            XDTMessageLineNumber: [NSNumber numberWithUnsignedInteger:[[obj substringWithRange:[match rangeAtIndex:3]] integerValue]],
                            XDTMessageCodeLine: [obj substringWithRange:[match rangeAtIndex:4]],
                            XDTMessageText: [obj substringWithRange:[match rangeAtIndex:5]],
                            XDTMessageType: [NSNumber numberWithUnsignedInteger:(XDTMessageTypeAll != treatingType)? treatingType : XDTMessageTypeError]
                            };
                } else {
                    /* Basic warnings */
                    match = [basicRegex firstMatchInString:obj options:0 range:range];
                    if (nil != match) {
                        msg = @{
                                //XDTMessageFileURL: nil,
                                //XDTMessagePassNumber: nil,
                                XDTMessageLineNumber: [NSNumber numberWithUnsignedInteger:[[obj substringWithRange:[match rangeAtIndex:2]] integerValue] + 1],
                                XDTMessageCodeLine: [obj substringWithRange:[match rangeAtIndex:3]],
                                XDTMessageText: [obj substringWithRange:[match rangeAtIndex:1]],
                                XDTMessageType: [NSNumber numberWithUnsignedInteger:(XDTMessageTypeAll != treatingType)? treatingType : XDTMessageTypeWarning]
                                };
                    } else {
                        /* old school style of Assembler warnings */
                        msg = @{
                                //XDTMessageFileURL: nil,
                                XDTMessagePassNumber: @2,
                                //XDTMessageLineNumber: nil,
                                //XDTMessageCodeLine: @"",
                                XDTMessageText: obj,
                                XDTMessageType: [NSNumber numberWithUnsignedInteger:(XDTMessageTypeAll != treatingType)? treatingType : XDTMessageTypeError]
                                };
                    }
                }
            }
            [newMessages addObject:msg];
        }];
    } else {
        NSSet<NSArray *> *messageTupel = [NSSet setWithPythonListOfTuple:messageList];
        [messageTupel enumerateObjectsUsingBlock:^(NSArray *messageItem, BOOL *stop) {
            NSDictionary<XDTMessageTypeKey, id> *msg = nil;

            NSString *typeString = [[NSString alloc] initWithData:[messageItem objectAtIndex:0] encoding:NSUTF8StringEncoding].uppercaseString;  /* Message type: E=Error; W=Warning */
            XDTMessageTypeValue typeValue = treatingType;
            if (XDTMessageTypeAll == treatingType) {
                if ([@"E" isEqualToString:typeString]) {
                    typeValue = XDTMessageTypeError;
                } else if ([@"W" isEqualToString:typeString]) {
                    typeValue = XDTMessageTypeWarning;
                } else {
                    NSLog(@"Warning: unknown message type: %@", typeString);
                }
            }

            NSData *stringData = [messageItem objectAtIndex:1];
            NSString *fileName = [[NSNull null] isEqual:stringData]? @"" : [[NSString alloc] initWithData:stringData encoding:NSUTF8StringEncoding];  /* Name of te Source file. */
            NSNumber *passNum = [messageItem objectAtIndex:2];  /* Number of the Assembler pass. */
            NSNumber *lineNum = [messageItem objectAtIndex:3];  /* Number of the line in source code. */
            stringData = [messageItem objectAtIndex:4];
            NSString *sourceLine = [[NSNull null] isEqualTo:stringData]? @"" : [[NSString alloc] initWithData:stringData encoding:NSUTF8StringEncoding];  /* Line of source code where the line number points to. */
            NSString *message = [[NSString alloc] initWithData:[messageItem objectAtIndex:5] encoding:NSUTF8StringEncoding];  /* Text of the generated message. */

            if (nil == message || 0 >= message.length) {
                NSLog(@"Warning: XDT Message without text!");
                return;
            }
            msg = @{
                    XDTMessageFileURL: [NSURL fileURLWithPath:fileName],
                    XDTMessagePassNumber: passNum,
                    XDTMessageLineNumber: (nil == lineNum)? [NSNull null] : lineNum,
                    XDTMessageCodeLine: (nil == sourceLine)? @"" : sourceLine,
                    XDTMessageText: message,
                    XDTMessageType: [NSNumber numberWithUnsignedInteger:typeValue]
                    };
            [newMessages addObject:msg];
        }];
    }
    _messages = newMessages;
    _usedSortDescriptors = nil;

    return self;
}


+ (instancetype)messageWithMessages:(XDTMessage *)messages
{
    XDTMessage *retVal = [[XDTMessage alloc] init];
    retVal->_messages = [NSMutableOrderedSet orderedSetWithOrderedSet:messages->_messages];
    retVal->_usedSortDescriptors = messages->_usedSortDescriptors;
    return retVal;
}


- (instancetype)initWithSet:(NSOrderedSet<NSDictionary<XDTMessageTypeKey,id> *> *)messageSet
{
    assert(NULL != messageSet);

    self = [super init];
    if (nil == self) {
        return nil;
    }

    _messages = nil;
    if (0 >= [messageSet count]) {
        return self;
    }
    _messages = [NSMutableOrderedSet orderedSetWithOrderedSet:messageSet];
    _usedSortDescriptors = nil;

    return self;
}


- (void)dealloc
{
    //Py_CLEAR(objectcodePythonClass);
#if !__has_feature(objc_arc)
    [_messages release];
    [super dealloc];
#endif
}


#pragma mark - Accessor Methods


- (XDTMessage *)messagesOfType:(XDTMessageTypeValue)type
{
    NSPredicate *p = [NSPredicate predicateWithFormat:@"%K == %d", XDTMessageType, type];
    NSOrderedSet<NSDictionary<XDTMessageTypeKey,id> *> *filtered = [_messages filteredOrderedSetUsingPredicate:p];
    XDTMessage *retVal = [[XDTMessage alloc] initWithSet:filtered];
#if !__has_feature(objc_arc)
    [retVal autorelease];
#endif
    return retVal;
}


- (XDTMessage *)sortedByPriorityAscendingType
{
    if (_usedSortDescriptors == sortDescriptorsAscendingType) {
        XDTMessage *retVal = [[XDTMessage alloc] initWithSet:_messages];
#if !__has_feature(objc_arc)
        [retVal autorelease];
#endif
        retVal->_usedSortDescriptors = _usedSortDescriptors;
        return retVal;
    }

    NSArray<NSDictionary<XDTMessageTypeKey,id> *> *sorted = [_messages sortedArrayUsingDescriptors:sortDescriptorsAscendingType];
    XDTMessage *retVal = [[XDTMessage alloc] initWithSet:[NSOrderedSet orderedSetWithArray:sorted]];
#if !__has_feature(objc_arc)
    [retVal autorelease];
#endif
    retVal->_usedSortDescriptors = sortDescriptorsAscendingType;
    return retVal;
}


- (XDTMessage *)sortedByPriorityDecendingType
{
    if (_usedSortDescriptors == sortDescriptorsDecendingType) {
        XDTMessage *retVal = [[XDTMessage alloc] initWithSet:_messages];
#if !__has_feature(objc_arc)
        [retVal autorelease];
#endif
        retVal->_usedSortDescriptors = _usedSortDescriptors;
        return retVal;
    }

    NSArray<NSDictionary<XDTMessageTypeKey,id> *> *sorted = [_messages sortedArrayUsingDescriptors:sortDescriptorsDecendingType];
    XDTMessage *retVal = [[XDTMessage alloc] initWithSet:[NSOrderedSet orderedSetWithArray:sorted]];
#if !__has_feature(objc_arc)
    [retVal autorelease];
#endif
    retVal->_usedSortDescriptors = sortDescriptorsDecendingType;
    return retVal;
}


- (NSUInteger)count
{
    return _messages.count;
}


- (NSUInteger)countOfType:(XDTMessageTypeValue)type
{
    if (XDTMessageTypeAll == type) {
        return _messages.count;
    }

    NSPredicate *p = [NSPredicate predicateWithFormat:@"%K == %d", XDTMessageType, type];
    NSOrderedSet<NSDictionary<XDTMessageTypeKey,id> *> *filtered = [_messages filteredOrderedSetUsingPredicate:p];
    return filtered.count;
}


- (void)enumerateMessagesUsingBlock:(NS_NOESCAPE XDTMessageEnumBlock)block
{
    [_messages enumerateObjectsUsingBlock:^(NSDictionary<XDTMessageTypeKey,id> * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        block(obj, stop);
    }];
}


- (void)enumerateMessagesOfType:(XDTMessageTypeValue)type usingBlock:(NS_NOESCAPE XDTMessageEnumBlock)block
{
    NSPredicate *p = [NSPredicate predicateWithFormat:@"%K == %d", XDTMessageType, type];
    [_messages enumerateObjectsUsingBlock:^(NSDictionary<XDTMessageTypeKey,id> *obj, NSUInteger idx, BOOL *stop) {
        if ([p evaluateWithObject:obj]) {
            block(obj, stop);
        };
    }];
}

@end


#pragma mark - Implementation of class XDTMutableMessage


@implementation XDTMutableMessage

- (void)addMessages:(XDTMessage *)messages
{
    [self willChangeValueForKey:NSStringFromSelector(@selector(count))];
    [_messages unionOrderedSet:messages->_messages];
    [self didChangeValueForKey:NSStringFromSelector(@selector(count))];
}


- (void)replaceMessagesOfType:(XDTMessageTypeValue)type withMessagesOfSameType:(XDTMessage *)messages
{
    NSPredicate *p = [NSPredicate predicateWithFormat:@"%K == %d", XDTMessageType, type];
    NSOrderedSet<NSDictionary<XDTMessageTypeKey,id> *> *messagesOfSameType = [messages->_messages filteredOrderedSetUsingPredicate:p];

    p = [NSPredicate predicateWithFormat:@"%K != %d", XDTMessageType, type];

    [self willChangeValueForKey:NSStringFromSelector(@selector(count))];
    [_messages filterUsingPredicate:p];
    [_messages unionOrderedSet:messagesOfSameType];
    [self didChangeValueForKey:NSStringFromSelector(@selector(count))];
}


- (void)sortByPriorityAscendingType
{
    if (_usedSortDescriptors == sortDescriptorsAscendingType) {
        return;
    }

    [_messages sortUsingDescriptors:sortDescriptorsAscendingType];
    _usedSortDescriptors = sortDescriptorsAscendingType;
}


- (void)sortByPriorityDecendingType
{
    if (_usedSortDescriptors == sortDescriptorsDecendingType) {
        return;
    }

    [_messages sortUsingDescriptors:sortDescriptorsDecendingType];
    _usedSortDescriptors = sortDescriptorsDecendingType;
}

@end
