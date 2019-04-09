//
//  BasicCodeDocument.m
//  SimpleXDT99IDE
//
//  Created by Henrik Wedekind on 12.12.16.
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

#import "BasicCodeDocument.h"

#import "NSViewAutolayoutAdditions.h"

#import "AppDelegate.h"

#import <XDTools99/XDBasic.h>


@interface BasicCodeDocument ()

@property (retain) IBOutlet NSView *specialLogOptionView;

@property (assign) BOOL shouldShowWarningsInLog;
@property (assign) BOOL shouldDumpTokensInLog;

@property (assign) BOOL shouldJoinSourceLines;
@property (assign) BOOL shouldProtectFile;
@property (nonatomic, assign) NSUInteger outputFormatPopupButtonIndex;

@property (retain) NSArray<NSString *> *compilingMessages;
@property (retain) XDTObject *compilingResult;
@property (retain) NSString *tokenDump;

- (XDTBasic *)parseCode:(NSError **)error;

@end


@implementation BasicCodeDocument

- (instancetype)init
{
    self = [super init];
    if (nil == self) {
        return nil;
    }

    /* Setup documents options, before any data can read and processed */
    NSUserDefaults *defaults = [[NSUserDefaultsController sharedUserDefaultsController] defaults];
    [self setShouldJoinSourceLines:[defaults boolForKey:UserDefaultKeyBasicOptionShouldJoinSourceLines]];
    [self setShouldProtectFile:[defaults boolForKey:UserDefaultKeyBasicOptionShouldProtectFile]];
    [self setOutputFormatPopupButtonIndex:[defaults integerForKey:UserDefaultKeyBasicOptionOutputTypePopupIndex]];

    if (![[NSBundle mainBundle] loadNibNamed:@"BasicOptionsView" owner:self topLevelObjects:nil]) {
#if !__has_feature(objc_arc)
        [self release];
#endif
        return nil;
    }
    _compilingResult = nil;

    return self;
}


- (void)dealloc
{
#if !__has_feature(objc_arc)
    [_tokenDump release];
    [_compilingMessages release];
    [_compilingResult release];

    [super dealloc];
#endif
}


- (void)windowControllerDidLoadNib:(NSWindowController *)aController {
    [super windowControllerDidLoadNib:aController];

    [[[self logOptionsPlaceholderView] superview] replaceKeepingLayoutSubview:[self logOptionsPlaceholderView] with:_specialLogOptionView];
    [self setLogOptionsPlaceholderView:_specialLogOptionView];

    NSToolbarItem *optionsItem = [self xdt99OptionsToolbarItem];
    if (nil != optionsItem) {
        [optionsItem setView:[self xdt99OptionsToolbarView]];
    }
}


- (void)canCloseDocumentWithDelegate:(id)delegate shouldCloseSelector:(SEL)shouldCloseSelector contextInfo:(void *)contextInfo
{
    /* Save the latest assembler options to user defaults before closing. */
    NSUserDefaults *defaults = [[NSUserDefaultsController sharedUserDefaultsController] defaults];
    [defaults setBool:_shouldJoinSourceLines forKey:UserDefaultKeyBasicOptionShouldJoinSourceLines];
    [defaults setBool:_shouldProtectFile forKey:UserDefaultKeyBasicOptionShouldProtectFile];
    [defaults setInteger:_outputFormatPopupButtonIndex forKey:UserDefaultKeyBasicOptionOutputTypePopupIndex];

    [super canCloseDocumentWithDelegate:delegate shouldCloseSelector:shouldCloseSelector contextInfo:contextInfo];
}


+ (BOOL)isNativeType:(NSString *)typeName
{
    return [@"Xbas99DocumentType" isEqualToString:typeName];
}


- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError {
    // Insert code here to write your document to data of the specified type. If outError != NULL, ensure that you create and set an appropriate error when returning nil.
    // You can also choose to override -fileWrapperOfType:error:, -writeToURL:ofType:error:, or -writeToURL:ofType:forSaveOperation:originalContentsURL:error: instead.
    if (![@"Xbas99DocumentType" isEqualToString:typeName]) {
        if (outError) {
            *outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:nil];
        }
    }

    /* Saves only the source code variant. Generating any tagged/binary output only via the generateCode method. */
    NSData *retVal = [[self sourceCode] dataUsingEncoding:NSUTF8StringEncoding];
    return retVal;
}


- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError {
    // Insert code here to read your document from the given data of the specified type. If outError != NULL, ensure that you create and set an appropriate error when returning NO.
    // You can also choose to override -readFromFileWrapper:ofType:error: or -readFromURL:ofType:error: instead.
    // If you override either of these, you should also override -isEntireFileLoaded to return NO if the contents are lazily loaded.
    if ([@"Xbas99DocumentType" isEqualToString:typeName]) {
        [self setSourceCode:[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]];
#if !__has_feature(objc_arc)
        [[self sourceCode] autorelease];
#endif
    } else if ([@"Xbas99BinaryType" isEqualToString:typeName]) {
        NSString *fileExtension = [[self fileURL] pathExtension];
        XDTBasic *basic = [XDTBasic basicWithOptions:@{}];

        NSString *fileFormat = nil;
        if ([@"bin" isEqualToString:fileExtension]) {
            [basic loadProgramData:data error:outError];
            if (nil != *outError) {
                return NO;
            }
            fileFormat = @"internal";
        } else if ([@"iv254" isEqualToString:fileExtension]) {
            [basic loadLongData:data error:outError];
            if (nil != *outError) {
                return NO;
            }
            fileFormat = @"long";
        } else if ([@"dv163" isEqualToString:fileExtension]) {
            [basic loadMergedData:data error:outError];
            if (nil != *outError) {
                return NO;
            }
            fileFormat = @"merge";
        } else {
            if (nil != outError) {
                *outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr
                                            userInfo:@{NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"Unknown binary Basic file format.", @"Reason for the error if the Basic file cannot be recognized.")}];
            }
            return NO;
        }

        /* Test, if binary files are correctly read in. */
        NSDictionary<NSNumber *, NSArray *> *lines = [basic lines];
        if (0 >= [lines count]) {
            if (nil != outError) {
                *outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr
                                            userInfo:@{NSLocalizedFailureReasonErrorKey: [NSString stringWithFormat:NSLocalizedString(@"It seems that this Basic file is not in %@ format.", @"Reason for the error if the recognized file format cannot be decoded."), fileFormat]}];
            }
            return NO;
        }

        [self setCompilingMessages:[basic warnings]];
        [self setSourceCode:[basic getSource:outError]];

        /* binary Basic files cannot be handled as source code files, so force to save as a new file. */
        [self setFileURL:nil];
        NSAlert *info = [NSAlert alertWithMessageText:NSLocalizedString(@"Creating new file", @"Message text for alerting to create a new file.")
                                        defaultButton:nil alternateButton:nil otherButton:nil
                            informativeTextWithFormat:NSLocalizedString(@"Binary file imported. You will have to save the source code within a new file.", @"Informative text for imported binary Basic files to store them into a new file.")];
        [info runModal];
        //[info beginSheetModalForWindow:[self windowForSheet] modalDelegate:nil didEndSelector:nil contextInfo:nil];
    } else {
        if (nil != outError) {
            *outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:nil];
        }
    }

    if (nil != [self fileURL]) {
        [self setOutputFileName:[[[[self fileURL] lastPathComponent] stringByDeletingPathExtension] stringByAppendingString:@"-prg"]];
        [self setOutputBasePathURL:[[self fileURL] URLByDeletingLastPathComponent]];
    }
    [self checkCode:nil];
    return YES;
}


#pragma mark - Accessor Methods


+ (NSSet<NSString *> *)keyPathsForValuesAffectingValueForKey:(NSString *)key
{
    NSSet *retVal = [super keyPathsForValuesAffectingValueForKey:key];
    if ([@"generatedLogMessage" isEqualToString:key]) {
        NSMutableSet *newSet = [NSMutableSet setWithSet:retVal];
        [newSet addObjectsFromArray:@[@"shouldDumpTokensInLog", @"shouldShowWarningsInLog", @"compilingMessages", @"tokenDump"]];
        retVal = newSet;
    }
    return retVal;
}


- (NSString *)generatedLogMessage
{
    if (![self shouldShowLog]) {
        return @"";
    }

    NSMutableString *retVal = [NSMutableString string];
    if ([self shouldShowErrorsInLog] && nil != [self errorMessage]) {
        [retVal appendFormat:@"%@\n", [self errorMessage]];
    }
    if (_shouldShowWarningsInLog && nil != _compilingMessages) {
        [retVal appendFormat:@"%@\n", [_compilingMessages componentsJoinedByString:@"\n"]];
    }
    if (_shouldDumpTokensInLog && nil != _tokenDump) {
        [retVal appendFormat:@"%@\n", _tokenDump];
    }
    return retVal;
}


- (void)setOutputFormatPopupButtonIndex:(NSUInteger)outputFormatPopupButtonIndex
{
    if (outputFormatPopupButtonIndex == _outputFormatPopupButtonIndex) {
        return;
    }

    _outputFormatPopupButtonIndex = outputFormatPopupButtonIndex;
    switch (_outputFormatPopupButtonIndex) {
        case 0:
            [self setOutputFileName:[[[self outputFileName] stringByDeletingPathExtension] stringByAppendingPathExtension:@"bin"]];
            break;
        case 1:
            [self setOutputFileName:[[[self outputFileName] stringByDeletingPathExtension] stringByAppendingPathExtension:@"iv254"]];
            break;
        case 2:
            [self setOutputFileName:[[[self outputFileName] stringByDeletingPathExtension] stringByAppendingPathExtension:@"dv163"]];
            break;

        default:
            break;
    }
}


#pragma mark - Action Methods


- (void)checkCode:(id)sender
{
    NSError *error = nil;

    XDTBasic *basic = [self parseCode:&error];
    if (nil == basic) {
        if (nil != error) {
            /* TODO: Present errors through an error sheet, or display it just in the log view. */
        }
        return;
    }
    /* Do other serious things here... */
}


- (void)generateCode:(id)sender
{
    NSError *error = nil;

    XDTBasic *basic = [self parseCode:&error];
    if (nil == basic) {
        if (nil != error) {
            /* TODO: Present errors through an error sheet, or display it just in the log view. */
        }
        return;
    }

    BOOL successfullySaved = NO;
    switch (_outputFormatPopupButtonIndex) {
        case 0:
            successfullySaved = [basic saveProgramFormatFile:[NSURL fileURLWithPath:[self outputFileName] relativeToURL:[self outputBasePathURL]] error:&error];
            break;
        case 1:
            successfullySaved = [basic saveLongFormatFile:[NSURL fileURLWithPath:[self outputFileName] relativeToURL:[self outputBasePathURL]] error:&error];
            break;
        case 2:
            successfullySaved = [basic saveMergedFormatFile:[NSURL fileURLWithPath:[self outputFileName] relativeToURL:[self outputBasePathURL]] error:&error];
            break;

        default:
            break;
    }
    if (!successfullySaved) {
        [self setErrorMessage:[NSString stringWithFormat:@"ERROR: %@\n%@", [error localizedDescription], [error localizedFailureReason]]];
    }
}


#pragma mark - Private Methods


- (XDTBasic *)parseCode:(NSError **)error
{
    XDTBasic *basic = [XDTBasic basicWithOptions:@{XDTBasicOptionJoinLines: [NSNumber numberWithBool:_shouldJoinSourceLines],
                                                   XDTBasicOptionProtectFile: [NSNumber numberWithBool:_shouldProtectFile]
                                                   }];
    if (![basic parseSourceCode:[self sourceCode] error:error]) {
        [self setErrorMessage:[NSString stringWithFormat:@"ERROR: %@\n%@", [*error localizedDescription], [*error localizedFailureReason]]];
        return nil;
    }

    [self setCompilingMessages:[basic warnings]];
    [self setTokenDump:[basic dumpTokenList:error]];
    
    return basic;
}

@end
