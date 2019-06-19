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

#import "AppDelegate.h"

#import "NoodleLineNumberView.h"

#import "XDTObject.h"
#import "XDTMessage.h"



@interface SourceCodeDocument () {
    NoodleLineNumberView *_lineNumberRulerView;
}

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

    return self;
}


- (void)dealloc
{
#if !__has_feature(objc_arc)
    [_outputBasePathURL release];
    [_outputFileName release];
    [_generatorMessages release];
    [_lineNumberRulerView release];
    
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


#pragma mark - Accessor Methods


+ (NSSet<NSString *> *)keyPathsForValuesAffectingGeneratedLogMessage
{
    return [NSSet setWithObjects:NSStringFromSelector(@selector(shouldShowWarningsInLog)), NSStringFromSelector(@selector(shouldShowErrorsInLog)), NSStringFromSelector(@selector(shouldShowLog)), NSStringFromSelector(@selector(generatorMessages)), nil];
}


- (NSMutableString *)generatedLogMessage
{
    NSMutableString *retVal = [NSMutableString string];
    if (![self shouldShowLog]) {
        return retVal;
    }

    /* This method should be overridden to implement the document typical log output */
    if ([self shouldShowErrorsInLog]) {
        [_generatorMessages enumerateMessagesOfType:XDTMessageTypeError usingBlock:^(NSDictionary<XDTMessageTypeKey,id> *obj, BOOL *stop) {
            NSString *fileName = [(NSURL *)[obj valueForKey:XDTMessageFileURL] lastPathComponent];
            NSNumber *passNumber = (NSNumber *)[obj valueForKey:XDTMessagePassNumber];
            NSNumber *lineNumber = (NSNumber *)[obj valueForKey:XDTMessageLineNumber];
            NSString *codeLine = (NSString *)[obj valueForKey:XDTMessageCodeLine];
            NSString *messageText = (NSString *)[obj valueForKey:XDTMessageText];
            /*
             > gaops.gpl <1> 0028 -         STx   @>8391,@>8302
             ***** Syntax error
             */
            [retVal appendFormat:@"%@ <%@> %@ - %@\n%@\n", fileName, passNumber, lineNumber, codeLine, messageText];
        }];
    }
    if ([self shouldShowWarningsInLog]) {
        [_generatorMessages enumerateMessagesOfType:XDTMessageTypeWarning usingBlock:^(NSDictionary<XDTMessageTypeKey,id> *obj, BOOL *stop) {
            NSString *fileName = [(NSURL *)[obj valueForKey:XDTMessageFileURL] lastPathComponent];
            if (nil == fileName) {
                fileName = [[self fileURL] lastPathComponent];
            }
            NSNumber *passNumber = (NSNumber *)[obj valueForKey:XDTMessagePassNumber];
            NSNumber *lineNumber = (NSNumber *)[obj valueForKey:XDTMessageLineNumber];
            NSString *codeLine = (NSString *)[obj valueForKey:XDTMessageCodeLine];
            if (nil == codeLine) {
                codeLine = @"";
            }
            NSString *messageText = (NSString *)[obj valueForKey:XDTMessageText];
            [retVal appendFormat:@"%@ <%@> %@ - %@\nWarning: %@\n", fileName, passNumber, lineNumber, codeLine, messageText];
        }];
        // TODO: an Ralf: Für xas99 und xga99 fehlen noch Angaben über Datei, Durchlauf und Zeilennummer vor der Warnung, so wie es in stderr ausgegeben wird.
        /*
         Treating as register, did you intend an @address?
         asmacs-ti.asm <2> 0034 - Warning: Treating as register, did you intend an @address?
         */
    }
    
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


#pragma mark - Action Methods


- (void)checkCode:(id)sender
{
    /* This method should be overridden to implement the document typical code generator */
}


- (void)generateCode:(id)sender
{
    /* This method should be overridden to implement the document typical code generator */
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
