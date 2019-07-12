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

#import <Python/Python.h>

#import "NSSetPythonAdditions.h"


NS_ASSUME_NONNULL_BEGIN

XDTMessageTypeKey const XDTMessageFileURL = @"XDTMessageFileURL";
XDTMessageTypeKey const XDTMessagePassNumber = @"XDTMessagePassNumber";
XDTMessageTypeKey const XDTMessageLineNumber = @"XDTMessageLineNumber";
XDTMessageTypeKey const XDTMessageCodeLine = @"XDTMessageCodeLine";
XDTMessageTypeKey const XDTMessageText = @"XDTMessageText";
XDTMessageTypeKey const XDTMessageType = @"XDTMessageType";


static NSArray<NSSortDescriptor *> *sortDescriptorsAscendingType;
static NSArray<NSSortDescriptor *> *sortDescriptorsDecendingType;


@interface XDTMessage () {
    @protected
    NSMutableOrderedSet<NSDictionary<XDTMessageTypeKey, id> *> *_messages;
    NSArray<NSSortDescriptor *> *_usedSortDescriptors;
}

- (instancetype)initWithSet:(NSOrderedSet<NSDictionary<XDTMessageTypeKey, id> *> *)messageArray;

+ (NSDictionary<XDTMessageTypeKey, id> *)createMessageElement:(NSArray<id> *)messageTupel;

- (instancetype)sortedUsingDescriptior:(NSArray<NSSortDescriptor *> *)descriptor;

@end

NS_ASSUME_NONNULL_END


@implementation XDTMessage

+ (NSString *)pythonClassName
{
    return [NSString stringWithUTF8String:PyList_New(0)->ob_type->tp_name];
}


+ (void)initialize
{
    if (self == [XDTMessage class]) {
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


+ (instancetype)message
{
    PyObject *console = PyList_New(0);
    id retVal = [self messageWithPythonList:console];
    Py_XDECREF(console);
    return retVal;
}


+ (instancetype)messageWithMessages:(XDTMessage *)messages
{
    id retVal = [self.class messageWithPythonList:messages.pythonInstance];
    return [retVal sortedUsingDescriptior:messages->_usedSortDescriptors];
}


+ (instancetype)messageWithPythonList:(PyObject *)messageList
{
    id retVal = [[self.class alloc] initWithPythonList:messageList];
#if !__has_feature(objc_arc)
    return [retVal autorelease];
#else
    return retVal;
#endif
}


- (instancetype)initWithPythonList:(PyObject *)messageList
{
    assert(NULL != messageList);

    self = [super initWithPythonInstance:messageList];
    if (nil == self) {
        return nil;
    }

    _usedSortDescriptors = sortDescriptorsAscendingType;
    _messages = nil;
    [self refresh];

    return self;
}


- (instancetype)initWithSet:(NSOrderedSet<NSDictionary<XDTMessageTypeKey,id> *> *)messageSet
{
    assert(NULL != messageSet);

    self = [super initWithPythonInstance:NULL];
    if (nil == self) {
        return nil;
    }

    _usedSortDescriptors = nil;
    _messages = nil;
    if (0 >= [messageSet count]) {
        return self;
    }
    _messages = [NSMutableOrderedSet orderedSetWithOrderedSet:messageSet];

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


- (instancetype)messagesForLineNumberRange:(NSRange)lineNumberRange
{
    if (0 == lineNumberRange.length) {
        return nil;
    }

    const NSUInteger startLineNumber = lineNumberRange.location;
    const NSUInteger stopLineNumber = NSMaxRange(lineNumberRange);

    NSIndexSet *messageIndexes = [_messages indexesOfObjectsPassingTest:^BOOL(NSDictionary<XDTMessageTypeKey,id> *message, NSUInteger idx, BOOL *stop) {
        NSNumber *lineNumber = [message valueForKey:XDTMessageLineNumber];
        if (nil == lineNumber || [[NSNull null] isEqualTo:lineNumber]) {
            return NO;
        }
        const NSUInteger issueLineNumber = [lineNumber unsignedIntegerValue];
        return issueLineNumber >= startLineNumber && issueLineNumber < stopLineNumber;
    }];

    if (0 == messageIndexes.count) {
        return nil;
    }

    id retVal = [[self.class alloc] initWithSet:[NSOrderedSet orderedSetWithArray:[_messages objectsAtIndexes:messageIndexes]]];
#if !__has_feature(objc_arc)
    return [retVal autorelease];
#else
    return retVal;
#endif
}


- (instancetype)messagesOfType:(XDTMessageTypeValue)type
{
    NSPredicate *p = [NSPredicate predicateWithFormat:@"%K == %d", XDTMessageType, type];
    NSOrderedSet<NSDictionary<XDTMessageTypeKey,id> *> *filtered = [_messages filteredOrderedSetUsingPredicate:p];
    XDTMessage *retVal = [[self.class alloc] initWithSet:filtered];

#if !__has_feature(objc_arc)
    return [retVal autorelease];
#else
    return retVal;
#endif
}


- (instancetype)sortedByPriorityAscendingType
{
    return [self sortedUsingDescriptior:sortDescriptorsAscendingType];
}


- (instancetype)sortedByPriorityDecendingType
{
    return [self sortedUsingDescriptior:sortDescriptorsDecendingType];
}


- (instancetype)sortedUsingDescriptior:(NSArray<NSSortDescriptor *> *)descriptor
{
    if (_usedSortDescriptors == descriptor) {
        XDTMessage *retVal = [[self.class alloc] initWithSet:_messages];
        retVal->_usedSortDescriptors = _usedSortDescriptors;
#if !__has_feature(objc_arc)
        return [retVal autorelease];
#else
        return retVal;
#endif
    }

    NSArray<NSDictionary<XDTMessageTypeKey,id> *> *sorted = [_messages sortedArrayUsingDescriptors:descriptor];
    XDTMessage *retVal = [[self.class alloc] initWithSet:[NSOrderedSet orderedSetWithArray:sorted]];
    retVal->_usedSortDescriptors = descriptor;
#if !__has_feature(objc_arc)
    return [retVal autorelease];
#else
    return retVal;
#endif
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


+ (NSDictionary<XDTMessageTypeKey, id> *)createMessageElement:(NSArray<id> *)messageTuple
{
    NSDictionary<XDTMessageTypeKey, id> *msg = nil;

    NSString *typeString = [[NSString alloc] initWithData:[messageTuple objectAtIndex:0] encoding:NSUTF8StringEncoding].uppercaseString;  /* Message type: E=Error; W=Warning */
    XDTMessageTypeValue typeValue = XDTMessageTypeInfo;
    if ([@"E" isEqualToString:typeString]) {
        typeValue = XDTMessageTypeError;
    } else if ([@"W" isEqualToString:typeString]) {
        typeValue = XDTMessageTypeWarning;
    } else {
        NSLog(@"Warning: unknown message type: %@", typeString);
    }

    NSData *stringData = [messageTuple objectAtIndex:1];
    NSString *fileName = [NSNull.null isEqualTo:stringData]? @"" : [[NSString alloc] initWithData:stringData encoding:NSUTF8StringEncoding];  /* Name of te Source file. */
    NSURL *fileUrl = [NSURL fileURLWithPath:fileName.lastPathComponent relativeToURL:[NSURL fileURLWithPath:fileName.stringByDeletingLastPathComponent isDirectory:YES]];
    NSNumber *passNum = [messageTuple objectAtIndex:2];  /* Number of the Assembler pass. */
    NSNumber *lineNum = [messageTuple objectAtIndex:3];  /* Number of the line in source code. */
    stringData = [messageTuple objectAtIndex:4];
    NSString *sourceLine = [[NSNull null] isEqualTo:stringData]? @"" : [[NSString alloc] initWithData:stringData encoding:NSUTF8StringEncoding];  /* Line of source code where the line number points to. */
    NSString *message = [[NSString alloc] initWithData:[messageTuple objectAtIndex:5] encoding:NSUTF8StringEncoding];  /* Text of the generated message. */

    if (nil == message || 0 >= message.length) {
        NSLog(@"%s ERROR: XDT Message without text!", __FUNCTION__);
    }
    msg = @{
            XDTMessageFileURL: (nil == fileUrl)? NSNull.null : fileUrl,
            XDTMessagePassNumber: passNum,
            XDTMessageLineNumber: (nil == lineNum)? NSNull.null : lineNum,
            XDTMessageCodeLine: (nil == sourceLine)? @"" : sourceLine,
            XDTMessageText: (nil == message || 0 >= message.length)? NSNull.null : message,
            XDTMessageType: [NSNumber numberWithUnsignedInteger:typeValue]
            };
    return msg;
}


- (void)refresh
{
    /* Check if the messageList comes from xbas99, which delivers its messages in an array of strings, not an array of tuples like the other does. */
    NSSet<NSArray<id> *> *listOfMessageTupel = [NSSet setWithPythonListOfTuple:self.pythonInstance];
    const Py_ssize_t messageCount = PyList_Size(self.pythonInstance);
    if (0 >= messageCount || nil == listOfMessageTupel) {
        [_messages removeAllObjects];
        return;
    }

    NSMutableOrderedSet<NSDictionary<XDTMessageTypeKey, id> *> *newMessages = [NSMutableOrderedSet orderedSetWithCapacity:messageCount];
    [listOfMessageTupel enumerateObjectsUsingBlock:^(NSArray<id> *messageTupel, BOOL *stop) {
        NSDictionary<XDTMessageTypeKey, id> *msg = [self.class createMessageElement:messageTupel];
        [newMessages addObject:msg];
    }];
    _messages = newMessages;
    [_messages sortUsingDescriptors:_usedSortDescriptors];
}


- (NSEnumerator<NSDictionary<XDTMessageTypeKey, id> *> *)objectEnumerator
{
    if (_usedSortDescriptors != sortDescriptorsAscendingType) {
        [_messages sortUsingDescriptors:sortDescriptorsAscendingType];
        _usedSortDescriptors = sortDescriptorsAscendingType;
    }
    return _messages.objectEnumerator;
}


- (NSEnumerator<NSDictionary<XDTMessageTypeKey, id> *> *)reverseObjectEnumerator
{
    if (_usedSortDescriptors != sortDescriptorsDecendingType) {
        [_messages sortUsingDescriptors:sortDescriptorsDecendingType];
        _usedSortDescriptors = sortDescriptorsDecendingType;
    }
    return _messages.reverseObjectEnumerator;
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
    // TODO: update the underlying Python data!
    [self willChangeValueForKey:NSStringFromSelector(@selector(count))];
    [_messages unionOrderedSet:messages->_messages];
    [self didChangeValueForKey:NSStringFromSelector(@selector(count))];
}


- (void)replaceMessagesOfType:(XDTMessageTypeValue)type withMessagesOfSameType:(XDTMessage *)messages
{
    // TODO: update the underlying Python data!
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
