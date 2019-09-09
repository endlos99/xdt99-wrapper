//
//  SourceCodeTextView.m
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

#import "SourceCodeTextView.h"

#import "AppDelegate.h"
#import "HighlighterDelegate.h"
#import "PrintPanelAccessoryController.h"


@interface SourceCodeTextView () {
    BOOL _observerAdded;

    BOOL _previousPrintLineNumbers;     // Stores the last setting of whether to print line numbers
    BOOL _previousHighlightSource;      // Stores the last setting of whether to highlight syntax
}

@property (assign) TabBehaviourType tabBehaviour;
@property (assign) NSUInteger tabWidth;

// Definitions from Cathegory SourceCodeTextView (NSPrinting)
@property (assign) PrintPanelAccessoryController *printPanelAccessoryController;
@property (assign) HighlighterDelegate *highlighterDelegate;

@end


@implementation SourceCodeTextView

- (instancetype)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (nil == self) {
        return nil;
    }

    _observerAdded = NO; // No Observer will be added when initialized for NSPrinting

    return self;
}


- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (nil == self) {
        return nil;
    }

    _tabBehaviour = [NSUserDefaults.standardUserDefaults integerForKey:UserDefaultKeyDocumentOptionTabBehaviour];
    _tabWidth = [NSUserDefaults.standardUserDefaults integerForKey:UserDefaultKeyDocumentOptionTabWidth];
    [NSUserDefaults.standardUserDefaults addObserver:self
                                          forKeyPath:UserDefaultKeyDocumentOptionTabBehaviour
                                             options:NSKeyValueObservingOptionNew
                                             context:NULL];
    [NSUserDefaults.standardUserDefaults addObserver:self
                                          forKeyPath:UserDefaultKeyDocumentOptionTabWidth
                                             options:NSKeyValueObservingOptionNew
                                             context:NULL];
    _observerAdded = YES;

    return self;
}


- (void)dealloc
{
    if (_observerAdded) {
        [NSUserDefaults.standardUserDefaults removeObserver:self
                                                 forKeyPath:UserDefaultKeyDocumentOptionTabWidth];
        [NSUserDefaults.standardUserDefaults removeObserver:self
                                                 forKeyPath:UserDefaultKeyDocumentOptionTabBehaviour];
    }
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([UserDefaultKeyDocumentOptionTabBehaviour isEqualToString:keyPath]) {
        self.tabBehaviour = [(NSUserDefaults *)object integerForKey:UserDefaultKeyDocumentOptionTabBehaviour];
    } else if ([UserDefaultKeyDocumentOptionTabWidth isEqualToString:keyPath]) {
        self.tabWidth = [(NSUserDefaults *)object integerForKey:UserDefaultKeyDocumentOptionTabWidth];
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}


- (void)insertTab:(id)sender
{
    if (self.window.firstResponder != self) {
        [super insertTab:sender];
        return;
    }

    switch (_tabBehaviour) {
        case TabBehaviourInsertTab:
            [super insertTab:sender];
            break;
        case TabBehaviourInsertSpaces:
            [self insertText:[NSString stringWithFormat:@"%*s", (int)_tabWidth, ""]];
            break;
        case TabBehaviourTIStyle:
            [self insertTIStyledTab:sender];
            break;

        default:
            break;
    }
}


/* Values are the number of spaces from the beginnig of a line. Value 0 is a termination flag. */
static NSUInteger const tabstops[] = {7, 12, 25, 30, 45, 59, 79, 0};

- (void)insertBacktab:(id)sender
{
    if (!_tabBehaviour || self.window.firstResponder != self) {
        [super insertBacktab:sender];
        return;
    }

    NSRange lineRange = [self.textStorage.mutableString lineRangeForRange:self.selectedRange];
    int locationInLine = (int)(self.selectedRange.location - lineRange.location);
    for (int i = 0; 0 != tabstops[i]; i++) {
        if (tabstops[i] >= locationInLine) {
            if (0 >= i) {
                self.selectedRange = NSMakeRange(lineRange.location, 0);
            } else {
                self.selectedRange = NSMakeRange(lineRange.location + tabstops[i-1], 0);
            }
            break;
        }
    }
}


- (NSUInteger)lineNumberAtIndex:(NSUInteger)index
{
    if (self.textStorage.length < index) {
        return 0;
    }

    NSUInteger numberOfLines = 0;
    NSRange range = {0, 0};

    while (range.location < index) {
        numberOfLines++;
        range.location += [self.textStorage.mutableString lineRangeForRange:range].length;
    }

    return numberOfLines;
}


- (NSUInteger)wrappedLineNumberAtIndex:(NSUInteger)index
{
    if (self.textStorage.length < index) {
        return 0;
    }

    NSUInteger numberOfLines = 0;
    NSRange range = {0, 0};

    while (range.location < index) {
        numberOfLines++;
        (void) [self.layoutManager lineFragmentRectForGlyphAtIndex:range.location effectiveRange:&range];
        range.location += range.length;
    }

    return numberOfLines;
}


- (void)insertTIStyledTab:(id)sender
{
    NSRange lineRange = [self.textStorage.mutableString lineRangeForRange:self.selectedRange];
    lineRange.length--; // We don't need the new line character
    NSUInteger locationInLine = self.selectedRange.location - lineRange.location;
    for (int i = 0; 0 != tabstops[i]; i++) {
        if (tabstops[i] > locationInLine) {
            if (tabstops[i] <= lineRange.length) {
                /* If line is longer than the tab position, just adjust the cursor position. */
                if (0 == self.selectedRange.length) {
                    self.selectedRange = NSMakeRange(lineRange.location + tabstops[i], 0);
                } else {
                    /* If there is a selection, replace it with amount of spaces to reach the tab position. */
                    [self insertText:[NSString stringWithFormat:@"%*s", (int)(tabstops[i] - locationInLine), ""]];
                }
            } else {
                /* Line is shorter than the new tab position, insert amount of necessary spaces to the end of line. */
                self.selectedRange = NSMakeRange(lineRange.location + lineRange.length, 0);
                [self insertText:[NSString stringWithFormat:@"%*s", (int)(tabstops[i] - lineRange.length), ""]];
            }
            break;
        }
    }
}


#pragma mark Overwritings of NSView(NSPrinting)


/* Override of knowsPageRange: checks printing parameters against the last invocation, and if not the same, resizes the view and relays out the text.  On first invocation, the saved size will be 0,0, which will cause the text to be laid out.
 */
- (BOOL)knowsPageRange:(NSRangePointer)range
{
    if (_previousPrintLineNumbers != self.printPanelAccessoryController.printListing ||
        _previousHighlightSource != self.printPanelAccessoryController.highlightSource) {
        _previousPrintLineNumbers = self.printPanelAccessoryController.printListing;
        _previousHighlightSource = self.printPanelAccessoryController.highlightSource;

        [self.textStorage beginEditing];
        if (_previousHighlightSource) {
            [self.textStorage.mutableString enumerateSubstringsInRange:NSMakeRange(0, self.textStorage.length)
                                                               options:NSStringEnumerationByLines + NSStringEnumerationSubstringNotRequired
                                                            usingBlock:^(NSString *line, NSRange lineRange, NSRange enclosingRange, BOOL *stop) {
                                                                [self.highlighterDelegate highlightSyntaxForText:self.textStorage inRange:lineRange];
                                                            }];
        } else {
            [self.textStorage setAttributes:@{NSForegroundColorAttributeName: NSColor.blackColor,
                                              NSFontAttributeName: [NSFont fontWithName:@"Menlo" size:0.0]
                                              }
                                      range:NSMakeRange(0, self.textStorage.length)];
        }
        [self.textStorage endEditing];
    }

    return [super knowsPageRange:range];
}

@end
