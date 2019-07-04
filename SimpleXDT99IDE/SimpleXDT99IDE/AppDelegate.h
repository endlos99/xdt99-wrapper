//
//  AppDelegate.h
//  SimpleXDT99
//
//  Created by Henrik Wedekind on 02.12.16.
//
//  SimpleXDT99IDE a simple IDE based on xdt99 that shows how to use the XDTools99.framework
//  Copyright © 2016-2019 Henrik Wedekind (aka hackmac). All rights reserved.
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

#import <Cocoa/Cocoa.h>

#define UserDefaultKeyDocumentOptionOpenNestedFiles @"DocumentOptionOpenNestedFiles"
#define UserDefaultKeyDocumentOptionShowLog @"DocumentOptionShowLog"
#define UserDefaultKeyDocumentOptionShowErrorsInLog @"DocumentOptionShowErrorsInLog"
#define UserDefaultKeyDocumentOptionShowWarningsInLog @"DocumentOptionShowWarningsInLog"
#define UserDefaultKeyDocumentOptionEnableHighlighting @"DocumentOptionEnableHighlighting"
#define UserDefaultKeyDocumentOptionHighlightSyntax @"DocumentOptionHighlightSyntax"
#define UserDefaultKeyDocumentOptionHighlightMessages @"DocumentOptionHighlightMessages"

#define UserDefaultKeyAssemblerOptionOutputTypePopupIndex @"AssemblerOptionOutputFileTypePopupButtonIndex"
#define UserDefaultKeyAssemblerOptionDisableXDTExtensions @"AssemblerOptionDisableXDTExtensions"
#define UserDefaultKeyAssemblerOptionUseRegisterSymbols @"AssemblerOptionUseRegisterSymbols"
#define UserDefaultKeyAssemblerOptionGenerateListOutput @"AssemblerOptionGenerateListOutput"
#define UserDefaultKeyAssemblerOptionGenerateSymbolTable @"AssemblerOptionGenerateSymbolTable"
#define UserDefaultKeyAssemblerOptionGenerateSymbolsAsEqus @"AssemblerOptionGenerateSymbolsAsEqus"
#define UserDefaultKeyAssemblerOptionBaseAddress @"AssemblerOptionBaseAddress"
#define UserDefaultKeyAssemblerOptionTextMode @"AssemblerOptionTextMode"

#define UserDefaultKeyBasicOptionOutputTypePopupIndex @"BasicOptionOutputTypePopupIndex"
#define UserDefaultKeyBasicOptionShouldProtectFile @"BasicOptionShouldProtectFile"
#define UserDefaultKeyBasicOptionShouldJoinSourceLines @"BasicOptionShouldJoinSourceLines"
#define UserDefaultKeyBasicOptionShouldJoinLineDelta @"BasicOptionShouldJoinLineDelta"

#define UserDefaultKeyGPLOptionOutputTypePopupIndex @"GPLOptionOutputFileTypePopupButtonIndex"
#define UserDefaultKeyGPLOptionSyntaxTypePopupIndex @"GPLOptionSyntaxTypePopupButtonIndex"
#define UserDefaultKeyGPLOptionGenerateListOutput @"GPLOptionGenerateListOutput"
#define UserDefaultKeyGPLOptionGenerateSymbolTable @"GPLOptionGenerateSymbolTable"
#define UserDefaultKeyGPLOptionGenerateSymbolsAsEqus @"GPLOptionGenerateSymbolsAsEqus"
#define UserDefaultKeyGPLOptionAORGAddress @"GPLOptionAORGAddress"
#define UserDefaultKeyGPLOptionGROMAddress @"GPLOptionGROMAddress"


FOUNDATION_EXPORT NSErrorDomain const IDEErrorDomain;

typedef NS_ENUM(NSUInteger, IDEErrorCode) {
    IDEErrorCodeCantDisplayErrorInLogView = 1,
    IDEErrorCodeDocumentNotSaved = 2,
};


@interface AppDelegate : NSObject <NSApplicationDelegate>


@end

