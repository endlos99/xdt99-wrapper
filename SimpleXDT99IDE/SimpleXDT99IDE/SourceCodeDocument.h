//
//  SourceCodeDocument.h
//  SimpleXDT99
//
//  Created by Henrik Wedekind on 02.12.16.
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

#import <Cocoa/Cocoa.h>


@interface SourceCodeDocument : NSDocument

@property (retain) NSString *sourceCode;

@property (assign) BOOL shouldShowLog;
@property (assign) BOOL shouldShowErrorsInLog;

@property (retain) NSURL *outputBasePathURL;
@property (retain) NSString *outputFileName;

@property (assign) IBOutlet NSToolbarItem *xdt99OptionsToolbarItem;
@property (assign) IBOutlet NSView *xdt99OptionsToolbarView;

@property (assign) IBOutlet NSView *logOptionsPlaceholderView;

@property (assign) IBOutlet NSScrollView *sourceScrollView;
@property (assign) IBOutlet NSTextView *sourceView;
@property (assign) IBOutlet NSTextView *logView;
@property (readonly) BOOL hasLogContentToSave;

@property (readonly) NSImage *statusImage;
@property (retain) NSString *errorMessage;
@property (readonly) NSString *generatedLogMessage;

- (IBAction)checkCode:(id)sender;
- (IBAction)generateCode:(id)sender;

@end

