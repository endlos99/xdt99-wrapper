//
//  SourceCodeTextView.h
//  SimpleXDT99IDE
//
//  Created by Henrik Wedekind on 04.07.19.
//
//  SimpleXDT99IDE a simple IDE based on xdt99 that shows how to use the XDTools99.framework
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

#import <Cocoa/Cocoa.h>


typedef NS_ENUM(NSUInteger, TabBehaviourType) {
    TabBehaviourTIStyle,
    TabBehaviourInsertSpaces,
    TabBehaviourInsertTab,
};


NS_ASSUME_NONNULL_BEGIN

@interface SourceCodeTextView : NSTextView

/**
 Counting the number of hard breaked lines within the receivers text up to the specified index.

 @param index   Index of a character. \p index must be in the range of the text bounds.
 @return        Number of the line of text that the specified index contains. Line numbers are counting starting 1. If \p index does not match the bound of the text, 0 will be returned.
 */
- (NSUInteger)lineNumberAtIndex:(NSUInteger)index;

/**
 Counting the number of lines of wrapped text in the receiver up to the specified index.

 @param index   Index of a character. \p index must be in the range of the text bounds.
 @return        Number of the line of wrapped text that the specified index contains. Line numbers are counting starting 1. If \p index does not match the bound of the text, 0 will be returned.
 */
- (NSUInteger)wrappedLineNumberAtIndex:(NSUInteger)index;

- (void)insertTIStyledTab:(id)sender;

@end


@class PrintPanelAccessoryController;
@class HighlighterDelegate;


@interface SourceCodeTextView (NSPrinting)

- (void)setPrintPanelAccessoryController:(PrintPanelAccessoryController *)controller;

- (void)setHighlighterDelegate:(HighlighterDelegate *)delegate;

@end

NS_ASSUME_NONNULL_END
