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

#import "Terminal.h"

#import "NSViewAutolayoutAdditions.h"
#import "NSTextStorageAdditions.h"
#import "NSColorAdditions.h"

#import "AppDelegate.h"

#import "NoodleLineNumberView.h"

#import "XDTObject.h"
#import "XDTMessage.h"



@interface SourceCodeDocument () <SBApplicationDelegate> {
    NoodleLineNumberView *_lineNumberRulerView;
    XDTObject<XDTParserProtocol> *_parser;

    NSInteger _terminalId;
}

@property (retain) NSNumber *lineNumberDigits;
@property (retain) NSNumber *lineNumberJump;

@property (retain) IBOutlet NSPanel *lineNumberPanel;

- (IBAction)jumpToLineNumber:(nullable id)sender;
- (IBAction)jumpToLabel:(nullable id<NSValidatedUserInterfaceItem>)sender;
- (IBAction)jumpToLastIssue:(nullable id)sender;
- (IBAction)jumpToNextIssue:(nullable id)sender;
- (IBAction)jumpToPreviousIssue:(nullable id)sender;
- (IBAction)jumpToFirstIssue:(nullable id)sender;

- (IBAction)endLineNumberSheet:(nullable id)sender;  // only for quitting the line number sheet

- (IBAction)selectOutputFile:(nullable id)sender;
- (IBAction)hideShowLog:(nullable id)sender;
- (IBAction)toggleErrors:(nullable id)sender;
- (IBAction)toggleWarnings:(nullable id)sender;

- (IBAction)saveLog:(nullable id)sender;

- (void)updateMessagesToSource;
- (void)buildLabelMenu:(NSMenu *)labelMenu;

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

    _terminalId = NSNotFound;

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

    [_parser release];
    
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


- (BOOL)setupSyntaxHighlighting
{
    NSUserDefaults *defaults = NSUserDefaultsController.sharedUserDefaultsController.defaults;
    BOOL useSyntaxHighlighting = [defaults boolForKey:UserDefaultKeyDocumentOptionHighlightSyntax];
    if (!useSyntaxHighlighting) {
        self.sourceView.textStorage.delegate = nil;
        self.sourceCode = self.sourceView.textStorage.mutableString;
    }

    return useSyntaxHighlighting;
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


- (BOOL)presentError:(NSError *)error
{
    NSUserDefaults *defaults = [[NSUserDefaultsController sharedUserDefaultsController] defaults];
    NSDictionary<NSErrorDomain, NSData *> *suppressedAlerts = [defaults objectForKey:UserDefaultKeyDocumentOptionSuppressedAlerts];
    NSIndexSet *suppressedErrorCodes = [NSKeyedUnarchiver unarchiveObjectWithData:[suppressedAlerts objectForKey:error.domain]];
    BOOL isSuppressedErrorCode = [suppressedErrorCodes containsIndex:error.code];

    if (isSuppressedErrorCode) {
        [self willNotPresentError:error];
        return NO;
    }

    NSErrorDomain errorDomain = error.domain;
    NSInteger errorCode = error.code;
    BOOL isXDTLoggedError = [errorDomain isEqualToString:XDTErrorDomain] && XDTErrorCodeToolLoggedError == errorCode;
    if (isXDTLoggedError) {
        /*
         The content/message of an logged error will change, because it is already be shown in the log console.
         */
        error = [self willPresentError:error];
    }

    NSAlert *errorAlert = [NSAlert alertWithError:error];
    errorAlert.alertStyle = (isXDTLoggedError)? NSAlertStyleWarning : NSAlertStyleCritical;
    errorAlert.showsSuppressionButton = isXDTLoggedError; // Using default checkbox title
    [errorAlert beginSheetModalForWindow:self.windowForSheet completionHandler:^(NSModalResponse returnCode) {
        if (errorAlert.suppressionButton.state == NSOnState) {
            // Suppress this alert for the specific error domain and error code from now on
            NSMutableIndexSet *newSuppressedErrorCode = suppressedErrorCodes.mutableCopy;
            [newSuppressedErrorCode addIndex:errorCode];
            NSMutableDictionary<NSErrorDomain, NSData *> *newSuppressedAlerts = suppressedAlerts.mutableCopy;
            [newSuppressedAlerts setObject:[NSKeyedArchiver archivedDataWithRootObject:newSuppressedErrorCode] forKey:errorDomain];
            [defaults setObject:newSuppressedAlerts forKey:UserDefaultKeyDocumentOptionSuppressedAlerts];
        }
    }];
    
    return NO;
}


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


#pragma mark - Implementation of NSTextViewDelegate


- (BOOL)textView:(NSTextView *)textView clickedOnLink:(id)link atIndex:(NSUInteger)charIndex
{
    NSURLComponents *urlComponents = [NSURLComponents componentsWithURL:link resolvingAgainstBaseURL:NO];
    if ([@"xdt99" isEqualToString:urlComponents.scheme]) {
        NSString *fileName = [urlComponents.path lastPathComponent];
        if (NSOrderedSame != [[self.fileURL lastPathComponent] caseInsensitiveCompare:fileName]) {
            NSError *error = nil;
            NSString *filePath = [_parser findFile:urlComponents.path error:&error];
            if (nil == filePath) {
                if (nil != error) {
                    [self presentError:error modalForWindow:[self windowForSheet] delegate:nil didPresentSelector:nil contextInfo:nil];
                }
                return YES;
            }
            NSURL *includingURL = [NSURL fileURLWithPath:filePath];
            if (nil != includingURL) {
                [NSDocumentController.sharedDocumentController openDocumentWithContentsOfURL:includingURL
                                                                                     display:YES
                                                                           completionHandler:^(NSDocument *document, BOOL alreadyOpen, NSError *error) {
                                                                               SourceCodeDocument *includedGPLDoc = (SourceCodeDocument *)document;
                                                                               [self.xdt99OptionsToolbarItem.view.window addTabbedWindow:includedGPLDoc.xdt99OptionsToolbarItem.view.window ordered:NSWindowBelow];
                                                                           }];
            }
            return YES;
        }
        
        // scroll the source to line numer in link
        __block NSInteger lineNumberToSelect = NSNotFound;
        [urlComponents.queryItems enumerateObjectsUsingBlock:^(NSURLQueryItem *obj, NSUInteger idx, BOOL *stop) {
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
    return textView == _sourceView;
}


- (BOOL)textView:(NSTextView *)textView shouldChangeTextInRanges:(NSArray<NSValue *> *)affectedRanges replacementStrings:(NSArray<NSString *> *)replacementStrings
{
    return textView == _sourceView;
}


#pragma mark - Implementation of SBApplicationDelegate


/* Part of the SBApplicationDelegate protocol.
    Called when an error occurs in Scripting Bridge method. */
- (id)eventDidFail:(const AppleEvent *)event withError:(NSError *)error
{
    //[[NSAlert alertWithError:error] runModal];
    NSLog(@"%s ERROR: AppleEvent error: %@", __FUNCTION__, error);
    return nil;
}


#pragma mark - Accessor Methods


- (void)setGeneratorMessages:(XDTMessage *)generatorMessages
{
    _generatorMessages = generatorMessages;

    [self updateMessagesToSource];
}


/* subclasses should override this method to implement attributings */
- (void)setSourceCode:(NSString *)newSourceCode
{
    if (nil != self.parser) {
        [self.parser setSource:newSourceCode];
    }
    self.attributedSourceCode = [[NSAttributedString alloc] initWithString:newSourceCode
                                                                attributes:@{NSForegroundColorAttributeName: [NSColor XDTSourceTextColor],
                                                                             NSFontAttributeName: [NSFont fontWithName:@"Menlo" size:0.0]
                                                                             }];
}


- (NSString *)sourceCode
{
    return _attributedSourceCode.string;
}


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

    NSDictionary<NSAttributedStringKey, id> *monospacedFontAttribute = @{NSFontAttributeName: [NSFont fontWithName:@"Menlo" size:0.0]};

    /* This method should be overridden to implement the document typical log output */
    [[_generatorMessages sortedByPriorityAscendingType] enumerateMessagesUsingBlock:^(NSDictionary<XDTMessageTypeKey,id> *obj, BOOL *stop) {
        const XDTMessageTypeValue messageType = (XDTMessageTypeValue)[(NSNumber *)[obj valueForKey:XDTMessageType] unsignedIntegerValue];

        id fileUrl = [obj valueForKey:XDTMessageFileURL];
        NSString *fileName = (nil == fileUrl || NSNull.null == fileUrl)? nil : [(NSURL *)fileUrl lastPathComponent];
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
            [formattedlogEntry appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@" - %@", codeLine] attributes:monospacedFontAttribute]];
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


- (NSString *)commandLineInstruction
{
    return @"";
}


#pragma mark - Action Methods


- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
    if (menuItem.action == @selector(jumpToLineNumber:)) {
        return 0 < self.sourceView.textStorage.length;
    }

    if (menuItem.action == @selector(jumpToLabel:)) {
        if (!menuItem.hasSubmenu) {
            return YES; // Every single label menu item is valid
        }
        if (nil == _parser) {   // i.e. Basic document has no parser (and no labels), so disable this item
            return NO;
        }
        NSMenu *jumpToLabelMenu = menuItem.submenu;
        [self buildLabelMenu:jumpToLabelMenu];  // Build/update label list
        return 0 < jumpToLabelMenu.numberOfItems;
    }

    if (menuItem.action == @selector(jumpToLastIssue:)) {
        if (nil == _generatorMessages || 0 >= _generatorMessages.count) {
            menuItem.title = NSLocalizedString(@"No Last Issue", @"Menu item title for no last entry in a list of messages.");
            return NO;
        }
        menuItem.title = NSLocalizedString(@"Last Issue", @"Menu item title for jumping to the last unspecified entry in a list of messages.");
        return YES;
    }

    if (menuItem.action == @selector(jumpToNextIssue:)) {
        if (nil == _generatorMessages || 0 >= _generatorMessages.count || _sourceView.selectedRange.location >= _sourceView.textStorage.length) {
            return NO;
        }
        NSRange lineNumberRange = {_sourceView.selectedRange.location, 0};
        lineNumberRange = [_sourceView.textStorage.mutableString lineRangeForRange:lineNumberRange];
        lineNumberRange.location += lineNumberRange.length / 2;
        lineNumberRange = NSMakeRange([_sourceView lineNumberAtIndex:lineNumberRange.location] + 1, NSNotFound);
        XDTMessage *nextMessages = [_generatorMessages messagesForLineNumberRange:lineNumberRange];
        if (nil == nextMessages) {
            menuItem.title = NSLocalizedString(@"No Next Issue", @"Menu item title for no next entry in a list of messages.");
            return NO;
        }
        XDTMessageTypeValue msgType = [[nextMessages.objectEnumerator.nextObject valueForKey:XDTMessageType] unsignedIntegerValue];
        switch (msgType) {
            case XDTMessageTypeError:
                menuItem.title = NSLocalizedString(@"Next Error", @"Menu item title for jumping to the next error in a list of messages.");
                break;
            case XDTMessageTypeWarning:
                menuItem.title = NSLocalizedString(@"Next Warning", @"Menu item title for jumping to the next warning in a list of messages.");
                break;

            default:
                menuItem.title = NSLocalizedString(@"Next Issue", @"Menu item title for jumping to the next unspecified entry in a list of messages.");
                break;
        }
        return YES;
    }

    if (menuItem.action == @selector(jumpToPreviousIssue:)) {
        if (nil == _generatorMessages || 0 >= _generatorMessages.count || 0 >= _sourceView.selectedRange.location) {
            return NO;
        }
        NSRange lineNumberRange = {_sourceView.selectedRange.location, 0};
        lineNumberRange = [_sourceView.textStorage.mutableString lineRangeForRange:lineNumberRange];
        lineNumberRange.location += lineNumberRange.length / 2;
        lineNumberRange = NSMakeRange(1, [_sourceView lineNumberAtIndex:lineNumberRange.location] - 1);
        XDTMessage *prevMessages = [_generatorMessages messagesForLineNumberRange:lineNumberRange];
        if (nil == prevMessages) {
            menuItem.title = NSLocalizedString(@"No Previous Issue", @"Menu item title for no previous entry in a list of messages.");
            return NO;
        }
        XDTMessageTypeValue msgType = [[prevMessages.reverseObjectEnumerator.nextObject valueForKey:XDTMessageType] unsignedIntegerValue];
        switch (msgType) {
            case XDTMessageTypeError:
                menuItem.title = NSLocalizedString(@"Previous Error", @"Menu item title for jumping to the previous error in a list of messages.");
                break;
            case XDTMessageTypeWarning:
                menuItem.title = NSLocalizedString(@"Previous Warning", @"Menu item title for jumping to the previous warning in a list of messages.");
                break;

            default:
                menuItem.title = NSLocalizedString(@"Previous Issue", @"Menu item title for jumping to the previous unspecified entry in a list of messages.");
                break;
        }
        return YES;
    }

    if (menuItem.action == @selector(jumpToFirstIssue:)) {
        if (nil == _generatorMessages || 0 >= _generatorMessages.count) {
            menuItem.title = NSLocalizedString(@"No First Issue", @"Menu item title for no first entry in a list of messages.");
            return NO;
        }
        menuItem.title = NSLocalizedString(@"First Issue", @"Menu item title for jumping to the first unspecified entry in a list of messages.");
        return YES;
    }

    if (menuItem.action == @selector(hideShowLog:)) {
        menuItem.title = (_shouldShowLog)? NSLocalizedString(@"Hide Log", @"Menu item title for hiding the log view.") : NSLocalizedString(@"Show Log", @"Menu item title for showing the log view.");
        return YES;
    }

    if (menuItem.action == @selector(toggleErrors:)) {
        menuItem.title = (_shouldShowErrorsInLog)? NSLocalizedString(@"Suppress Errors in Log", @"Menu item title for suppressing errors in the log view") : NSLocalizedString(@"Display Errors in Log", @"Menu item title for displaying errors in the log view");
        return _shouldShowLog;
    }

    if (menuItem.action == @selector(toggleWarnings:)) {
        menuItem.title = (_shouldShowWarningsInLog)? NSLocalizedString(@"Suppress Warnings in Log", @"Menu item title for suppressing warnings in the log view") : NSLocalizedString(@"Display Warnings in Log", @"Menu item title for displaying warnings in the log view");
        return _shouldShowLog;
    }

    return YES;
}


- (IBAction)jumpToLineNumber:(id)sender
{
    [self.windowForSheet beginSheet:_lineNumberPanel completionHandler:^(NSModalResponse returnCode) {
        const NSInteger jumpLineNumber = [self.lineNumberJump integerValue];
        if (NSModalResponseStop != returnCode || nil == self.lineNumberJump) {
            return;
        }
        __block NSRange lastLineRange = self.sourceView.selectedRange;
        [self.sourceView.textStorage enumerateLinesUsingBlock:^(NSRange lineRange, NSUInteger lineNumber, BOOL *stop) {
            if (lineNumber == jumpLineNumber) {
                lastLineRange = lineRange;
                *stop = YES;
            }
        }];
        self.sourceView.selectedRange = lastLineRange;
        [self.sourceView scrollRangeToVisible:lastLineRange];
    }];
}


- (IBAction)jumpToLabel:(id<NSValidatedUserInterfaceItem>)sender
{
    const NSInteger jumpLineNumber = sender.tag;
    [_sourceView.textStorage enumerateLinesUsingBlock:^(NSRange lineRange, NSUInteger lineNumber, BOOL *stop) {
        if (lineNumber == jumpLineNumber) {
            self.sourceView.selectedRange = lineRange;
            [self.sourceView scrollRangeToVisible:lineRange];
            *stop = YES;
        }
    }];
}


- (IBAction)jumpToLastIssue:(id)sender
{
    NSEnumerator<NSDictionary<XDTMessageTypeKey,id> *> *messageEnumerator = _generatorMessages.reverseObjectEnumerator;
    NSDictionary<XDTMessageTypeKey, id> *lastMessage = messageEnumerator.nextObject;
    if (nil == lastMessage) {
        return;
    }

    NSNumber *lineNumber = [lastMessage valueForKey:XDTMessageLineNumber];
    while ([NSNull.null isEqualTo:lineNumber]) {
        lastMessage = messageEnumerator.nextObject;
        lineNumber = [lastMessage valueForKey:XDTMessageLineNumber];
    }
    NSUInteger firstLineNumber = [lineNumber unsignedIntegerValue];
    _sourceView.selectedRange = [_sourceView.textStorage rangeForLineNumber:firstLineNumber];
    [_sourceView scrollRangeToVisible:_sourceView.selectedRange];
}


- (IBAction)jumpToNextIssue:(id)sender
{
    NSRange lineNumberRange = {_sourceView.selectedRange.location, 0};
    lineNumberRange = [_sourceView.textStorage.mutableString lineRangeForRange:lineNumberRange];
    lineNumberRange.location += lineNumberRange.length / 2;
    lineNumberRange = NSMakeRange([_sourceView lineNumberAtIndex:lineNumberRange.location] + 1, NSNotFound);
    XDTMessage *nextMessages = [_generatorMessages messagesForLineNumberRange:lineNumberRange];
    if (nil == nextMessages) {
        return;
    }

    NSUInteger nextLineNumber = [[nextMessages.objectEnumerator.nextObject valueForKey:XDTMessageLineNumber] unsignedIntegerValue];
    _sourceView.selectedRange = [_sourceView.textStorage rangeForLineNumber:nextLineNumber];
    [_sourceView scrollRangeToVisible:_sourceView.selectedRange];
}


- (IBAction)jumpToPreviousIssue:(id)sender
{
    NSRange lineNumberRange = {_sourceView.selectedRange.location, 0};
    lineNumberRange = [_sourceView.textStorage.mutableString lineRangeForRange:lineNumberRange];
    lineNumberRange.location += lineNumberRange.length / 2;
    lineNumberRange = NSMakeRange(1, [_sourceView lineNumberAtIndex:lineNumberRange.location] - 1);
    XDTMessage *prevMessages = [_generatorMessages messagesForLineNumberRange:lineNumberRange];
    if (nil == prevMessages) {
        return;
    }

    NSUInteger prevLineNumber = [[prevMessages.reverseObjectEnumerator.nextObject valueForKey:XDTMessageLineNumber] unsignedIntegerValue];
    _sourceView.selectedRange = [_sourceView.textStorage rangeForLineNumber:prevLineNumber];
    [_sourceView scrollRangeToVisible:_sourceView.selectedRange];
}


- (IBAction)jumpToFirstIssue:(id)sender
{
    NSEnumerator<NSDictionary<XDTMessageTypeKey,id> *> *messageEnumerator = _generatorMessages.objectEnumerator;
    NSDictionary<XDTMessageTypeKey, id> *firstMessage = messageEnumerator.nextObject;
    if (nil == firstMessage) {
        return;
    }

    NSNumber *lineNumber = [firstMessage valueForKey:XDTMessageLineNumber];
    while ([NSNull.null isEqualTo:lineNumber]) {
        firstMessage = messageEnumerator.nextObject;
        lineNumber = [firstMessage valueForKey:XDTMessageLineNumber];
    }
    NSUInteger firstLineNumber = [lineNumber unsignedIntegerValue];
    _sourceView.selectedRange = [_sourceView.textStorage rangeForLineNumber:firstLineNumber];
    [_sourceView scrollRangeToVisible:_sourceView.selectedRange];
}


- (IBAction)endLineNumberSheet:(id)sender
{
    [self.windowForSheet endSheet:_lineNumberPanel];
}


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
- (IBAction)checkCode:(id)sender
{
    if (!self.isDocumentEdited) {
        return;
    }
    NSUserDefaults *defaults = [[NSUserDefaultsController sharedUserDefaultsController] defaults];
    NSDictionary<NSErrorDomain, NSData *> *suppressedAlerts = [defaults objectForKey:UserDefaultKeyDocumentOptionSuppressedAlerts];
    NSIndexSet *suppressedErrorCodes = [NSKeyedUnarchiver unarchiveObjectWithData:[suppressedAlerts objectForKey:IDEErrorDomain]];
    if ([suppressedErrorCodes containsIndex:IDEErrorCodeDocumentNotSaved]) {
        [self saveDocument:sender];
        [self updateChangeCount:NSChangeCleared];
        return;
    }

    NSAlert *alert = [NSAlert new];
    alert.messageText = NSLocalizedString(@"Can't process file!", @"Alert message for unsaved documents which will be processed by a generator.");
    [alert addButtonWithTitle:NSLocalizedString(@"Save", @"Default button name for choosing 'Save' in an Alert.")];
    [alert addButtonWithTitle:NSLocalizedString(@"Abort", @"Alternate button name for choosing 'Abort' in an Alert.")];
    alert.informativeText = [NSString stringWithFormat:NSLocalizedString(@"Caution: The file '%@' must be saved before it can be processed.", @"Informative text for unsaved documents which will be processed by a generator."), self.fileURL.lastPathComponent];
    alert.alertStyle = NSAlertStyleWarning;
    alert.showsSuppressionButton = YES;
    [alert beginSheetModalForWindow:self.windowForSheet completionHandler:^(NSModalResponse returnCode) {
        if (alert.suppressionButton.state == NSOnState) {
            // Suppress this alert for the specific error domain and error code from now on
            NSMutableIndexSet *newSuppressedErrorCode = suppressedErrorCodes.mutableCopy;
            [newSuppressedErrorCode addIndex:IDEErrorCodeDocumentNotSaved];
            NSMutableDictionary<NSErrorDomain, NSData *> *newSuppressedAlerts = suppressedAlerts.mutableCopy;
            [newSuppressedAlerts setObject:[NSKeyedArchiver archivedDataWithRootObject:newSuppressedErrorCode] forKey:IDEErrorDomain];
            [defaults setObject:newSuppressedAlerts forKey:UserDefaultKeyDocumentOptionSuppressedAlerts];
        }
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
- (IBAction)generateCode:(id)sender
{
    [self checkCode:sender];
}


- (IBAction)runToolInTerminal:(id)sender
{
    /* Services kann nicht viel...
    NSPasteboard *pboard = [NSPasteboard pasteboardWithName:@"NSPasteboardNameTerminalFolder"];
    [pboard prepareForNewContentsWithOptions:NSPasteboardContentsCurrentHostOnly];
    [pboard writeObjects:@[self.fileURL.URLByDeletingLastPathComponent]];
    NSPerformService(@"New Terminal at Folder", pboard);
     */
    NSString *cli = self.commandLineInstruction;
    if (0 >= cli.length) {  // usually always true
        return;
    }

    TerminalApplication *_terminal = [SBApplication applicationWithBundleIdentifier:@"com.apple.Terminal"];
    if (!_terminal.isRunning) {
        _terminal.launchFlags = kLSLaunchDontAddToRecents | kLSLaunchAsync;
    }
    //_terminal.delegate = self;

    TerminalTab *terminalTab = nil;
    if (NSNotFound != _terminalId) {
        TerminalWindow *win = [_terminal.windows objectWithID:[NSNumber numberWithInteger:_terminalId]];
        if (nil != win && win.id == _terminalId && win.exists) {
            win.frontmost = YES;
            win.visible = YES;
            terminalTab = [win.tabs objectAtLocation:@0];
        } else {
            terminalTab = nil;
        }
    }
    if (nil == terminalTab) {
        [_terminal open:@[self.fileURL.URLByDeletingLastPathComponent]];
        TerminalWindow *win = [_terminal.windows objectAtLocation:@0];
        win.frontmost = YES;
        win.visible = YES;
        _terminalId = win.id;

        terminalTab = [win.tabs objectAtLocation:@0];
        terminalTab = [_terminal doScript:nil in:terminalTab];
        terminalTab.titleDisplaysFileName = NO;
        terminalTab.titleDisplaysShellPath = NO;
        terminalTab.titleDisplaysDeviceName = NO;
        terminalTab.titleDisplaysWindowSize = NO;
        terminalTab.titleDisplaysCustomTitle = YES;
        terminalTab.customTitle = @"xdt99";
    }
    [_terminal activate];
    (void) [_terminal doScript:cli in:terminalTab];
}


- (IBAction)hideShowLog:(id)sender
{
    [self setShouldShowLog:!_shouldShowLog];
}


- (IBAction)toggleErrors:(id)sender
{
    [self setShouldShowErrorsInLog:!_shouldShowErrorsInLog];
}


- (IBAction)toggleWarnings:(id)sender
{
    [self setShouldShowWarningsInLog:!_shouldShowWarningsInLog];
}


- (IBAction)selectOutputFile:(id)sender
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


- (IBAction)saveLog:(id)sender
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


#pragma mark - Private Methods


- (void)updateMessagesToSource
{
    [_sourceView.textStorage beginEditing];

    [_sourceView.textStorage removeAttribute:NSBackgroundColorAttributeName range:NSMakeRange(0, _sourceView.textStorage.length)];
    [_sourceView.textStorage removeAttribute:NSToolTipAttributeName range:NSMakeRange(0, _sourceView.textStorage.length)];

    NSUserDefaults *defaults = [[NSUserDefaultsController sharedUserDefaultsController] defaults];
    BOOL useMessageHighlighting = [defaults boolForKey:UserDefaultKeyDocumentOptionHighlightMessages];
    if (!useMessageHighlighting) {
        [_sourceView.textStorage endEditing];
        return;
    }

    NSEnumerator<NSDictionary<XDTMessageTypeKey, id> *> *messageEnumerator = _generatorMessages.objectEnumerator;
    __block NSDictionary<XDTMessageTypeKey, id> *currentMessage = messageEnumerator.nextObject;
    if (nil != currentMessage) {
        NSNumber *lineNumberObj = [currentMessage valueForKey:XDTMessageLineNumber];
        while([[NSNull null] isEqualTo:lineNumberObj]) {
            currentMessage = messageEnumerator.nextObject;
            lineNumberObj = [currentMessage valueForKey:XDTMessageLineNumber];
        }

        __block NSUInteger currentMessageLineNumber = [lineNumberObj unsignedIntegerValue];
        __block XDTMessageTypeValue currentMessageType = [[currentMessage valueForKey:XDTMessageType] unsignedIntegerValue];
        [_sourceView.textStorage enumerateLinesUsingBlock:^(NSRange lineRange, NSUInteger lineNumber, BOOL *stop) {
            if (lineNumber < currentMessageLineNumber) {
                return;
            }

            NSColor *backgroundColor = nil;
            NSString *toolTip = nil;
            switch (currentMessageType) {
                case XDTMessageTypeError:
                    backgroundColor = [NSColor XDTErrorBackgroundColor];
                    toolTip = [NSString stringWithFormat:@"%@: %@", NSLocalizedString(@"Error", @"the word 'Error'"), [currentMessage valueForKey:XDTMessageText]];
                    break;

                case XDTMessageTypeWarning:
                    backgroundColor = [NSColor XDTWarningBackgroundColor];
                    toolTip = [NSString stringWithFormat:@"%@: %@", NSLocalizedString(@"Warning", @"the word 'Warning'"), [currentMessage valueForKey:XDTMessageText]];
                    break;

                default:
                    break;
            }
            if (nil != backgroundColor) {
                [self.sourceView.textStorage addAttribute:NSBackgroundColorAttributeName value:backgroundColor range:lineRange];
                [self.sourceView.textStorage addAttribute:NSToolTipAttributeName value:toolTip range:lineRange];
            }

            do {
                currentMessage = messageEnumerator.nextObject;
                if (nil == currentMessage) {
                    *stop = YES;
                    return;
                }
                NSNumber *lineNumber = [currentMessage valueForKey:XDTMessageLineNumber];
                if ([NSNull.null isNotEqualTo:lineNumber]) {
                    currentMessageLineNumber = [lineNumber unsignedIntegerValue];
                }
            } while (lineNumber == currentMessageLineNumber);   // skip other messages with lower priority
            currentMessageType = [[currentMessage valueForKey:XDTMessageType] unsignedIntegerValue];
        }];
    }

    [_sourceView.textStorage endEditing];
}


/**
 Builds the specified menu with a list of all labels from the current (GPL-)Assembler document that will be used as jump locations.
 @param labelMenu   The Menu which will contain all available labels defined in the source code. All existing menu items will be removed.
 */
- (void)buildLabelMenu:(NSMenu *)labelMenu
{
    [labelMenu removeAllItems];

    __block NSInteger lineCounter = 0;
    [self.sourceView.textStorage.mutableString enumerateLinesUsingBlock:^(NSString *line, BOOL *stop) {
        lineCounter++;
        NSArray<id> *lineComponents = [self.parser splitLine:line];
        if (0 >= lineComponents.count) {    // comment or empty line?
            return;
        }
        NSString *label = [[NSString alloc] initWithData:lineComponents.firstObject encoding:NSUTF8StringEncoding];
        if (nil == label || 0 == label.length) {
            return;
        }
        if ([label hasSuffix:@":"]) {
            label = [label substringToIndex:label.length-1];
        }

        NSMenuItem *labelItem = [[NSMenuItem alloc] initWithTitle:label action:@selector(jumpToLabel:) keyEquivalent:@""];
        labelItem.tag = lineCounter;
        labelItem.target = self;
        [labelMenu addItem:labelItem];
    }];
}

@end
