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

- (void)insertTIStyledTab:(id)sender;

@end

NS_ASSUME_NONNULL_END
