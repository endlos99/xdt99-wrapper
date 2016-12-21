//
//  NSViewAutolayoutAdditions.m
//  SimpleXDT99IDE
//
//  Created by Henrik Wedekind on 13.12.16.
//
//  SimpleXDT99IDE a simple IDE based on xdt99 that shows how to use the XDTools99.framework
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

#import "NSViewAutolayoutAdditions.h"


@implementation NSView (AutolayoutAdditions)

- (void)replaceKeepingLayoutSubview:(NSView *)oldView with:(NSView *)newView
{
    if (oldView == newView) {
        return;
    }
    if (nil == oldView || ![oldView isDescendantOf:self]) {
        return;
    }
    if (nil == newView || [newView isDescendantOf:self]) {
        return;
    }

    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"NSConstraintBasedLayoutVisualizeMutuallyExclusiveConstraints"];
    NSMutableArray<NSLayoutConstraint *> *newRelevantConstraints = [NSMutableArray arrayWithCapacity:4];
    NSMutableArray<NSLayoutConstraint *> *oldRelevantConstraints = [NSMutableArray arrayWithCapacity:4];
    for (NSLayoutConstraint *c in [self constraints]) {
        const id firstItem = [c firstItem];
        const id secondItem = [c secondItem];

        NSLayoutConstraint *newConstraint = nil;
        if (firstItem == oldView) {
            newConstraint = [NSLayoutConstraint constraintWithItem:newView
                                                         attribute:[c firstAttribute]
                                                         relatedBy:[c relation]
                                                            toItem:secondItem
                                                         attribute:[c secondAttribute]
                                                        multiplier:[c multiplier]
                                                          constant:[c constant]];
            //NSLog(@"\nreplace first item constraint:\n %@\nwith new constraint:\n %@", c, newConstraint);
        } else if (secondItem == oldView) {
            newConstraint = [NSLayoutConstraint constraintWithItem:firstItem
                                                         attribute:[c firstAttribute]
                                                         relatedBy:[c relation]
                                                            toItem:newView
                                                         attribute:[c secondAttribute]
                                                        multiplier:[c multiplier]
                                                          constant:[c constant]];
            //NSLog(@"\nreplace second item constraint:\n %@\nwith new constraint:\n %@", c, newConstraint);
        }
        if (nil != newConstraint) {
            [newConstraint setShouldBeArchived:[c shouldBeArchived]];
            [newConstraint setPriority:[c priority]];
            
            [newRelevantConstraints addObject:newConstraint];
            [oldRelevantConstraints addObject:c];
        }
    }

    /* Remember the old frame, in case Auto Layout is not being used. */
    NSRect frame = oldView.frame;

    [self replaceSubview:oldView with:newView];
    [self removeConstraints:oldRelevantConstraints];
    [self addConstraints:newRelevantConstraints];

    /* Replace frames origin. */
    frame.size = [newView frame].size;
    [newView setFrame:frame];
}

@end
