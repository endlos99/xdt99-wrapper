//
//  AssemblerDocument.m
//  SimpleXDT99
//
//  Created by Henrik Wedekind on 07.12.16.
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

#import "AssemblerDocument.h"

#import "NSViewAutolayoutAdditions.h"

#import "AppDelegate.h"

#import <XDTools99/XDAssembler.h>


@interface AssemblerDocument ()

@property (assign) IBOutlet NSView *specialLogOptionView;

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

@property (retain) XDTObjcode *assemblingResult;
@property (readonly) NSString *listOutput;

@property (readonly) XDTAssemblerTargetType targetType;
- (BOOL)assembleCode:(XDTAssemblerTargetType)xdtTargetType error:(NSError **)error;
- (BOOL)exportBinaries:(XDTAssemblerTargetType)xdtTargetType compressObjectCode:(BOOL)shouldCompressObjectCode error:(NSError **)error;

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
    }
    NSData *retVal = [[self sourceCode] dataUsingEncoding:NSUTF8StringEncoding];
    return retVal;
}


- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError {
    if (![@"Xas99DocumentType" isEqualToString:typeName]) {
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


#pragma mark - Accessor Methods


+ (NSSet *)keyPathsForValuesAffectingShouldUseBaseAddress
{
    return [NSSet setWithObject:@"outputFormatPopupButtonIndex"];
}


- (BOOL)shouldUseBaseAddress
{
    return (0 == _outputFormatPopupButtonIndex) || (4 == _outputFormatPopupButtonIndex);
}


+ (NSSet *)keyPathsForValuesAffectingShouldUseCartName
{
    return [NSSet setWithObject:@"outputFormatPopupButtonIndex"];
}


- (BOOL)shouldUseCartName
{
    return (6 == _outputFormatPopupButtonIndex);
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
            [self setOutputFileName:[[[self outputFileName] stringByDeletingPathExtension] stringByAppendingPathExtension:@"js"]];
            break;
        case 6:
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

    XDTAssemblerTargetType xdtTargetType = [self targetType];
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

    BOOL shouldCompressObjectCode = 1 == _outputFormatPopupButtonIndex;
    XDTAssemblerTargetType xdtTargetType = [self targetType];
    if (![self assembleCode:xdtTargetType error:&error] || nil != error || ![self exportBinaries:xdtTargetType compressObjectCode:shouldCompressObjectCode error:&error]) {
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


- (XDTAssemblerTargetType)targetType
{
    XDTAssemblerTargetType xdtTargetType = XDTAssemblerTargetTypeObjectCode;
    switch (_outputFormatPopupButtonIndex) {
        case 0:
            xdtTargetType = XDTAssemblerTargetTypeProgramImage;
            break;
        case 1:
        case 2:
            xdtTargetType = XDTAssemblerTargetTypeObjectCode;
            break;
        case 3:
            xdtTargetType = XDTAssemblerTargetTypeEmbededXBasic;
            break;
        case 4:
            xdtTargetType = XDTAssemblerTargetTypeRawBinary;
            break;
        case 5:
            xdtTargetType = XDTAssemblerTargetTypeTextBinary;
            break;
        case 6:
            xdtTargetType = XDTAssemblerTargetTypeJumpstart;
            break;
        case 7:
            xdtTargetType = XDTAssemblerTargetTypeMESSCartridge;
            break;
        /* TODO: Since version 1.7.0 of xas99, there is a new option to export an EQU listing to a text file.
         This feature is open to implement.
         */

        default:
            break;
    }
    return xdtTargetType;
}


- (BOOL)assembleCode:(XDTAssemblerTargetType)xdtTargetType error:(NSError **)error
{
    NSDictionary *options = @{
                              XDTAssemblerOptionRegister: [NSNumber numberWithBool:[self shouldUseRegisterSymbols]],
                              XDTAssemblerOptionStrict: [NSNumber numberWithBool:[self shouldBeStrict]],
                              XDTAssemblerOptionTarget: [NSNumber numberWithUnsignedInteger:xdtTargetType]
                              };
    XDTAssembler *assembler = [XDTAssembler assemblerWithOptions:options includeURL:[self fileURL]];

    XDTObjcode *result = [assembler assembleSourceFile:[self fileURL] error:error];
    if (nil != error && nil != *error) {
        [self setErrorMessage:[NSString stringWithFormat:@"%@\n%@\n", [*error localizedDescription], [*error localizedFailureReason]]];
        [self setAssemblingResult:result];

        return NO;
    }
    [self setErrorMessage:@"No errors found!\n"];
    [self setAssemblingResult:result];

    return YES;
}


- (BOOL)exportBinaries:(XDTAssemblerTargetType)xdtTargetType compressObjectCode:(BOOL)shouldCompressObjectCode error:(NSError **)error
{
    BOOL retVal = YES;

    switch (xdtTargetType) {
        case XDTAssemblerTargetTypeProgramImage: {
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
        case XDTAssemblerTargetTypeRawBinary: {
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
        case XDTAssemblerTargetTypeTextBinary: {
            NSError *tempError = nil;
            NSMutableString *fileContent = [NSMutableString string];
            for (NSArray<id> *element in [_assemblingResult generateRawBinaryAt:_baseAddress error:&tempError]) {
                if (nil != tempError || nil == element) {
                    break;
                }
                NSNumber *address = [element objectAtIndex:0];
                //NSNumber *bank = [element objectAtIndex:1];
                NSData *data = [element objectAtIndex:2];

                [fileContent appendFormat:@"\n;      aorg >%04x", (unsigned int)[address longValue]];
                NSUInteger i = 0;
                while (i < [data length]) {
                    uint8 row[8];
                    NSRange byteRange = NSMakeRange(i, MIN([data length] - i, 8));
                    [data getBytes:row range:byteRange];
                    i += byteRange.length;
                    
                    NSMutableArray<NSString *> *bytes = [NSMutableArray arrayWithCapacity:8];
                    for (int b = 0; b < byteRange.length; b++) {
                        [bytes addObject:[NSString stringWithFormat:@">%02x", row[b]]];
                    }
                    [fileContent appendFormat:@"\n       byte %@", [bytes componentsJoinedByString:@", "]];
                }
            }
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
        case XDTAssemblerTargetTypeObjectCode: {
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
        case XDTAssemblerTargetTypeEmbededXBasic: {
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
        case XDTAssemblerTargetTypeJumpstart: {
            NSData *data = [_assemblingResult generateJumpstart:error];
            if ((nil != error && nil != *error) || nil == data) {
                retVal = NO;
                break;
            }
            NSURL *newOutputFileURL = [NSURL URLWithString:[self outputFileName] relativeToURL:[self outputBasePathURL]];
            [data writeToURL:newOutputFileURL options:NSDataWritingAtomic error:error];
            retVal = nil != error && nil == *error;
            break;
        }
        case XDTAssemblerTargetTypeMESSCartridge: {
            if (nil == _cartridgeName || [_cartridgeName length] == 0) {
                NSDictionary *errorDict = @{
                                            NSLocalizedDescriptionKey: NSLocalizedString(@"Missing Option!", @"Error description of a missing option."),
                                            NSLocalizedRecoverySuggestionErrorKey: NSLocalizedString(@"The cartridge name is missing! Please specify a name of the cartridge to create!", @"Explanation for an error of a missing cartridge name option.")
                                            };
                NSError *missingOptionError = [NSError errorWithDomain:XDTErrorDomain code:-1 userInfo:errorDict];
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

    return retVal;
}

@end
