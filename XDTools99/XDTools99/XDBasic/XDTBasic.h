//
//  XDTBasic.h
//  XDTools99
//
//  Created by Henrik Wedekind on 12.12.16.
//
//  XDTools99.framework a collection of Objective-C wrapper for xdt99
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

#import "XDTObject.h"


#define XDTBasicOptionJoinLines @"XDTBasicOptionJoinLines"
#define XDTBasicOptionProtectFile @"XDTBasicOptionProtectFile"
#define XDTBasicOptionTarget @"XDTBasicOptionTarget"

#define XDTBasicVersionRequired "1.5.0"


typedef NSUInteger XDTBasicTargetType;
NS_ENUM(XDTBasicTargetType) {
    XDTBasicTargetTypeInternalFormat,   /* TI (Extended) Basic internal format used with OLD, SAVE, RUN */
    XDTBasicTargetTypeLongFormat,       /* Long Format */
    XDTBasicTargetTypeMergeFormat,      /* Merge Format, not supported by xbas99 */
};


NS_ASSUME_NONNULL_BEGIN
@interface XDTBasic : XDTObject

@property (readonly) NSString *version;
@property (readonly) BOOL join;
@property (readonly) BOOL protect;
@property (readonly) XDTBasicTargetType targetType;

/*
 Returns a structure which contains for each entry the basic line number (key of the dictionary) 
 and the Basic tokens (value of the dictionary) that belongs to that line.
 */
@property (nullable,readonly) NSDictionary<NSNumber *, NSArray *> *lines;
@property (nullable,readonly) NSArray<NSString *> *warnings;

+ (BOOL)checkRequiredModuleVersion;

+ (nullable instancetype)basicWithOptions:(NSDictionary<NSString *, NSObject *> *)options;

/* Program to source code conversion */
- (BOOL)loadProgramData:(NSData *)data error:(NSError **)error; // load tokenized BASIC program in internal format
- (BOOL)loadLongData:(NSData *)data error:(NSError **)error;    // load tokenized BASIC program in long format
- (BOOL)loadMergedData:(NSData *)data error:(NSError **)error;  // load tokenized BASIC program in merge format

- (nullable NSString *)getSource:(NSError **)error;    // textual representation of token sequence

/* Source code to program conversion */
- (BOOL)parseSourceCode:(NSString *)sourceCode error:(NSError **)error;  // parse and tokenize BASIC source code

- (BOOL)saveProgramFormatFile:(NSURL *)fileURL error:(NSError **)error;
- (BOOL)saveLongFormatFile:(NSURL *)fileURL error:(NSError **)error;
- (BOOL)saveMergedFormatFile:(NSURL *)fileURL error:(NSError **)error;

- (nullable NSString *)dumpTokenList:(NSError **)error;

@end
NS_ASSUME_NONNULL_END
