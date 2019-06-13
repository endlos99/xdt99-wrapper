//
//  AssemblerDocument.m
//  SimpleXDT99
//
//  Created by Henrik Wedekind on 07.12.16.
//
//  SimpleXDT99IDE a simple IDE based on xdt99 that shows how to use the XDTools99.framework
//  Copyright © 2016-2019 Henrik Wedekind (aka hackmac). All rights reserved.
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

#import "AssemblerDocument.h"

#import "NSViewAutolayoutAdditions.h"

#import "AppDelegate.h"

#import <XDTools99/XDAssembler.h>


@interface AssemblerDocument ()

@property (retain) IBOutlet NSView *specialLogOptionView;

@property (assign) NSUInteger baseAddress;
@property (readonly) BOOL shouldUseBaseAddress;
@property (retain) NSString *cartridgeName;
@property (readonly) BOOL shouldUseCartName;

@property (nonatomic, assign) NSUInteger outputFormatPopupButtonIndex;

@property (assign) BOOL shouldUseRegisterSymbols;
@property (assign) BOOL shouldBeStrict;
@property (assign, nonatomic) BOOL shouldShowListingInLog;
@property (assign, nonatomic) BOOL shouldShowSymbolsInListing;
@property (assign, nonatomic) BOOL shouldShowSymbolsAsEqus;

@property (retain) XDTAs99Objcode *assemblingResult;
@property (readonly) NSString *listOutput;

@property (readonly) XDTAs99TargetType targetType;
- (BOOL)assembleCode:(XDTAs99TargetType)xdtTargetType error:(NSError **)error;
- (BOOL)exportBinaries:(XDTAs99TargetType)xdtTargetType compressObjectCode:(BOOL)shouldCompressObjectCode error:(NSError **)error;

@end


@implementation AssemblerDocument

- (instancetype)init
{
    self = [super init];
    if (nil == self) {
        return nil;
    }

    /* Setup documents options, before any data can read and processed */
    NSUserDefaults *defaults = [[NSUserDefaultsController sharedUserDefaultsController] defaults];
    [self setShouldUseRegisterSymbols:[defaults boolForKey:UserDefaultKeyAssemblerOptionUseRegisterSymbols]];
    [self setShouldBeStrict:[defaults boolForKey:UserDefaultKeyAssemblerOptionDisableXDTExtensions]];
    [self setShouldShowListingInLog:[defaults boolForKey:UserDefaultKeyAssemblerOptionGenerateListOutput]];
    [self setShouldShowSymbolsInListing:[defaults boolForKey:UserDefaultKeyAssemblerOptionGenerateSymbolTable]];
    [self setShouldShowSymbolsAsEqus:[defaults boolForKey:UserDefaultKeyAssemblerOptionGenerateSymbolsAsEqus]];
    [self setBaseAddress:[defaults integerForKey:UserDefaultKeyAssemblerOptionBaseAddress]];
    [self setOutputFormatPopupButtonIndex:[defaults integerForKey:UserDefaultKeyAssemblerOptionOutputTypePopupIndex]];

    if (![[NSBundle mainBundle] loadNibNamed:@"AssemblerOptionsView" owner:self topLevelObjects:nil]) {
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
    /* Save the latest assembler options to user defaults before closing. */
    NSUserDefaults *defaults = [[NSUserDefaultsController sharedUserDefaultsController] defaults];
    [defaults setBool:[self shouldUseRegisterSymbols] forKey:UserDefaultKeyAssemblerOptionUseRegisterSymbols];
    [defaults setBool:[self shouldBeStrict] forKey:UserDefaultKeyAssemblerOptionDisableXDTExtensions];
    [defaults setBool:_shouldShowListingInLog forKey:UserDefaultKeyAssemblerOptionGenerateListOutput];
    [defaults setBool:_shouldShowSymbolsInListing forKey:UserDefaultKeyAssemblerOptionGenerateSymbolTable];
    [defaults setBool:_shouldShowSymbolsAsEqus forKey:UserDefaultKeyAssemblerOptionGenerateSymbolsAsEqus];
    [defaults setInteger:_outputFormatPopupButtonIndex forKey:UserDefaultKeyAssemblerOptionOutputTypePopupIndex];
    [defaults setInteger:_baseAddress forKey:UserDefaultKeyAssemblerOptionBaseAddress];

    [super canCloseDocumentWithDelegate:delegate shouldCloseSelector:shouldCloseSelector contextInfo:contextInfo];
}


- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError {
    if (![@"Xas99DocumentType" isEqualToString:typeName]) {
        if (outError) {
            *outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:nil];
        }
        return nil;
    }
    NSData *retVal = [[self sourceCode] dataUsingEncoding:NSUTF8StringEncoding];
    return retVal;
}


- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError {
    if (![@"Xas99DocumentType" isEqualToString:typeName]) {
        if (outError) {
            *outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:kPOSIXErrorEFTYPE userInfo:nil];
        }
        return NO;
    }

    [self setSourceCode:[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]];

    [self setCartridgeName:[[[self fileURL] lastPathComponent] stringByDeletingPathExtension]];
    [self setOutputFileName:[_cartridgeName stringByAppendingString:@"-obj"]];
    [self setOutputBasePathURL:[[self fileURL] URLByDeletingLastPathComponent]];
    [self setErrorMessage:@""];

    return YES;
}


#pragma mark - Accessor Methods


+ (NSSet *)keyPathsForValuesAffectingShouldUseBaseAddress
{
    return [NSSet setWithObject:NSStringFromSelector(@selector(outputFormatPopupButtonIndex))];
}


- (BOOL)shouldUseBaseAddress
{
    return (0 == _outputFormatPopupButtonIndex) || (4 == _outputFormatPopupButtonIndex);
}


+ (NSSet *)keyPathsForValuesAffectingShouldUseCartName
{
    return [NSSet setWithObject:NSStringFromSelector(@selector(outputFormatPopupButtonIndex))];
}


- (BOOL)shouldUseCartName
{
    return (8 == _outputFormatPopupButtonIndex);
}


+ (NSSet *)keyPathsForValuesAffectingListOutput
{
    return [NSSet setWithObjects:NSStringFromSelector(@selector(assemblingResult)), NSStringFromSelector(@selector(shouldShowSymbolsInListing)), NSStringFromSelector(@selector(shouldShowSymbolsAsEqus)), nil];
}


- (NSString *)listOutput
{
    NSMutableString *retVal = nil;
    NSError *error = nil;
    if (nil == _assemblingResult) {
        return nil;
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
        return nil;
    }
    return retVal;
}


+ (NSSet<NSString *> *)keyPathsForValuesAffectingValueForKey:(NSString *)key
{
    NSSet *retVal = [super keyPathsForValuesAffectingValueForKey:key];
    if ([NSStringFromSelector(@selector(generatedLogMessage)) isEqualToString:key]) {
        NSMutableSet *newSet = [NSMutableSet setWithSet:retVal];
        [newSet addObject:NSStringFromSelector(@selector(shouldShowListingInLog))];
        [newSet unionSet:[self keyPathsForValuesAffectingListOutput]];
        [newSet removeObject:NSStringFromSelector(@selector(errorMessage))];  /* 'errorMessage' from the super class is overlayed by 'assemblingResult', so remove it */
        retVal = newSet;
    }
    return retVal;
}


- (NSMutableString *)generatedLogMessage
{
    NSMutableString *retVal = [super generatedLogMessage];
    if (nil == retVal || ![self shouldShowLog]) {
        return retVal;
    }

    if (_shouldShowListingInLog) {
        NSString *listOut = [self listOutput];
        if (nil != listOut && 0 < [listOut length]) {
            [retVal appendFormat:@"%@\n", listOut];
        }
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
            [self setOutputFileName:[[[self outputFileName] stringByDeletingPathExtension] stringByAppendingPathExtension:@"image"]];
            break;
        case 1:
        case 2:
            [self setOutputFileName:[[[self outputFileName] stringByDeletingPathExtension] stringByAppendingPathExtension:@"obj"]];
            break;
        case 3:
            [self setOutputFileName:[[[self outputFileName] stringByDeletingPathExtension] stringByAppendingPathExtension:@"xb"]];
            break;
        case 4:
            [self setOutputFileName:[[[self outputFileName] stringByDeletingPathExtension] stringByAppendingPathExtension:@"bin"]];
            break;
        case 5:
        case 6:
        case 7:
            [self setOutputFileName:[[[self outputFileName] stringByDeletingPathExtension] stringByAppendingPathExtension:@"dat"]];
            break;
        case 8:
            [self setOutputFileName:[[[self outputFileName] stringByDeletingPathExtension] stringByAppendingPathExtension:@"card"]];
            [self setBaseAddress:0x6000];
            break;
        /* TODO: Since version 1.7.0 of xas99, there is a new option to export an EQU listing to a text file.
         This feature is open to implement.
         */

        default:
            break;
    }
}


#pragma mark - Action Methods


- (void)checkCode:(id)sender
{
    NSError *error = nil;

    XDTAs99TargetType xdtTargetType = [self targetType];
    if (![self assembleCode:xdtTargetType error:&error]) {
        if (nil != error) {
            if (!self.shouldShowErrorsInLog || !self.shouldShowLog) {
                [self presentError:error modalForWindow:[self windowForSheet] delegate:nil didPresentSelector:nil contextInfo:nil];
            }
            return;
        }
    }
}


- (void)generateCode:(id)sender
{
    NSError *error = nil;

    BOOL shouldCompressObjectCode = 1 == _outputFormatPopupButtonIndex;
    XDTAs99TargetType xdtTargetType = [self targetType];
    if (![self assembleCode:xdtTargetType error:&error] || nil != error ||
        ![self exportBinaries:xdtTargetType compressObjectCode:shouldCompressObjectCode error:&error] || nil != error) {
        if (nil != error) {
            if (!self.shouldShowErrorsInLog || !self.shouldShowLog) {
                [self presentError:error modalForWindow:[self windowForSheet] delegate:nil didPresentSelector:nil contextInfo:nil];
            }
            return;
        }
    }
}


#pragma mark - Private Methods


+ (NSSet *)keyPathsForValuesAffectingTargetType
{
    return [NSSet setWithObject:NSStringFromSelector(@selector(outputFormatPopupButtonIndex))];
}


- (XDTAs99TargetType)targetType
{
    XDTAs99TargetType xdtTargetType = XDTAs99TargetTypeObjectCode;
    switch (_outputFormatPopupButtonIndex) {
        case 0:
            xdtTargetType = XDTAs99TargetTypeProgramImage;
            break;
        case 1:
        case 2:
            xdtTargetType = XDTAs99TargetTypeObjectCode;
            break;
        case 3:
            xdtTargetType = XDTAs99TargetTypeEmbededXBasic;
            break;
        case 4:
            xdtTargetType = XDTAs99TargetTypeRawBinary;
            break;
        case 5:
            xdtTargetType = XDTAs99TargetTypeTextBinaryAsm;
            break;
        case 6:
            xdtTargetType = XDTAs99TargetTypeTextBinaryBas;
            break;
        case 7:
            xdtTargetType = XDTAs99TargetTypeTextBinaryC;
            break;
        case 8:
            xdtTargetType = XDTAs99TargetTypeMESSCartridge;
            break;
        /* TODO: Since version 1.7.0 of xas99, there is a new option to export an EQU listing to a text file.
         This feature is open to implement.
         */

        default:
            break;
    }
    return xdtTargetType;
}


- (BOOL)assembleCode:(XDTAs99TargetType)xdtTargetType error:(NSError **)error
{
    if (nil == [self fileURL]) {    // there must be a file which can be assembled
        return NO;
    }
    NSDictionary *options = @{
                              XDTAs99OptionRegister: [NSNumber numberWithBool:[self shouldUseRegisterSymbols]],
                              XDTAs99OptionStrict: [NSNumber numberWithBool:[self shouldBeStrict]],
                              XDTAs99OptionTarget: [NSNumber numberWithUnsignedInteger:xdtTargetType],
                              XDTAs99OptionWarnings: [NSNumber numberWithBool:[self shouldShowWarningsInLog]]
                              };
    XDTAssembler *assembler = [XDTAssembler assemblerWithOptions:options includeURL:[self fileURL]];

    XDTAs99Objcode *result = [assembler assembleSourceFile:[self fileURL] error:error];
    if (nil != error && nil != *error) {
        if (nil == [*error localizedFailureReason]) {
            [self setErrorMessage:[NSString stringWithFormat:@"%@:\n", [*error localizedDescription]]];
        } else {
            [self setErrorMessage:[NSString stringWithFormat:@"%@:\n%@\n", [*error localizedDescription], [*error localizedFailureReason]]];
        }
        [self setAssemblingResult:result];

        return NO;
    }
    [self setErrorMessage:@""];
    if (0 < assembler.warnings.count) {
        [self setWarningMessage:[assembler.warnings componentsJoinedByString:@"\n"]];
    } else {
        [self setWarningMessage:@""];
    }
    [self setAssemblingResult:result];

    return YES;
}


- (BOOL)exportBinaries:(XDTAs99TargetType)xdtTargetType compressObjectCode:(BOOL)shouldCompressObjectCode error:(NSError **)error
{
    BOOL retVal = YES;

    XDTGenerateTextMode mode = 0;

    switch (xdtTargetType) {
        case XDTAs99TargetTypeProgramImage: {
            NSString *newOutpuFileName = [self outputFileName];
            for (NSData *data in [_assemblingResult generateImageAt:_baseAddress error:error]) {
                if ((nil != error && nil != *error) || nil == data) {
                    retVal = NO;
                    break;
                }
                NSURL *newOutpuFileURL = [NSURL fileURLWithPath:newOutpuFileName relativeToURL:[self outputBasePathURL]];
                [data writeToURL:newOutpuFileURL options:NSDataWritingAtomic error:error];
                if (nil != error && nil != *error) {
                    retVal = NO;
                    break;
                }

                NSString *fileName = [NSMutableString stringWithString:[newOutpuFileName stringByDeletingPathExtension]];
                unichar nextChar = [fileName characterAtIndex:[fileName length]-1] + 1;
                newOutpuFileName = [[[fileName substringToIndex:[fileName length]-1] stringByAppendingFormat:@"%c", nextChar] stringByAppendingPathExtension:[newOutpuFileName pathExtension]];
            }
            break;
        }
        case XDTAs99TargetTypeRawBinary: {
            for (NSArray<id> *element in [_assemblingResult generateRawBinaryAt:_baseAddress error:error]) {
                if ((nil != error && nil != *error) || nil == element) {
                    retVal = NO;
                    break;
                }
                NSNumber *address = [element objectAtIndex:0];
                NSNumber *bank = [element objectAtIndex:1];
                NSData *data = [element objectAtIndex:2];

                NSString *fileNameAddition = nil;
                if ([bank isMemberOfClass:[NSNull class]]) {
                    fileNameAddition = [NSString stringWithFormat:@"_%04x", (unsigned int)[address longValue]];
                } else {
                    fileNameAddition = [NSString stringWithFormat:@"_%04x_b%d", (unsigned int)[address longValue], (int)[bank longValue]];
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
        }
        case XDTAs99TargetTypeTextBinaryC:
            if (0 == mode) {
                mode = XDTGenerateTextModeOutputC;
            }
        case XDTAs99TargetTypeTextBinaryBas:
            if (0 == mode) {
                mode = XDTGenerateTextModeOutputBasic;
            }
        case XDTAs99TargetTypeTextBinaryAsm: {
            if (0 == mode) {
                mode = XDTGenerateTextModeOutputAssembler;
            }

            NSError *tempError = nil;
            // TODO: extend GUI for new configuration options
            NSString *fileContent = [_assemblingResult generateTextAt:_baseAddress
                                                             withMode:mode + XDTGenerateTextModeOptionWord
                                                                error:&tempError];
            if (nil == tempError && nil != fileContent && [fileContent length] > 0) {
                NSURL *newOutpuFileURL = [NSURL fileURLWithPath:[self outputFileName] relativeToURL:[self outputBasePathURL]];
                [fileContent writeToURL:newOutpuFileURL atomically:YES encoding:NSUTF8StringEncoding error:&tempError];
            } else {
                retVal = NO;
            }
            if (nil != error) {
                *error = tempError;
            }
            break;
        }
        case XDTAs99TargetTypeObjectCode: {
            NSData *data = [_assemblingResult generateObjCode:shouldCompressObjectCode error:error];
            if ((nil != error && nil != *error) || nil == data) {
                retVal = NO;
                break;
            }
            NSURL *newOutputFileURL = [NSURL fileURLWithPath:[self outputFileName] relativeToURL:[self outputBasePathURL]];
            [data writeToURL:newOutputFileURL options:NSDataWritingAtomic error:error];
            retVal = nil != error && nil == *error;
            break;
        }
        case XDTAs99TargetTypeEmbededXBasic: {
            NSData *data = [_assemblingResult generateBasicLoader:error];
            if ((nil != error && nil != *error) || nil == data) {
                retVal = NO;
                break;
            }
            NSURL *newOutputFileURL = [NSURL fileURLWithPath:[self outputFileName] relativeToURL:[self outputBasePathURL]];
            [data writeToURL:newOutputFileURL options:NSDataWritingAtomic error:error];
            retVal = nil != error && nil == *error;
            break;
        }
        case XDTAs99TargetTypeMESSCartridge: {
            if (nil == _cartridgeName || [_cartridgeName length] == 0) {
                NSDictionary *errorDict = @{
                                            NSLocalizedDescriptionKey: NSLocalizedString(@"Missing Option!", @"Error description of a missing option."),
                                            NSLocalizedRecoverySuggestionErrorKey: NSLocalizedString(@"The cartridge name is missing! Please specify a name of the cartridge to create!", @"Explanation for an error of a missing cartridge name option.")
                                            };
                NSError *missingOptionError = [NSError errorWithDomain:XDTErrorDomain code:XDTErrorCodeToolException userInfo:errorDict];
                [self setErrorMessage:[NSString stringWithFormat:@"%@\n%@", [missingOptionError localizedDescription], [missingOptionError localizedFailureReason]]];
                retVal = NO;
                if (nil != error) {
                    *error = missingOptionError;
                }
                break;
            }

            NSURL *newOutputFileURL = [NSURL fileURLWithPath:[self outputFileName] relativeToURL:[self outputBasePathURL]];
            XDTZipFile *zipfile = [XDTZipFile zipFileForWritingToURL:newOutputFileURL error:error];
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
        /* TODO: Since version 1.7.0 of xas99, there is a new option to export an EQU listing to a text file.
         This feature is open to implement.
         */

        default:
            break;
    }

    if (nil != error && nil != *error) {
        if (nil == [*error localizedFailureReason]) {
            [self setErrorMessage:[NSString stringWithFormat:@"%@:\n", [*error localizedDescription]]];
        } else {
            [self setErrorMessage:[NSString stringWithFormat:@"%@:\n%@\n", [*error localizedDescription], [*error localizedFailureReason]]];
        }

        return retVal;
    }
    [self setErrorMessage:@""];

    return retVal;
}

@end
