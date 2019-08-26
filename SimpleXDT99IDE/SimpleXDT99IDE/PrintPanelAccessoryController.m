//
//  PrintPanelAccessoryController.m
//  SimpleXDT99IDE
//
//  Created by Henrik Wedekind on 16.09.19.
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

#import "PrintPanelAccessoryController.h"

#import "AppDelegate.h"


@interface PrintPanelAccessoryController ()

@end


@implementation PrintPanelAccessoryController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    // We override the designated initializer, ignoring the nib since we need our own
    return [super initWithNibName:@"PrintPanelAccessory" bundle:nibBundleOrNil];
}


- (void)setRepresentedObject:(id)printInfo
{
    [super setRepresentedObject:printInfo];
    // We don't bind to NSUserDefaults since we don't want changes while one panel is up to affect other panels that may be up
    self.highlightSource = [NSUserDefaults.standardUserDefaults boolForKey:UserDefaultKeyDocumentOptionPrintUsingHighlighting];
    [self addObserver:self forKeyPath:NSStringFromSelector(@selector(highlightSource)) options:0 context:NULL];
}


- (void)dealloc
{
    if (nil != self.representedObject) {   // If setRepresentedObject: wasn't called, no observers, so don't attempt to remove
        [self removeObserver:self forKeyPath:NSStringFromSelector(@selector(highlightSource))];
    }
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:NSStringFromSelector(@selector(highlightSource))]) {
        [[NSUserDefaults standardUserDefaults] setBool:self.highlightSource forKey:UserDefaultKeyDocumentOptionPrintUsingHighlighting];
        // TODO: Update prewiev after changing the highlighting attribute.
    } else if ([keyPath isEqualToString:NSStringFromSelector(@selector(printListing))]) {
        [[NSUserDefaults standardUserDefaults] setBool:self.printListing forKey:UserDefaultKeyDocumentOptionPrintListing];
        // TODO: Update prewiev after changing the highlighting attribute.
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}


#pragma mark Implementation of NSPrintPanelAccessorizing


- (NSSet *)keyPathsForValuesAffectingPreview {
    return [NSSet setWithObjects:NSStringFromSelector(@selector(highlightSource)), NSStringFromSelector(@selector(printListing)), nil];
}


- (nonnull NSArray<NSDictionary<NSPrintPanelAccessorySummaryKey, NSString *> *> *)localizedSummaryItems
{
    return @[@{NSPrintPanelAccessorySummaryItemNameKey: NSLocalizedString(@"Syntax Highlighting", @"Print panel summary item title for whether syntax should be highlighted"),
               NSPrintPanelAccessorySummaryItemDescriptionKey: self.highlightSource? NSLocalizedString(@"On", @"Print panel summary value for feature that is enabled") : NSLocalizedString(@"Off", @"Print panel summary value for feature that is disabled")
               },
             @{NSPrintPanelAccessorySummaryItemNameKey: NSLocalizedString(@"Print Listing", @"Print panel summary item title for whether assemby listing should be printed"),
               NSPrintPanelAccessorySummaryItemDescriptionKey: self.printListing? NSLocalizedString(@"On", @"Print panel summary value for feature that is enabled") : NSLocalizedString(@"Off", @"Print panel summary value for feature that is disabled")
               },
             ];
}

@end
