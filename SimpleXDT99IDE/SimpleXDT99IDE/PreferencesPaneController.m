//
//  PreferencesPaneController.m
//  SimpleXDT99IDE
//
//  Created by Henrik Wedekind on 11.07.19.
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

#import "PreferencesPaneController.h"

#import "SourceCodeDocument.h"
#import "AppDelegate.h"

#import <XDTools99/XDTools99.h>


@interface PreferencesPaneController ()

@end


static PreferencesPaneController *_sharedPreferencesPane = nil;

@implementation PreferencesPaneController

+ (instancetype)sharedPreferencesPane
{
    if (nil == _sharedPreferencesPane) {
        @synchronized (self) {
            _sharedPreferencesPane = [[PreferencesPaneController alloc] initWithWindowNibName:@"PreferencesPane"];
        }
    }
    return _sharedPreferencesPane;
}


- (void)windowDidLoad
{
    [super windowDidLoad];

    self.window.excludedFromWindowsMenu = YES;
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}


- (IBAction)toggleAllHighlighting:(id)sender
{
    NSUserDefaults *defaults = [[NSUserDefaultsController sharedUserDefaultsController] defaults];
    BOOL enableHighlighting = [defaults boolForKey:UserDefaultKeyDocumentOptionEnableHighlighting];
    if (!enableHighlighting) {
        [defaults setBool:NO forKey:UserDefaultKeyDocumentOptionHighlightSyntax];
        [defaults setBool:NO forKey:UserDefaultKeyDocumentOptionHighlightMessages];
        [self toggleSyntaxHighlighting:sender];
        //[self toggleMessageHighlighting:sender];
    }
}


- (IBAction)toggleSyntaxHighlighting:(id)sender
{
    [NSDocumentController.sharedDocumentController.documents enumerateObjectsUsingBlock:^(SourceCodeDocument *doc, NSUInteger idx, BOOL *stop) {
        NSRange saveSelection = doc.sourceView.selectedRange;
        [doc setupSyntaxHighlighting];
        doc.sourceView.selectedRange = saveSelection;
        [doc.sourceView scrollRangeToVisible:saveSelection];
        doc.generatorMessages = doc.generatorMessages;
    }];
}


- (IBAction)toggleMessageHighlighting:(id)sender
{
    [NSDocumentController.sharedDocumentController.documents enumerateObjectsUsingBlock:^(SourceCodeDocument *doc, NSUInteger idx, BOOL *stop) {
        doc.generatorMessages = doc.generatorMessages;
    }];
}


- (IBAction)resetSuppressedAlerts:(id)sender
{
    NSData *emptyIndexSet = [NSKeyedArchiver archivedDataWithRootObject:NSIndexSet.indexSet];
    NSUserDefaults *defaults = [[NSUserDefaultsController sharedUserDefaultsController] defaults];

    [defaults setObject:@{IDEErrorDomain: emptyIndexSet, XDTErrorDomain: emptyIndexSet} forKey:UserDefaultKeyDocumentOptionSuppressedAlerts];
}

@end
