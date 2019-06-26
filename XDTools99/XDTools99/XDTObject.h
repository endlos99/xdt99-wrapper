//
//  XDTObject.h
//  XDTools99
//
//  Created by Henrik Wedekind on 05.12.16.
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

#import <Foundation/Foundation.h>


#define XDTErrorDomain @"XDTErrorDomain"

typedef NS_ENUM(NSInteger, XDTErrorCode) {
    XDTErrorCodeToolLoggedError = 0,
    XDTErrorCodeToolException = 1,
    XDTErrorCodePythonError = 2,
    XDTErrorCodePythonException = 3,
};


@protocol XDTParserProtocol <NSObject>

/**
 Set the source code where the parser works on.
 */
- (void)setSource:(NSString *)source;

/**
 Subclasses needts to overwrite this method!
 This Method will be called from \p openNestedFiles: before it loads and opens new documents.

 @return    A non nullable set of URL of files this document needs to include.

 Default implementation retruns an empty list.
 */
- (NSOrderedSet<NSURL *> *)includedFiles:(NSError **)error;

@end


@interface XDTObject : NSObject

+ (void)reinitializeWithXDTModulePath:(NSString *)modulePath;

@end
