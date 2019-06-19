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

#import "AppDelegate.h"

#import <XDTools99/XDBasic.h>


@interface BasicCodeDocument ()

@property (retain) IBOutlet NSView *specialLogOptionView;

@property (assign) BOOL shouldDumpTokensInLog;

@property (assign) BOOL shouldJoinSourceLines;
@property (assign) BOOL shouldProtectFile;
@property (assign) NSUInteger outputFormatPopupButtonIndex;

@property (retain) XDTObject *compilingResult;
@property (retain) NSString *tokenDump;

@property (readonly) XDTBasicTargetType targetType;

- (XDTBasic *)parseCode:(NSError **)error;

- (void)valueDidChangeForOutputFormatPopupButtonIndex:(XDTBasicTargetType)newTarget;

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
    [_compilingResult release];

    [super dealloc];
#endif
}


- (void)windowControllerDidLoadNib:(NSWindowController *)aController {
    [super windowControllerDidLoadNib:aController];

    [self setLogOptionsPlaceholderView:_specialLogOptionView];

    [self addObserver:self forKeyPath:NSStringFromSelector(@selector(outputFormatPopupButtonIndex)) options:NSKeyValueObservingOptionNew context:nil];

    NSToolbarItem *optionsItem = [self xdt99OptionsToolbarItem];
    if (nil != optionsItem) {
        [optionsItem setView:[self xdt99OptionsToolbarView]];
    }
}


- (void)canCloseDocumentWithDelegate:(id)delegate shouldCloseSelector:(SEL)shouldCloseSelector contextInfo:(void *)contextInfo
{
    [self removeObserver:self forKeyPath:NSStringFromSelector(@selector(outputFormatPopupButtonIndex))];

    /* Save the latest assembler options to user defaults before closing. */
    NSUserDefaults *defaults = [[NSUserDefaultsController sharedUserDefaultsController] defaults];
    [defaults setBool:_shouldJoinSourceLines forKey:UserDefaultKeyBasicOptionShouldJoinSourceLines];
    [defaults setBool:_shouldProtectFile forKey:UserDefaultKeyBasicOptionShouldProtectFile];
    [defaults setInteger:_outputFormatPopupButtonIndex forKey:UserDefaultKeyBasicOptionOutputTypePopupIndex];

    [super canCloseDocumentWithDelegate:delegate shouldCloseSelector:shouldCloseSelector contextInfo:contextInfo];
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (object == self && [NSStringFromSelector(@selector(outputFormatPopupButtonIndex)) isEqualToString:keyPath]) {
        XDTBasicTargetType target = self.targetType;
        [self valueDidChangeForOutputFormatPopupButtonIndex:target];
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}


- (void)valueDidChangeForOutputFormatPopupButtonIndex:(XDTBasicTargetType)newTarget
{
    switch (newTarget) {
        case 0:
            self.outputFileName = [self.outputFileName.stringByDeletingPathExtension stringByAppendingPathExtension:@"bin"];
            break;
        case 1:
            self.outputFileName = [self.outputFileName.stringByDeletingPathExtension stringByAppendingPathExtension:@"iv254"];
            break;
        case 2:
            self.outputFileName = [self.outputFileName.stringByDeletingPathExtension stringByAppendingPathExtension:@"dv163"];
            break;

        default:
            break;
    }
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
        return nil;
    }

    /* Saves only the source code variant. Generating any tagged/binary output only via the generateCode method. */
    NSData *retVal = [[self sourceCode] dataUsingEncoding:NSUTF8StringEncoding];
    return retVal;
}


- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError
{
    NSError *error = nil;
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
            [basic loadProgramData:data error:&error];
            if (nil != error) {
                if (nil != *outError) {
                    *outError = error;
                }
                return NO;
            }
            fileFormat = @"internal";
        } else if ([@"iv254" isEqualToString:fileExtension]) {
            [basic loadLongData:data error:&error];
            if (nil != error) {
                if (nil != *outError) {
                    *outError = error;
                }
                return NO;
            }
            fileFormat = @"long";
        } else if ([@"dv163" isEqualToString:fileExtension]) {
            [basic loadMergedData:data error:&error];
            if (nil != error) {
                if (nil != *outError) {
                    *outError = error;
                }
                return NO;
            }
            fileFormat = @"merge";
        } else {
            if (nil != outError) {
                *outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:kPOSIXErrorEFTYPE
                                            userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"Can not open Basic file!", @"Description for the error if the Basic file cannot be opened."),
                                                       NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"Unknown binary Basic file format.", @"Reason for the error if the Basic file cannot be recognized.")}];
            }
            return NO;
        }

        /* Test, if binary files are correctly read in. */
        NSDictionary<NSNumber *, NSArray *> *lines = [basic lines];
        if (0 >= [lines count]) {
            if (nil != outError) {
                *outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:kPOSIXErrorEFTYPE
                                            userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"Can not open Basic file!", @"Description for the error if the Basic file cannot be opened."),
                                                       NSLocalizedFailureReasonErrorKey: [NSString stringWithFormat:NSLocalizedString(@"It seems that this Basic file is not in %@ format.", @"Reason for the error if the recognized file format cannot be decoded."), fileFormat]}];
            }
            return NO;
        }

        [self setGeneratorMessages:basic.messages];
        [self setSourceCode:[basic getSource:&error]];

        if (nil == error) {
            /* binary Basic files cannot be handled as source code files, so force to save as a new file. */
            [self setFileURL:nil];
            NSAlert *info = [NSAlert alertWithMessageText:NSLocalizedString(@"Creating new file", @"Message text for alerting to create a new file.")
                                            defaultButton:nil alternateButton:nil otherButton:nil
                                informativeTextWithFormat:NSLocalizedString(@"Binary file imported. You will have to save the source code within a new file.", @"Informative text for imported binary Basic files to store them into a new file.")];
            [info runModal];
            //[info beginSheetModalForWindow:[self windowForSheet] modalDelegate:nil didEndSelector:nil contextInfo:nil];
        }
    } else {
        error = [NSError errorWithDomain:NSOSStatusErrorDomain code:kPOSIXErrorEFTYPE userInfo:nil];
    }

    if (nil == error) {
        if (nil != [self fileURL]) {
            [self setOutputFileName:[[[[self fileURL] lastPathComponent] stringByDeletingPathExtension] stringByAppendingString:@"-prg"]];
            [self setOutputBasePathURL:[[self fileURL] URLByDeletingLastPathComponent]];
        }
        
        return YES;
    }
    
    if (nil != outError) {
        *outError = error;
    }
    return NO;
}


#pragma mark - Accessor Methods


+ (NSSet<NSString *> *)keyPathsForValuesAffectingGeneratedLogMessage
{
    NSSet *retVal = [[super superclass] keyPathsForValuesAffectingGeneratedLogMessage];
    NSMutableSet *newSet = [NSMutableSet setWithSet:retVal];
    [newSet addObjectsFromArray:@[NSStringFromSelector(@selector(shouldDumpTokensInLog)), NSStringFromSelector(@selector(tokenDump))]];
    retVal = newSet;
    
    return retVal;
}


- (NSMutableString *)generatedLogMessage
{
    NSMutableString *retVal = [super generatedLogMessage];
    if (nil == retVal || ![self shouldShowLog]) {
        return retVal;
    }

    if (_shouldDumpTokensInLog && nil != _tokenDump && 0 < [_tokenDump length]) {
        [retVal appendFormat:@"%@\n", _tokenDump];
    }
    
    return retVal;
}


#pragma mark - Action Methods


- (void)checkCode:(id)sender
{
    NSError *error = nil;

    XDTBasic *basic = [self parseCode:&error];
    if (nil == basic) {
        if (nil != error) {
            if (!self.shouldShowErrorsInLog || !self.shouldShowLog) {
                [self presentError:error modalForWindow:[self windowForSheet] delegate:nil didPresentSelector:nil contextInfo:nil];
            }
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
            if (!self.shouldShowErrorsInLog || !self.shouldShowLog) {
                [self presentError:error modalForWindow:[self windowForSheet] delegate:nil didPresentSelector:nil contextInfo:nil];
            }
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
        if (nil != error) {
            if (!self.shouldShowErrorsInLog || !self.shouldShowLog) {
                [self presentError:error modalForWindow:[self windowForSheet] delegate:nil didPresentSelector:nil contextInfo:nil];
            }
        }
    }
}


#pragma mark - Private Methods


+ (NSSet *)keyPathsForValuesAffectingTargetType
{
    return [NSSet setWithObject:NSStringFromSelector(@selector(outputFormatPopupButtonIndex))];
}


- (XDTBasicTargetType)targetType
{
    XDTBasicTargetType xdtTargetType = XDTBasicTargetTypeLongFormat;
    switch (_outputFormatPopupButtonIndex) {
        case 0:
            xdtTargetType = XDTBasicTargetTypeInternalFormat;
            break;
        case 1:
            xdtTargetType = XDTBasicTargetTypeLongFormat;
            break;
        case 2:
            xdtTargetType = XDTBasicTargetTypeMergeFormat;
            break;

        default:
            break;
    }
    return xdtTargetType;
}


- (XDTBasic *)parseCode:(NSError **)error
{
    XDTBasic *basic = [XDTBasic basicWithOptions:@{XDTBasicOptionJoinLines: [NSNumber numberWithBool:_shouldJoinSourceLines],
                                                   XDTBasicOptionProtectFile: [NSNumber numberWithBool:_shouldProtectFile]
                                                   }];
    if (![basic parseSourceCode:[self sourceCode] error:error]) {
        return nil;
    }

    [self setGeneratorMessages:basic.messages];
    [self setTokenDump:[basic dumpTokenList:error]];
    
    return basic;
}

@end
