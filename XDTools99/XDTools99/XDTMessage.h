//
//  XDTMessage.h
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

#import <Foundation/Foundation.h>

#import <Python/Python.h>


typedef NS_ENUM(NSUInteger, XDTMessageTypeValue) {
    XDTMessageTypeAll,
    XDTMessageTypeException,    /* currently not used */
    XDTMessageTypeError,
    XDTMessageTypeWarning,
    XDTMessageTypeInfo,         /* currently not used */
    XDTMessageTypeDebug,        /* currently not used */
};


NS_ASSUME_NONNULL_BEGIN

typedef NSString * XDTMessageTypeKey NS_EXTENSIBLE_STRING_ENUM; /* Keys for use in the NSDictionry */

FOUNDATION_EXPORT XDTMessageTypeKey const XDTMessageFileURL;    /* The source file of type NSURL */
FOUNDATION_EXPORT XDTMessageTypeKey const XDTMessagePassNumber; /* Number of the Assembler pass as an unsigned integer of type NSNumber */
FOUNDATION_EXPORT XDTMessageTypeKey const XDTMessageLineNumber; /* The line number of the source file, an unsigned integer of type NSNumber */
FOUNDATION_EXPORT XDTMessageTypeKey const XDTMessageCodeLine;   /* The text of the line of code pointed by the line number as NSString */
FOUNDATION_EXPORT XDTMessageTypeKey const XDTMessageText;       /* Text of the message, any error or warning messages as NSString */
FOUNDATION_EXPORT XDTMessageTypeKey const XDTMessageType;       /* Kind of message: XDTMessageTypeValue NSNumber */

typedef void (^XDTMessageEnumBlock)(NSDictionary<XDTMessageTypeKey, id> *obj, BOOL *stop);


@interface XDTMessage : NSObject

+ (instancetype)messageWithPythonList:(PyObject *)messageList;
+ (instancetype)messageWithPythonList:(PyObject *)messageList treatingAs:(XDTMessageTypeValue)type;
+ (instancetype)messageWithMessages:(XDTMessage *)messages;

- (XDTMessage *)messagesOfType:(XDTMessageTypeValue)type;
- (XDTMessage *)sortedByPriorityAscendingType;
- (XDTMessage *)sortedByPriorityDecendingType;

@property (readonly) NSUInteger count;
- (NSUInteger)countOfType:(XDTMessageTypeValue)type;

- (void)enumerateMessagesUsingBlock:(NS_NOESCAPE XDTMessageEnumBlock)block;
- (void)enumerateMessagesOfType:(XDTMessageTypeValue)type usingBlock:(NS_NOESCAPE XDTMessageEnumBlock)block;

@end


@interface XDTMutableMessage : XDTMessage

- (void)addMessages:(XDTMessage *)messages;
- (void)replaceMessagesOfType:(XDTMessageTypeValue)type withMessagesOfSameType:(XDTMessage * _Nullable)messages;

- (void)sortByPriorityAscendingType;
- (void)sortByPriorityDecendingType;

@end

NS_ASSUME_NONNULL_END
