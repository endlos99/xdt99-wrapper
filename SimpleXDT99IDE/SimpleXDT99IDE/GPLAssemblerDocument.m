//
//  GPLAssemblerDocument.m
//  SimpleXDT99IDE
//
//  Created by Henrik Wedekind on 16.12.16.
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

#import "GPLAssemblerDocument.h"

#import "NSViewAutolayoutAdditions.h"

#import "AppDelegate.h"

#import <XDTools99/XDGPL.h>


@interface GPLAssemblerDocument ()

@property (assign) IBOutlet NSView *specialLogOptionView;

@property (assign) NSUInteger gromAddress;
@property (assign) NSUInteger aorgAddress;
@property (retain) NSString *cartridgeName;
@property (readonly) BOOL shouldUseCartName;

@property (nonatomic, assign) NSUInteger outputFormatPopupButtonIndex;
@property (nonatomic, assign) NSUInteger syntaxFormatPopupButtonIndex;
@property (assign, nonatomic) BOOL shouldShowListingInLog;
@property (assign, nonatomic) BOOL shouldShowSymbolsInListing;
@property (assign, nonatomic) BOOL shouldShowSymbolsAsEqus;

@property (retain) XDTGPLObjcode *assemblingResult;
@property (readonly) NSString *listOutput;

@property (readonly) XDTGPLAssemblerTargetType targetType;
@property (readonly) XDTGPLAssemblerSyntaxType syntaxType;

- (BOOL)assembleCode:(XDTGPLAssemblerTargetType)xdtTargetType error:(NSError **)error;
- (BOOL)exportBinaries:(XDTGPLAssemblerTargetType)xdtTargetType error:(NSError **)error;

@end


@implementation GPLAssemblerDocument

- (instancetype)init
{
    self = [super init];
    if (nil == self) {
        return nil;
    }

    /* Setup documents options, before any data can read and processed */
    NSUserDefaults *defaults = [[NSUserDefaultsController sharedUserDefaultsController] defaults];
    [self setOutputFormatPopupButtonIndex:[defaults integerForKey:UserDefaultKeyGPLOptionOutputTypePopupIndex]];
    [self setSyntaxFormatPopupButtonIndex:[defaults integerForKey:UserDefaultKeyGPLOptionSyntaxTypePopupIndex]];
    [self setShouldShowListingInLog:[defaults boolForKey:UserDefaultKeyGPLOptionGenerateListOutput]];
    [self setShouldShowSymbolsInListing:[defaults boolForKey:UserDefaultKeyGPLOptionGenerateSymbolTable]];
    [self setShouldShowSymbolsAsEqus:[defaults boolForKey:UserDefaultKeyGPLOptionGenerateSymbolsAsEqus]];
    [self setAorgAddress:[defaults integerForKey:UserDefaultKeyGPLOptionAORGAddress]];
    [self setGromAddress:[defaults integerForKey:UserDefaultKeyGPLOptionGROMAddress]];

    if (![[NSBundle mainBundle] loadNibNamed:@"GPLAssemblerOptionsView" owner:self topLevelObjects:nil]) {
#if !__has_feature(objc_arc)
        [self release];
#endif
        return nil;
    }
    _assemblingResult = nil;
    _cartridgeName = nil;

    return self;
}


- (void)dealloc
{
#if !__has_feature(objc_arc)
    [_assemblingResult release];
    [_cartridgeName release];

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
    /* Save the latest GPL Assembler options to user defaults before closing. */
    NSUserDefaults *defaults = [[NSUserDefaultsController sharedUserDefaultsController] defaults];
    [defaults setInteger:_outputFormatPopupButtonIndex forKey:UserDefaultKeyGPLOptionOutputTypePopupIndex];
    [defaults setInteger:_syntaxFormatPopupButtonIndex forKey:UserDefaultKeyGPLOptionSyntaxTypePopupIndex];
    [defaults setBool:_shouldShowListingInLog forKey:UserDefaultKeyGPLOptionGenerateListOutput];
    [defaults setBool:_shouldShowSymbolsInListing forKey:UserDefaultKeyGPLOptionGenerateSymbolTable];
    [defaults setBool:_shouldShowSymbolsAsEqus forKey:UserDefaultKeyGPLOptionGenerateSymbolsAsEqus];
    [defaults setInteger:_aorgAddress forKey:UserDefaultKeyGPLOptionAORGAddress];
    [defaults setInteger:_gromAddress forKey:UserDefaultKeyGPLOptionGROMAddress];

    [super canCloseDocumentWithDelegate:delegate shouldCloseSelector:shouldCloseSelector contextInfo:contextInfo];
}


- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError {
    if (![@"Xga99DocumentType" isEqualToString:typeName]) {
        if (outError) {
            *outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:nil];
        }
    }
    NSData *retVal = [[self sourceCode] dataUsingEncoding:NSUTF8StringEncoding];
    return retVal;
}


- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError {
    if (![@"Xga99DocumentType" isEqualToString:typeName]) {
        if (outError) {
            *outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:nil];
        }
    }

    [self setSourceCode:[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]];

    [self setCartridgeName:[[[self fileURL] lastPathComponent] stringByDeletingPathExtension]];
    [self setOutputFileName:[_cartridgeName stringByAppendingString:@"-obj"]];
    [self setOutputBasePathURL:[[self fileURL] URLByDeletingLastPathComponent]];

    [self checkCode:nil];
    return YES;
}


+ (BOOL)autosavesInPlace {
    return YES;
}


#pragma mark - Accessor Methods


+ (NSSet *)keyPathsForValuesAffectingShouldUseCartName
{
    return [NSSet setWithObject:@"outputFormatPopupButtonIndex"];
}


- (BOOL)shouldUseCartName
{
    return (1 == _outputFormatPopupButtonIndex) || (2 == _outputFormatPopupButtonIndex);
}


+ (NSSet *)keyPathsForValuesAffectingListOutput
{
    return [NSSet setWithObjects:@"assemblingResult", @"shouldShowSymbolsInListing", @"shouldShowSymbolsAsEqus", nil];
}


- (NSString *)listOutput
{
    NSMutableString *retVal = nil;
    NSError *error = nil;
    if (nil == _assemblingResult) {
        return @"";
    }

    NSData *data = [_assemblingResult generateListing:_shouldShowSymbolsInListing && !_shouldShowSymbolsAsEqus error:&error];
    if (nil == error && nil != data) {
        retVal = [[NSMutableString alloc] initWithData:data encoding:NSUTF8StringEncoding];
#if !__has_feature(objc_arc)
        [retVal autorelease];
#endif
        if (_shouldShowSymbolsInListing && _shouldShowSymbolsAsEqus) {
            data = [_assemblingResult generateSymbols:YES error:&error];
            if (nil == error && nil != data) {
                [retVal appendFormat:@"\n%@\n", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]];
            }
        }
    }
    if (nil != error) {
        [self presentError:error modalForWindow:[self windowForSheet] delegate:nil didPresentSelector:nil contextInfo:nil];
        return @"";
    }
    return retVal;
}


+ (NSSet<NSString *> *)keyPathsForValuesAffectingValueForKey:(NSString *)key
{
    NSSet *retVal = [super keyPathsForValuesAffectingValueForKey:key];
    if ([@"generatedLogMessage" isEqualToString:key]) {
        NSMutableSet *newSet = [NSMutableSet setWithSet:retVal];
        [newSet addObject:@"shouldShowListingInLog"];
        [newSet unionSet:[self keyPathsForValuesAffectingListOutput]];
        [newSet removeObject:@"errorMessage"];  /* 'errorMessage' from the super class is overlayed by 'assemblingResult', so remove it */
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
    if ([self shouldShowErrorsInLog]) {
        [retVal appendFormat:@"%@\n", [self errorMessage]];
    }
    if (_shouldShowListingInLog) {
        [retVal appendFormat:@"%@\n", [self listOutput]];
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
        case 0: /* Plain GPL byte code */
            [self setOutputFileName:[[[self outputFileName] stringByDeletingPathExtension] stringByAppendingPathExtension:@"gbc"]];
            break;
        case 1: /* Image: GPL with header */
            [self setOutputFileName:[[[self outputFileName] stringByDeletingPathExtension] stringByAppendingPathExtension:@"bin"]];
            break;
        case 2: /* MESS cartridge */
            [self setOutputFileName:[[[self outputFileName] stringByDeletingPathExtension] stringByAppendingPathExtension:@"rpk"]];
            break;

        default:
            break;
    }
}


#pragma mark - Action Methods


- (void)checkCode:(id)sender
{
    NSError *error = nil;

    XDTGPLAssemblerTargetType xdtTargetType = [self targetType];
    if (![self assembleCode:xdtTargetType error:&error]) {
        if (nil != error) {
            [self presentError:error modalForWindow:[self windowForSheet] delegate:nil didPresentSelector:nil contextInfo:nil];
            return;
        }
    }
}


- (void)generateCode:(id)sender
{
    NSError *error = nil;

    XDTGPLAssemblerTargetType xdtTargetType = [self targetType];
    if (![self assembleCode:xdtTargetType error:&error] || nil != error || ![self exportBinaries:xdtTargetType error:&error]) {
        if (nil != error) {
            [self presentError:error modalForWindow:[self windowForSheet] delegate:nil didPresentSelector:nil contextInfo:nil];
            return;
        }
    }
}


#pragma mark - Private Methods


+ (NSSet *)keyPathsForValuesAffectingTargetType
{
    return [NSSet setWithObject:@"outputFormatPopupButtonIndex"];
}


- (XDTGPLAssemblerTargetType)targetType
{
    XDTGPLAssemblerTargetType xdtTargetType = XDTGPLAssemblerTargetTypePlainByteCode;
    switch (_outputFormatPopupButtonIndex) {
        case 0:
            xdtTargetType = XDTGPLAssemblerTargetTypePlainByteCode;
            break;
        case 1:
            xdtTargetType = XDTGPLAssemblerTargetTypeHeaderedByteCode;
            break;
        case 2:
            xdtTargetType = XDTGPLAssemblerTargetTypeMESSCartridge;
            break;

        default:
            break;
    }
    return xdtTargetType;
}


+ (NSSet *)keyPathsForValuesAffectingSyntaxType
{
    return [NSSet setWithObject:@"syntaxFormatPopupButtonIndex"];
}


- (XDTGPLAssemblerTargetType)syntaxType
{
    XDTGPLAssemblerTargetType xdtSyntaxType = XDTGPLAssemblerSyntaxTypeNativeXDT99;
    switch (_syntaxFormatPopupButtonIndex) {
        case 0:
            xdtSyntaxType = XDTGPLAssemblerSyntaxTypeNativeXDT99;
            break;
        case 1:
            xdtSyntaxType = XDTGPLAssemblerSyntaxTypeRAGGPL;
            break;
        case 2:
            xdtSyntaxType = XDTGPLAssemblerSyntaxTypeTIImageTool;
            break;

        default:
            break;
    }
    return xdtSyntaxType;
}


- (BOOL)assembleCode:(XDTGPLAssemblerTargetType)xdtTargetType error:(NSError **)error
{
    NSDictionary *options = @{
                              XDTGPLAssemblerOptionAORG: [NSNumber numberWithUnsignedInteger:[self aorgAddress]],
                              XDTGPLAssemblerOptionGROM: [NSNumber numberWithUnsignedInteger:[self gromAddress]],
                              XDTGPLAssemblerOptionStyle: [NSNumber numberWithUnsignedInteger:[self syntaxType]],
                              XDTGPLAssemblerOptionTarget: [NSNumber numberWithUnsignedInteger:[self targetType]]
                              };
    XDTGPLAssembler *assembler = [XDTGPLAssembler gplAssemblerWithOptions:options includeURL:[self fileURL]];

    XDTGPLObjcode *result = [assembler assembleSourceFile:[self fileURL] error:error];
    if (nil != error && nil != *error) {
        [self setErrorMessage:[NSString stringWithFormat:@"%@\n%@\n", [*error localizedDescription], [*error localizedFailureReason]]];
        [self setAssemblingResult:result];

        return NO;
    }
    [self setErrorMessage:@"No errors found!\n"];
    [self setAssemblingResult:result];

    return YES;
}


- (BOOL)exportBinaries:(XDTGPLAssemblerTargetType)xdtTargetType error:(NSError **)error
{
    BOOL retVal = YES;

    switch (xdtTargetType) {
        case XDTGPLAssemblerTargetTypePlainByteCode:    /* byte code */
            for (NSArray<id> *element in [_assemblingResult generateByteCode:error]) {
                if ((nil != error && nil != *error) || nil == element) {
                    retVal = NO;
                    break;
                }
                NSNumber *address = [element objectAtIndex:0];
                NSNumber *base = [element objectAtIndex:1];
                NSData *data = [element objectAtIndex:2];

                NSString *fileNameAddition = nil;
                if ([base isMemberOfClass:[NSNull class]]) {
                    fileNameAddition = [NSString stringWithFormat:@"_%04x", (unsigned int)[address longValue]];
                } else {
                    fileNameAddition = [NSString stringWithFormat:@"_%04x_b%d", (unsigned int)[address longValue], (int)[base longValue]];
                }
                NSURL *newOutputFileURL = [NSURL fileURLWithPath:[[[[self outputFileName] stringByDeletingPathExtension] stringByAppendingString:fileNameAddition] stringByAppendingPathExtension:[[self outputFileName] pathExtension]]
                                                 relativeToURL:[self outputBasePathURL]];
                [data writeToURL:newOutputFileURL options:NSDataWritingAtomic error:error];
                if (nil != error && nil != *error) {
                    retVal = NO;
                    break;
                }
            }
            break;

        case XDTGPLAssemblerTargetTypeHeaderedByteCode: { /* image */
            if (nil == _cartridgeName || [_cartridgeName length] == 0) {
                NSDictionary *errorDict = @{
                                            NSLocalizedDescriptionKey: @"Missing Option!",
                                            NSLocalizedRecoverySuggestionErrorKey: @"Please specify a name of the cartridge to create!"
                                            };
                NSError *missingOptionError = [NSError errorWithDomain:XDTErrorDomain code:-1 userInfo:errorDict];
                [self setErrorMessage:[NSString stringWithFormat:@"%@\n%@", [missingOptionError localizedDescription], [missingOptionError localizedFailureReason]]];
                retVal = NO;
                if (nil != error) {
                    *error = missingOptionError;
                }
                break;
            }

            NSData *data = [_assemblingResult generateImageWithName:_cartridgeName error:error];
            if ((nil != error && nil == *error) && nil != data) {
                NSURL *newOutpuFileURL = [NSURL fileURLWithPath:[self outputFileName] relativeToURL:[self outputBasePathURL]];
                [data writeToURL:newOutpuFileURL options:NSDataWritingAtomic error:error];
            }
            retVal = nil != error && nil == *error;
            break;
        }

        case XDTGPLAssemblerTargetTypeMESSCartridge: {
            if (nil == _cartridgeName || [_cartridgeName length] == 0) {
                NSDictionary *errorDict = @{
                                            NSLocalizedDescriptionKey: @"Missing Option!",
                                            NSLocalizedRecoverySuggestionErrorKey: @"Please specify a name of the cartridge to create!"
                                            };
                NSError *missingOptionError = [NSError errorWithDomain:XDTErrorDomain code:-1 userInfo:errorDict];
                [self setErrorMessage:[NSString stringWithFormat:@"%@\n%@", [missingOptionError localizedDescription], [missingOptionError localizedFailureReason]]];
                retVal = NO;
                if (nil != error) {
                    *error = missingOptionError;
                }
                break;
            }

            XDTZipFile *zipfile = [XDTZipFile zipFileForWritingToURL:[NSURL fileURLWithPath:[self outputFileName] relativeToURL:[self outputBasePathURL]] error:error];
            if ((nil != error && nil != *error) || nil == zipfile) {
                retVal = NO;
                break;
            }

            NSDictionary *tripel = [_assemblingResult generateMESSCartridgeWithName:_cartridgeName error:error];
            if ((nil != error && nil != *error) || nil == tripel) {
                retVal = NO;
                break;
            }
            for (NSString *fName in [tripel keyEnumerator]) {
                NSData *data = [tripel objectForKey:fName];
                [zipfile writeFile:fName withData:data error:error];
                if (nil != error && nil != *error) {
                    retVal = NO;
                    break;
                }
            }
            break;
        }

        default:
            break;
    }

    return retVal;
}


@end
