//
//  SourceCodeDocument.m
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

#import "SourceCodeDocument.h"

#import "NSViewAutolayoutAdditions.h"
#import "NSColorAdditions.h"

#import "AppDelegate.h"

#import "NoodleLineNumberView.h"

#import "XDTObject.h"
#import "XDTMessage.h"



@interface SourceCodeDocument () {
    NoodleLineNumberView *_lineNumberRulerView;
    XDTObject<XDTParserProtocol> *_parser;
}

@property (retain) NSNumber *lineNumberDigits;

- (IBAction)generateCode:(nullable id)sender;
- (IBAction)selectOutputFile:(nullable id)sender;
- (IBAction)hideShowLog:(nullable id)sender;

- (IBAction)saveLog:(id)sender;

@end


@implementation SourceCodeDocument

- (instancetype)init {
    self = [super init];
    if (nil == self) {
        return nil;
    }

    _outputBasePathURL = nil;
    _outputFileName = nil;
    _generatorMessages = nil;
    _lineNumberRulerView = nil;

    _lineNumberDigits = nil;

    return self;
}


- (void)dealloc
{
#if !__has_feature(objc_arc)
    [_outputBasePathURL release];
    [_outputFileName release];
    [_generatorMessages release];
    [_lineNumberRulerView release];
    [_lineNumberDigits release];
    
    [super dealloc];
#endif
}


+ (BOOL)autosavesInPlace {
    return YES;
}


- (NSString *)windowNibName {
    return @"Document";
}


- (void)windowControllerDidLoadNib:(NSWindowController *)aController {
    [super windowControllerDidLoadNib:aController];

    NSUserDefaults *defaults = [[NSUserDefaultsController sharedUserDefaultsController] defaults];
    [self setShouldShowLog:[defaults boolForKey:UserDefaultKeyDocumentOptionShowLog]];
    [self setShouldShowErrorsInLog:[defaults boolForKey:UserDefaultKeyDocumentOptionShowErrorsInLog]];
    [self setShouldShowWarningsInLog:[defaults boolForKey:UserDefaultKeyDocumentOptionShowWarningsInLog]];


    _lineNumberRulerView = [[NoodleLineNumberView alloc] initWithScrollView:_sourceScrollView];
    [_sourceScrollView setVerticalRulerView:_lineNumberRulerView];
    [_sourceScrollView setHasHorizontalRuler:NO];
    [_sourceScrollView setHasVerticalRuler:YES];
    [_sourceScrollView setRulersVisible:YES];
}


- (void)canCloseDocumentWithDelegate:(id)delegate shouldCloseSelector:(SEL)shouldCloseSelector contextInfo:(void *)contextInfo
{
    /* Save the latest common source code document options to user defaults before closing. */
    NSUserDefaults *defaults = [[NSUserDefaultsController sharedUserDefaultsController] defaults];
    [defaults setBool:_shouldShowLog forKey:UserDefaultKeyDocumentOptionShowLog];
    [defaults setBool:_shouldShowErrorsInLog forKey:UserDefaultKeyDocumentOptionShowErrorsInLog];
    [defaults setBool:_shouldShowWarningsInLog forKey:UserDefaultKeyDocumentOptionShowWarningsInLog];

    [super canCloseDocumentWithDelegate:delegate shouldCloseSelector:shouldCloseSelector contextInfo:contextInfo];
}


/* This method should be overridden from specialized class */
- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError {
    [NSException raise:@"UnimplementedMethod" format:@"%@ is unimplemented", NSStringFromSelector(_cmd)];
    return nil;
}


/* This method should be overridden from specialized class */
- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError {
    if (nil != outError) {
        *outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:nil];
    }
    return NO;
}


- (BOOL)openNestedFiles:(NSError **)outError
{
    __block NSError *myError = nil;
    NSOrderedSet<NSURL *> *includeFiles = [_parser includedFiles:&myError];
    if (nil != myError) {
        if (nil != outError) {
            *outError = myError;
        }
        return NO;
    }
    [includeFiles enumerateObjectsUsingBlock:^(NSURL *includingURL, NSUInteger idx, BOOL *stop) {
        /* open new tab with the included file. */
        [NSDocumentController.sharedDocumentController openDocumentWithContentsOfURL:includingURL
                                                                             display:YES
                                                                   completionHandler:^(NSDocument *document, BOOL documentWasAlreadyOpen, NSError *error) {
                                                                       if (nil == document || documentWasAlreadyOpen) {
                                                                           myError = error;
                                                                           return;
                                                                       }
                                                                       SourceCodeDocument *includedGPLDoc = (SourceCodeDocument *)document;
                                                                       [self.xdt99OptionsToolbarItem.view.window addTabbedWindow:includedGPLDoc.xdt99OptionsToolbarItem.view.window ordered:NSWindowOut];
                                                                   }];
    }];

    if (nil != outError) {
        *outError = myError;
    }
    return nil == myError;
}


/*
 Interesting delegate protocols are NSTextDelegate or its sub protocol NSTextViewDelegate i.e. for
 - grammar and spell checking for assembler nmemonics
 - displaying location (row, column) in source code in a status bar
 - assembling on the fly

 See hints at:
 - http://stackoverflow.com/questions/40672218/nsrulerview-how-to-correctly-align-line-numbers-with-main-text
 - http://stackoverflow.com/questions/15545857/nstextview-keydown-event#15546489
 */


/* This method returns a new error witch will displayed in an alert when no Log View is visible or the option showing errors is deactivated. */
- (NSError *)willPresentError:(NSError *)error
{
    if (![error.domain isEqualToString:XDTErrorDomain] || XDTErrorCodeToolLoggedError != error.code) {
        return error;
    }

    NSString *localizedRecoverySuggestionError = nil;
    if (!_shouldShowLog) {
        if (!_shouldShowErrorsInLog) {
            localizedRecoverySuggestionError = NSLocalizedString(@"Please open the log view and enable error logging to get detailed error information.", @"Recovery suggestion showing in an alert window when log view is invisible or error logging is disabled");
        } else {
            localizedRecoverySuggestionError = NSLocalizedString(@"Please open the log view to get detailed error information.", @"Recovery suggestion showing in an alert window when log view is invisible");
        }
    } else {
        if (!_shouldShowErrorsInLog) {
            localizedRecoverySuggestionError = NSLocalizedString(@"Please enable error logging to get detailed error information.", @"Recovery suggestion showing in an alert window when error logging is disabled");
        }
    }

    if (nil != localizedRecoverySuggestionError) {
        NSDictionary<NSErrorUserInfoKey, id> *d = [NSMutableDictionary dictionaryWithDictionary:error.userInfo];
        //NSString *s = [d valueForKey:NSLocalizedRecoverySuggestionErrorKey];
        [d setValue:localizedRecoverySuggestionError forKey:NSLocalizedRecoverySuggestionErrorKey];
        [d setValue:error forKey:NSUnderlyingErrorKey];

        error = [NSError errorWithDomain:IDEErrorDomain code:IDEErrorCodeCantDisplayErrorInLogView userInfo:d];
    }

    return error;
}


- (BOOL)textView:(NSTextView *)textView clickedOnLink:(id)link atIndex:(NSUInteger)charIndex
{
    NSURLComponents *urlComponents = [NSURLComponents componentsWithURL:link resolvingAgainstBaseURL:NO];
    if ([@"xdt99" isEqualToString:urlComponents.scheme]) {
        // TODO: select or open document with the filePath
        NSString *filePath = urlComponents.path;
        
        // scroll the source to line numer in link
        __block NSInteger lineNumberToSelect = NSNotFound;
        [urlComponents.queryItems enumerateObjectsUsingBlock:^(NSURLQueryItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([@"line" isEqualToString:obj.name]) {
                lineNumberToSelect = [obj.value integerValue];
            }
        }];

        NSLayoutManager *layoutManager = [_sourceView layoutManager];
        NSUInteger numberOfGlyphs = [layoutManager numberOfGlyphs];

        NSUInteger numberOfLines = 1;
        NSRange lineRange;
        for (NSUInteger indexOfGlyph = 0; indexOfGlyph < numberOfGlyphs; numberOfLines++) {
            [layoutManager lineFragmentRectForGlyphAtIndex:indexOfGlyph effectiveRange:&lineRange];
            // check if we've found our line number
            if (numberOfLines == lineNumberToSelect) {
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    [self->_sourceView.window makeFirstResponder:self->_sourceView];
                    [self->_sourceView.animator scrollRangeToVisible:lineRange];
                    [self->_sourceView.animator setSelectedRange:lineRange];
                }];
                break;
            }
            indexOfGlyph = NSMaxRange(lineRange);
        }
        return YES;
    }
    return NO;
}


- (BOOL)textView:(NSTextView *)textView shouldChangeTextInRange:(NSRange)affectedCharRange replacementString:(NSString *)replacementString
{
    return NO;
}


#pragma mark - Accessor Methods


+ (NSSet<NSString *> *)keyPathsForValuesAffectingGeneratedLogMessage
{
    return [NSSet setWithObjects:NSStringFromSelector(@selector(shouldShowWarningsInLog)), NSStringFromSelector(@selector(shouldShowErrorsInLog)), NSStringFromSelector(@selector(shouldShowLog)), NSStringFromSelector(@selector(generatorMessages)), NSStringFromSelector(@selector(lineNumberDigits)), nil];
}


- (NSMutableAttributedString *)generatedLogMessage
{
    NSMutableAttributedString *retVal = [NSMutableAttributedString new];
    if (![self shouldShowLog]) {
        return retVal;
    }

    NSColor *errorForeColor = [NSColor XDTErrorTextColor];
    NSColor *warningForeColor = [NSColor XDTWarningTextColor];

    NSDictionary<NSAttributedStringKey, id> *fontAttributeMonaco = @{
                                                                     NSFontAttributeName: [NSFont fontWithName:@"Monaco" size:0.0]
                                                                     };

    /* This method should be overridden to implement the document typical log output */
    [[_generatorMessages sortedByPriorityAscendingType] enumerateMessagesUsingBlock:^(NSDictionary<XDTMessageTypeKey,id> *obj, BOOL *stop) {
        const XDTMessageTypeValue messageType = (XDTMessageTypeValue)[(NSNumber *)[obj valueForKey:XDTMessageType] unsignedIntegerValue];

        NSString *fileName = [(NSURL *)[obj valueForKey:XDTMessageFileURL] lastPathComponent];
        if (nil == fileName) {
            fileName = [[self fileURL] lastPathComponent];
        }
        NSMutableAttributedString *formattedlogEntry = [[NSMutableAttributedString alloc] initWithString:[fileName stringByAppendingString:@" "]];
        
        NSNumber *passNumber = (NSNumber *)[obj valueForKey:XDTMessagePassNumber];
        if (nil != passNumber && [[NSNull null] isNotEqualTo:passNumber]) {
            [formattedlogEntry appendAttributedString:[[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"<%@> ", passNumber]]];
        }
        
        NSNumber *lineNumber = (NSNumber *)[obj valueForKey:XDTMessageLineNumber];
        if (nil != lineNumber && [[NSNull null] isNotEqualTo:lineNumber]) {
            NSInteger digitsOfLineNumber = (nil != self->_lineNumberDigits)? [self->_lineNumberDigits integerValue] : [lineNumber stringValue].length;
            NSString *logFormat = [NSString stringWithFormat:@"%%.%ldlu", (long)digitsOfLineNumber];
            [formattedlogEntry appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:logFormat, [lineNumber unsignedIntegerValue]]]];
            NSURLComponents *urlComponents = [NSURLComponents new];
            [urlComponents setScheme:@"xdt99"];
            [urlComponents setPath:[@"/" stringByAppendingString:fileName]];
            [urlComponents setQueryItems:@[[NSURLQueryItem queryItemWithName:@"line" value:[lineNumber stringValue]]]];
            [formattedlogEntry addAttributes:@{NSLinkAttributeName: [urlComponents URL]}
                                       range:NSMakeRange(formattedlogEntry.length-digitsOfLineNumber, digitsOfLineNumber)];
        } else {
            /* insert spaces instead of a line number */
            int digitsOfLineNumber = (nil != self->_lineNumberDigits)? [self->_lineNumberDigits intValue] : 0;
            [formattedlogEntry appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%*s", digitsOfLineNumber, ""]]];
        }
        
        NSString *codeLine = (NSString *)[obj valueForKey:XDTMessageCodeLine];
        if (nil != codeLine && [[NSNull null] isNotEqualTo:codeLine] && 0 < codeLine.length) {
            [formattedlogEntry appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@" - %@", codeLine] attributes:fontAttributeMonaco]];
        }

        NSString *messageText = (NSString *)[obj valueForKey:XDTMessageText];
        switch (messageType) {
            case XDTMessageTypeError:
                if (self.shouldShowErrorsInLog) {
                    NSRange prefixRange = [messageText rangeOfString:@"Error: " options:NSCaseInsensitiveSearch];
                    if (NSNotFound != prefixRange.location) {
                        messageText = [messageText substringFromIndex:NSMaxRange(prefixRange)];
                    }
                    [formattedlogEntry appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"\nError: %@\n", messageText]]];
                    [formattedlogEntry addAttribute:NSForegroundColorAttributeName value:errorForeColor range:NSMakeRange(0, formattedlogEntry.length)];
                    [retVal appendAttributedString:formattedlogEntry];
                }
                break;

            case XDTMessageTypeWarning:
                if (self.shouldShowWarningsInLog) {
                    NSRange prefixRange = [messageText rangeOfString:@"Warning: " options:NSCaseInsensitiveSearch];
                    if (NSNotFound != prefixRange.location) {
                        messageText = [messageText substringFromIndex:NSMaxRange(prefixRange)];
                    }
                    [formattedlogEntry appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"\nWarning: %@\n", messageText]]];

                    [formattedlogEntry addAttribute:NSForegroundColorAttributeName value:warningForeColor range:NSMakeRange(0, formattedlogEntry.length)];
                    [retVal appendAttributedString:formattedlogEntry];
                    // TODO: an Ralf: Für xas99 und xga99 fehlen noch Angaben über Datei, Durchlauf und Zeilennummer vor der Warnung, so wie es in stderr ausgegeben wird.
                }
                break;

            default:
                break;
        }
    }];

    return retVal;
}


+ (NSSet *)keyPathsForValuesAffectingHasLogContentToSave
{
    return [NSSet setWithObject:@"logView.string"];
}


- (BOOL)hasLogContentToSave
{
    return (nil != _logView) && ([[_logView string] length] > 0);
}


+ (NSSet *)keyPathsForValuesAffectingStatusImage
{
    return [NSSet setWithObjects:NSStringFromSelector(@selector(generatorMessages)), nil];
}


- (NSImage *)statusImage
{
    NSImageName imageName = NSImageNameStatusAvailable;
    if (nil != _generatorMessages) {
        if (0 < [_generatorMessages countOfType:XDTMessageTypeError]) {
            imageName = NSImageNameStatusUnavailable;
        } else if (0 < [_generatorMessages countOfType:XDTMessageTypeWarning]) {
            imageName = NSImageNameStatusPartiallyAvailable;
        }
    }
    return [NSImage imageNamed:imageName];
}


- (void)setLogOptionsPlaceholderView:(NSView *)newLogOptionView
{
    if (newLogOptionView == _logOptionsPlaceholderView) {
        return;
    }

    if (nil == newLogOptionView) {
        newLogOptionView = [[NSView alloc] initWithFrame:[_logOptionsPlaceholderView frame]];
    }
    [[_logOptionsPlaceholderView superview] replaceKeepingLayoutSubview:_logOptionsPlaceholderView with:newLogOptionView];

    [self willChangeValueForKey:NSStringFromSelector(@selector(logOptionsPlaceholderView))];
    _logOptionsPlaceholderView = newLogOptionView;
    [self didChangeValueForKey:NSStringFromSelector(@selector(logOptionsPlaceholderView))];
}


- (void)setGeneratorOptionsPlaceholderView:(NSView *)newOptionsView
{
    if (newOptionsView == _generatorOptionsPlaceholderView) {
        return;
    }

    if (nil == newOptionsView) {
        newOptionsView = [[NSView alloc] initWithFrame:[_generatorOptionsPlaceholderView frame]];
    }
    [[_generatorOptionsPlaceholderView superview] replaceKeepingLayoutSubview:_generatorOptionsPlaceholderView with:newOptionsView];

    [self willChangeValueForKey:NSStringFromSelector(@selector(generatorOptionsPlaceholderView))];
    _generatorOptionsPlaceholderView = newOptionsView;
    [self didChangeValueForKey:NSStringFromSelector(@selector(generatorOptionsPlaceholderView))];
}


#pragma mark - Action Methods


- (IBAction)saveDocument:(id)sender
{
    /*
     Overwrite the original behavior, that steels the focus of the source view and places the selected range at the end of the text.
     */
    NSArray<NSValue *> *selRanges = _sourceView.selectedRanges;

    [super saveDocument:sender];

    _sourceView.selectedRanges = selRanges;
    [_sourceView scrollRangeToVisible:_sourceView.selectedRange];
    [_sourceView.window makeFirstResponder:_sourceView];
}


/*
 This method should be overridden to implement the document typical code generator.
 But it should call its super method to handle unsaved modifications for the document.
 */
- (void)checkCode:(id)sender
{
    if (!self.isDocumentEdited) {
        return;
    }

    NSAlert *alert = [NSAlert new];
    alert.messageText = NSLocalizedString(@"Can't process file!", @"Alert message for unsaved documents which will be processed by a generator.");
    [alert addButtonWithTitle:NSLocalizedString(@"Save", @"Default button name for choosing 'Save' in an Alert.")];
    [alert addButtonWithTitle:NSLocalizedString(@"Abort", @"Alternate button name for choosing 'Abort' in an Alert.")];
    alert.informativeText = [NSString stringWithFormat:NSLocalizedString(@"Caution: The file '%@' must be saved before it can be processed.", @"Informative text for unsaved documents which will be processed by a generator."), self.fileURL.lastPathComponent];
    alert.alertStyle = NSAlertStyleWarning;
    [alert beginSheetModalForWindow:self.windowForSheet completionHandler:^(NSModalResponse returnCode) {
        [NSApp stopModalWithCode:returnCode];
    }];
    NSModalResponse returnCode = [NSApp runModalForWindow:self.windowForSheet];
    if (NSModalResponseContinue == returnCode ||
        NSAlertFirstButtonReturn == returnCode) {
        [self saveDocument:sender];
        [self updateChangeCount:NSChangeCleared];
    }
}


/*
 This method should be overridden to implement the document typical code generator.
 But it should call its super method to handle unsaved modifications for the document.
 */
- (void)generateCode:(id)sender
{
    [self checkCode:sender];
}


- (void)hideShowLog:(id)sender
{
    [self setShouldShowLog:[sender state] == NSOnState];
}


- (void)selectOutputFile:(id)sender
{
    NSSavePanel *panel = [NSSavePanel savePanel];
    [panel setCanCreateDirectories:YES];
    [panel setTitle:NSLocalizedString(@"Select output file name", @"Title for saving source files in Save Panel")];
    [panel setDirectoryURL:[self outputBasePathURL]];
    [panel setNameFieldStringValue:[self outputFileName]];

    [panel beginSheetModalForWindow:[self windowForSheet] completionHandler:^(NSInteger result) {
        if (NSFileHandlingPanelOKButton == result) {
            [self setOutputFileName:[[panel URL] lastPathComponent]];
            [self setOutputBasePathURL:[[panel URL] URLByDeletingLastPathComponent]];
        }
    }];
}


- (void)saveLog:(id)sender
{
    if (nil == _logView) {
        return;
    }

    NSData *logData = [[_logView string] dataUsingEncoding:NSUTF8StringEncoding];
    if (nil != logData && 0 < [logData length]) {
        /* TODO: Use a NSSavePanel to interact with user for getting the correct URL */
        NSString *dateString = [NSDateFormatter localizedStringFromDate:[NSDate date]
                                                              dateStyle:NSDateFormatterShortStyle
                                                              timeStyle:NSDateFormatterShortStyle];
        NSString *logFileName = [NSString stringWithFormat:@"Listing from %@, %@.txt", [[self fileURL] lastPathComponent], [dateString stringByReplacingOccurrencesOfString:@":" withString:@"-"]];
        NSURL *listingFileURL = [NSURL fileURLWithPath:logFileName relativeToURL:[self outputBasePathURL]];
        [logData writeToURL:listingFileURL atomically:YES];
    }
}

@end
