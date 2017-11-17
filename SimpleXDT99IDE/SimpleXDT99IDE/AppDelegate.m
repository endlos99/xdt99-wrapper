//
//  AppDelegate.m
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

#import "AppDelegate.h"

#import "XDTAssembler.h"
#import "XDTObjcode.h"
#import "XDTZipFile.h"
#import <XDTools99/XDBasic.h>
#import <XDTools99/XDGPL.h>


NS_ASSUME_NONNULL_BEGIN
@interface AppDelegate ()

/* Three views for save panel */
@property IBOutlet NSView *assemblerOptionsView;
@property IBOutlet NSView *gplAssemblerOptionsView;
@property IBOutlet NSView *basicOptionsView;

@property (assign) NSView *actualOptionsView;

@property IBOutlet NSPopUpButton *assemblerOutputTypePopUpButton;
@property IBOutlet NSTextField *assemblerCartridgeNameTextFiled;
@property IBOutlet NSTextField *gplCartridgeNameTextFiled;

@property (readonly) BOOL shouldCartridgeNameActivated;
@property (readonly) BOOL shouldBaseAddressActivated;

- (IBAction)runAssembler:(nullable id)sender;
- (IBAction)runGPLAssembler:(nullable id)sender;
- (IBAction)runBasicEncoder:(nullable id)sender;

- (nullable NSURL *)selectInputFileWithExtension:(NSString *)extension;

- (void)panel:(NSSavePanel *)panel didChangeAssemblerOutputType:(NSInteger) outputFileType;
- (void)panel:(NSSavePanel *)panel didChangeGPLOutputType:(NSInteger) outputFileType;
- (void)panel:(NSSavePanel *)panel didChangeBasicOutputType:(NSInteger) outputFileType;

- (BOOL)processSourceFileURL:(NSURL *)sourceFile withXDTprocess:(BOOL(^)(NSURL *outputFileURL))process;

@end
NS_ASSUME_NONNULL_END


@implementation AppDelegate

#pragma mark - NSApplicationDelegate Methods


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    NSDictionary *defaultsDict = @{
                                   UserDefaultKeyDocumentOptionShowLog: @YES,
                                   UserDefaultKeyDocumentOptionShowErrorsInLog: @YES,

                                   UserDefaultKeyAssemblerOptionOutputTypePopupIndex: @1,
                                   UserDefaultKeyAssemblerOptionDisableXDTExtensions: @NO,
                                   UserDefaultKeyAssemblerOptionUseRegisterSymbols: @YES,
                                   UserDefaultKeyAssemblerOptionGenerateListOutput: @NO,
                                   UserDefaultKeyAssemblerOptionGenerateSymbolTable: @NO,
                                   UserDefaultKeyAssemblerOptionGenerateSymbolsAsEqus: @NO,
                                   UserDefaultKeyAssemblerOptionBaseAddress: [NSNumber numberWithInteger:0xa000],

                                   UserDefaultKeyBasicOptionOutputTypePopupIndex: @1,
                                   UserDefaultKeyBasicOptionShouldProtectFile: @NO,
                                   UserDefaultKeyBasicOptionShouldJoinSourceLines: @NO,

                                   UserDefaultKeyGPLOptionOutputTypePopupIndex: @1,
                                   UserDefaultKeyGPLOptionSyntaxTypePopupIndex: @1,
                                   UserDefaultKeyGPLOptionAORGAddress: @0x0030,
                                   UserDefaultKeyGPLOptionGROMAddress: @0x6000
                                   };
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaultsDict];
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}


#pragma mark - Menu Action Methods


- (IBAction)runAssembler:(nullable id)sender
{
    NSURL *assemblerFileURL = [self selectInputFileWithExtension:@"a99"];
    if (nil == assemblerFileURL) {
        return;
    }

    _actualOptionsView = _assemblerOptionsView;
    [self processSourceFileURL:assemblerFileURL withXDTprocess:^BOOL(NSURL *outputFileURL) {
        NSUserDefaults *defaults = [[NSUserDefaultsController sharedUserDefaultsController] defaults];
        NSInteger selectedTypeIndenx = [defaults integerForKey:UserDefaultKeyAssemblerOptionOutputTypePopupIndex];
        XDTAssemblerTargetType xdtTargetType = XDTAssemblerTargetTypeObjectCode;
        BOOL compressedObjectCode = NO;
        switch (selectedTypeIndenx) {
            case 0:
                xdtTargetType = XDTAssemblerTargetTypeProgramImage;
                break;
            case 1:
            case 2:
                xdtTargetType = XDTAssemblerTargetTypeObjectCode;
                compressedObjectCode = selectedTypeIndenx == 1;
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
        NSDictionary *options = @{
                                  XDTAssemblerOptionRegister: [defaults objectForKey:UserDefaultKeyAssemblerOptionUseRegisterSymbols],
                                  XDTAssemblerOptionStrict: [defaults objectForKey:UserDefaultKeyAssemblerOptionDisableXDTExtensions],
                                  XDTAssemblerOptionTarget: [NSNumber numberWithUnsignedInteger:xdtTargetType]
                                  };
        XDTAssembler *assembler = [XDTAssembler assemblerWithOptions:options includeURL:assemblerFileURL];

        NSError *error = nil;
        XDTObjcode *assemblingResult = [assembler assembleSourceFile:assemblerFileURL error:&error];
        if (nil != error) {
            NSAlert *errorAlert = [NSAlert alertWithError:error];
            [errorAlert runModal];
            /* TODO: Extend the alert with an additional button, so you can decide if the error log will be shown. */
            return NO;
        }

        switch (xdtTargetType) {
            case XDTAssemblerTargetTypeProgramImage: {
                NSUInteger baseAddress = [defaults integerForKey:UserDefaultKeyAssemblerOptionBaseAddress];
                NSString *countingFileName = [NSMutableString stringWithString:[[outputFileURL lastPathComponent] stringByDeletingPathExtension]];
                for (NSData *data in [assemblingResult generateImageAt:baseAddress error:&error]) {
                    if (nil != error || nil == data) {
                        break;
                    }
                    NSURL *countingFileURL = [[outputFileURL URLByDeletingLastPathComponent] URLByAppendingPathComponent:[countingFileName stringByAppendingPathExtension:[outputFileURL pathExtension]]];
                    [data writeToURL:countingFileURL options:NSDataWritingAtomic error:&error];
                    if (nil != error) {
                        break;
                    }

                    unichar nextChar = [countingFileName characterAtIndex:[countingFileName length]-1] + 1;
                    countingFileName = [[countingFileName substringToIndex:[countingFileName length]-1] stringByAppendingFormat:@"%c", nextChar];
                }
                break;
            }
            case XDTAssemblerTargetTypeRawBinary: {
                NSUInteger baseAddress = [defaults integerForKey:UserDefaultKeyAssemblerOptionBaseAddress];
                for (NSArray<id> *element in [assemblingResult generateRawBinaryAt:baseAddress error:&error]) {
                    if (nil != error || nil == element) {
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
                    NSURL *newOutputFileURL = [NSURL URLWithString:[[[[outputFileURL lastPathComponent] stringByDeletingPathExtension] stringByAppendingString:fileNameAddition] stringByAppendingPathExtension:[outputFileURL pathExtension]]
                                                     relativeToURL:[outputFileURL URLByDeletingLastPathComponent]];
                    [data writeToURL:newOutputFileURL options:NSDataWritingAtomic error:&error];
                    if (nil != error) {
                        break;
                    }
                }
                break;
            }
            case XDTAssemblerTargetTypeTextBinary: {
                NSMutableString *fileContent = [NSMutableString string];
                NSUInteger baseAddress = [defaults integerForKey:UserDefaultKeyAssemblerOptionBaseAddress];
                for (NSArray<id> *element in [assemblingResult generateRawBinaryAt:baseAddress error:&error]) {
                    if (nil != error || nil == element) {
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
                if (nil == error && nil != fileContent && [fileContent length] > 0) {
                    [fileContent writeToURL:outputFileURL atomically:YES encoding:NSUTF8StringEncoding error:&error];
                }
                break;
            }
            case XDTAssemblerTargetTypeObjectCode: {
                NSData *data = [assemblingResult generateObjCode:compressedObjectCode error:&error];
                if (nil == error && nil != data) {
                    [data writeToURL:outputFileURL options:NSDataWritingAtomic error:&error];
                }
                break;
            }
            case XDTAssemblerTargetTypeEmbededXBasic: {
                NSData *data = [assemblingResult generateBasicLoader:&error];
                if (nil == error && nil != data) {
                    [data writeToURL:outputFileURL options:NSDataWritingAtomic error:&error];
                }
                break;
            }
            case XDTAssemblerTargetTypeJumpstart: {
                NSData *data = [assemblingResult generateJumpstart:&error];
                if (nil == error && nil != data) {
                    [data writeToURL:outputFileURL options:NSDataWritingAtomic error:&error];
                }
                break;
            }
            case XDTAssemblerTargetTypeMESSCartridge: {
                NSString *cartName = [_assemblerCartridgeNameTextFiled stringValue];
                if (nil == cartName || [cartName length] == 0) {
                    NSAlert *errorAlert = [NSAlert alertWithMessageText:@"Missing Option" defaultButton:@"Abort" alternateButton:nil otherButton:nil informativeTextWithFormat:@"Please specify a name of the cartridge to create!"];
                    [errorAlert runModal];
                    return NO;
                }

                XDTZipFile *zipfile = [XDTZipFile zipFileForWritingToURL:outputFileURL error:&error];
                if (nil == error && nil != zipfile) {
                    NSDictionary *tripel = [assemblingResult generateMESSCartridgeWithName:cartName error:&error];
                    if (nil == error && nil != tripel) {
                        for (NSString *fName in [tripel keyEnumerator]) {
                            NSData *data = [tripel objectForKey:fName];
                            [zipfile writeFile:fName withData:data error:&error];
                            if (nil != error) {
                                break;
                            }
                        }
                    }
                }
                if (nil != error) {
                    NSAlert *alert = [NSAlert alertWithError:error];
                    [alert runModal];
                    return NO;
                }
                break;
            }
                
            default:
                break;
        }
        if (nil == error && [defaults boolForKey:UserDefaultKeyAssemblerOptionGenerateListOutput]) {
            NSURL *listingURL = [[outputFileURL URLByDeletingPathExtension] URLByAppendingPathExtension:@"dv80"];
            BOOL outputSymbols = [defaults boolForKey:UserDefaultKeyAssemblerOptionGenerateSymbolTable];
            BOOL useEqus = [defaults boolForKey:UserDefaultKeyAssemblerOptionGenerateSymbolsAsEqus];
            NSData *data = [assemblingResult generateListing:outputSymbols && !useEqus error:&error];
            if (nil == error && nil != data) {
                NSMutableString *retVal = [[NSMutableString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                if (outputSymbols && useEqus) {
                    data = [assemblingResult generateSymbols:YES error:&error];
                    [retVal appendFormat:@"\n%@\n", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]];
                }
                if (nil == error && nil != retVal && [retVal length] > 0) {
                    [retVal writeToURL:listingURL atomically:YES encoding:NSUTF8StringEncoding error:&error];
                }
            }
        }

        if (nil != error) {
            [[NSAlert alertWithError:error] runModal];
            return NO;
        }
        return YES;
    }];
}


- (IBAction)runGPLAssembler:(nullable id)sender
{
    NSURL *gplFileURL = [self selectInputFileWithExtension:@"gpl"];
    if (nil == gplFileURL) {
        return;
    }

    _actualOptionsView = _gplAssemblerOptionsView;
    [self processSourceFileURL:gplFileURL withXDTprocess:^BOOL(NSURL * _Nonnull outputFileURL) {
        NSUserDefaults *defaults = [[NSUserDefaultsController sharedUserDefaultsController] defaults];
        NSInteger selectedTypeIndex = [defaults integerForKey:UserDefaultKeyGPLOptionOutputTypePopupIndex];
        XDTGPLAssemblerTargetType xdtTargetType = XDTAssemblerTargetTypeObjectCode;
        switch (selectedTypeIndex) {
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
        NSInteger selectedStyleIndex = [defaults integerForKey:UserDefaultKeyGPLOptionSyntaxTypePopupIndex];
        XDTGPLAssemblerTargetType xdtSyntaxType = XDTGPLAssemblerSyntaxTypeNativeXDT99;
        switch (selectedStyleIndex) {
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
        NSDictionary *options = @{
                                  XDTGPLAssemblerOptionAORG: [defaults objectForKey:UserDefaultKeyGPLOptionAORGAddress],
                                  XDTGPLAssemblerOptionGROM: [defaults objectForKey:UserDefaultKeyGPLOptionGROMAddress],
                                  XDTGPLAssemblerOptionStyle: [NSNumber numberWithUnsignedInteger:xdtSyntaxType],
                                  XDTGPLAssemblerOptionTarget: [NSNumber numberWithUnsignedInteger:xdtTargetType]
                                  };
        XDTGPLAssembler *assembler = [XDTGPLAssembler gplAssemblerWithOptions:options includeURL:gplFileURL];

        NSError *error = nil;
        XDTGPLObjcode *assemblingResult = [assembler assembleSourceFile:gplFileURL error:&error];
        if (nil != error) {
            NSAlert *errorAlert = [NSAlert alertWithError:error];
            [errorAlert runModal];
            /* TODO: Extend the alert with an additional button, so you can decide if the error log will be shown. */
            return NO;
        }

        switch (xdtTargetType) {
            case XDTGPLAssemblerTargetTypePlainByteCode:    /* byte code */
                for (NSArray<id> *element in [assemblingResult generateByteCode:&error]) {
                    if (nil != error || nil == element) {
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
                    NSURL *newOutputFileURL = [NSURL URLWithString:[[[[outputFileURL lastPathComponent] stringByDeletingPathExtension] stringByAppendingString:fileNameAddition] stringByAppendingPathExtension:[outputFileURL pathExtension]]
                                                     relativeToURL:[outputFileURL URLByDeletingLastPathComponent]];
                    [data writeToURL:newOutputFileURL options:NSDataWritingAtomic error:&error];
                    if (nil != error) {
                        break;
                    }
                }
                break;

            case XDTGPLAssemblerTargetTypeHeaderedByteCode: { /* image */
                NSString *cartName = [_gplCartridgeNameTextFiled stringValue];
                if (nil == cartName || [cartName length] == 0) {
                    NSAlert *errorAlert = [NSAlert alertWithMessageText:@"Missing Option" defaultButton:@"Abort" alternateButton:nil otherButton:nil informativeTextWithFormat:@"Please specify a name of the cartridge to create!"];
                    [errorAlert runModal];
                    return NO;
                }

                NSData *data = [assemblingResult generateImageWithName:cartName error:&error];
                if (nil == error && nil != data) {
                    [data writeToURL:outputFileURL options:NSDataWritingAtomic error:&error];
                }
                break;
            }

            case XDTGPLAssemblerTargetTypeMESSCartridge: {
                NSString *cartName = [_gplCartridgeNameTextFiled stringValue];
                if (nil == cartName || [cartName length] == 0) {
                    NSAlert *errorAlert = [NSAlert alertWithMessageText:@"Missing Option" defaultButton:@"Abort" alternateButton:nil otherButton:nil informativeTextWithFormat:@"Please specify a name of the cartridge to create!"];
                    [errorAlert runModal];
                    return NO;
                }

                XDTZipFile *zipfile = [XDTZipFile zipFileForWritingToURL:outputFileURL error:&error];
                if (nil != zipfile) {
                    NSDictionary *tripel = [assemblingResult generateMESSCartridgeWithName:cartName error:&error];
                    if (nil == error && nil != tripel) {
                        for (NSString *fName in [tripel keyEnumerator]) {
                            NSData *data = [tripel objectForKey:fName];
                            [zipfile writeFile:fName withData:data error:&error];
                            if (nil != error) {
                                break;
                            }
                        }
                    }
                }
                if (nil != error) {
                    NSAlert *alert = [NSAlert alertWithError:error];
                    [alert runModal];
                    return NO;
                }
                break;
            }
                
            default:
                break;
        }

        if (nil != error) {
            [[NSAlert alertWithError:error] runModal];
            return NO;
        }
        return YES;
    }];
}


- (IBAction)runBasicEncoder:(nullable id)sender
{
    NSURL *basicFileURL = [self selectInputFileWithExtension:@"bas"];
    if (nil == basicFileURL) {
        return;
    }

    _actualOptionsView = _basicOptionsView;
    [self processSourceFileURL:basicFileURL withXDTprocess:^BOOL(NSURL * _Nonnull outputFileURL) {
        NSUserDefaults *defaults = [[NSUserDefaultsController sharedUserDefaultsController] defaults];
        NSDictionary *options = @{
                                  XDTBasicOptionProtectFile: [defaults objectForKey:UserDefaultKeyBasicOptionShouldProtectFile],
                                  XDTBasicOptionJoinLines: [defaults objectForKey:UserDefaultKeyBasicOptionShouldJoinSourceLines]
                                  };
        XDTBasic *basic = [XDTBasic basicWithOptions:options];
        if (nil == basic) {
            return NO;
        }
        NSError *error = nil;
        /*
         If you will implement to load binary files formats for converting them, i.e. from internal to long format, 
         try to implement something like this:

        NSData *data = [NSData dataWithContentsOfURL:basicFileURL];
        [basic loadProgramData:data error:&error];
        if (nil != error) {
            NSAlert *alert = [NSAlert alertWithError:error];
            [alert runModal];
            return NO;
        }*/
        NSString *sourceCode = [NSString stringWithContentsOfURL:basicFileURL encoding:NSUTF8StringEncoding error:&error];
        if (nil == sourceCode) {
            if (nil != error) {
                [[NSAlert alertWithError:error] runModal];
            }
            return NO;
        }
        if (![basic parseSourceCode:sourceCode error:&error]) {
            if (nil != error) {
                [[NSAlert alertWithError:error] runModal];
            }
            return NO;
        }

        NSInteger selectedTypeIndenx = [defaults integerForKey:UserDefaultKeyBasicOptionOutputTypePopupIndex];
        BOOL successfullySaved = NO;
        switch (selectedTypeIndenx) {
            case 0:
                successfullySaved = [basic saveProgramFormatFile:outputFileURL error:&error];
                break;
            case 1:
                successfullySaved = [basic saveLongFormatFile:outputFileURL error:&error];
                break;
            case 2:
                successfullySaved = [basic saveMergedFormatFile:outputFileURL error:&error];
                break;

            default:
                break;
        }
        if (nil != error) {
            [[NSAlert alertWithError:error] runModal];
            return NO;
        }

        return successfullySaved;
    }];
}


#pragma mark - private methods


- (NSURL *)selectInputFileWithExtension:(NSString *)extension
{
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    [panel setCanCreateDirectories:NO];
    [panel setCanChooseFiles:YES];
    [panel setAllowsMultipleSelection:NO];
    if ([extension isEqualToString:@"a99"]) {
        [panel setAllowedFileTypes:@[extension, @"asm"]];
        [panel setTitle:@"Select assembler source file"];
    } else if ([extension isEqualToString:@"gpl"]) {
        [panel setAllowedFileTypes:@[extension]];
        [panel setTitle:@"Select GPL assembler source file"];
    } else if ([extension isEqualToString:@"bas"]) {
        [panel setAllowedFileTypes:@[extension, @"b99"]];
        [panel setTitle:@"Select TI Basic source file"];
    } else {
        NSLog(@"Cannot open source file with extension of '%@'", extension);
        return nil;
    }

    if (NSFileHandlingPanelOKButton == [panel runModal]) {
        return [panel URL];
    }
    return nil;
}



- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
    NSUserDefaults *defaults = object;
    NSSavePanel *panel = (__bridge NSSavePanel *)(context);

    if ([UserDefaultKeyAssemblerOptionOutputTypePopupIndex isEqualToString:keyPath]) {
        NSInteger outputFileType = [defaults integerForKey:UserDefaultKeyAssemblerOptionOutputTypePopupIndex];
        [self panel:panel didChangeAssemblerOutputType:outputFileType];
    } else if ([UserDefaultKeyGPLOptionOutputTypePopupIndex isEqualToString:keyPath]) {
        NSInteger outputFileType = [defaults integerForKey:UserDefaultKeyGPLOptionOutputTypePopupIndex];
        [self panel:panel didChangeGPLOutputType:outputFileType];
    } else if ([UserDefaultKeyBasicOptionOutputTypePopupIndex isEqualToString:keyPath]) {
        NSInteger outputFileType = [defaults integerForKey:UserDefaultKeyBasicOptionOutputTypePopupIndex];
        [self panel:panel didChangeBasicOutputType:outputFileType];
    }
}


- (void)panel:(NSSavePanel *)panel didChangeAssemblerOutputType:(NSInteger)outputFileType
{
    NSString *extension = @"";
    switch (outputFileType) {
        case 0:
            extension = @"img";
            break;
        case 1:
        case 2:
            extension = @"obj";
            break;
        case 3:
            extension = @"iv254";
            break;
        case 4:
            extension = @"bin";
            break;
        case 5:
            extension = @"dat";
            break;
        case 6:
            extension = @"dsk";
            break;
        case 7:
            extension = @"rpk";
            break;
        /* TODO: Since version 1.7.0 of xas99, there is a new option to export an EQU listing to a text file.
            This feature is open to implement.
         */

        default:
            break;
    }
    NSString *newNameFieldValue = [[panel nameFieldStringValue] stringByDeletingPathExtension];
    newNameFieldValue = [newNameFieldValue stringByAppendingPathExtension:extension];
    [panel setNameFieldStringValue:newNameFieldValue];

    [self willChangeValueForKey:@"shouldCartridgeNameActivated"];
    _shouldCartridgeNameActivated = (7 == outputFileType);
    [self didChangeValueForKey:@"shouldCartridgeNameActivated"];

    [self willChangeValueForKey:@"shouldBaseAddressActivated"];
    _shouldBaseAddressActivated = (0 == outputFileType) || (4 == outputFileType) || (5 == outputFileType);
    [self didChangeValueForKey:@"shouldBaseAddressActivated"];
}


- (void)panel:(NSSavePanel *)panel didChangeGPLOutputType:(NSInteger)outputFileType
{
    NSString *extension = @"";
    switch (outputFileType) {
        case 0:
            extension = @"gbc";
            break;
        case 1:
            extension = @"bin";
            break;
        case 2:
            extension = @"rpk";
            break;

        default:
            break;
    }
    NSString *newNameFieldValue = [[panel nameFieldStringValue] stringByDeletingPathExtension];
    newNameFieldValue = [newNameFieldValue stringByAppendingPathExtension:extension];
    [panel setNameFieldStringValue:newNameFieldValue];

    [self willChangeValueForKey:@"shouldCartridgeNameActivated"];
    _shouldCartridgeNameActivated = (1 == outputFileType) || (2 == outputFileType);
    [self didChangeValueForKey:@"shouldCartridgeNameActivated"];
}


- (void)panel:(NSSavePanel *)panel didChangeBasicOutputType:(NSInteger) outputFileType
{
    NSString *extension = @"";
    switch (outputFileType) {
        case 0:
            extension = @"bin";
            break;
        case 1:
            extension = @"iv254";
            break;
        case 2:
            extension = @"dv163";
            break;

        default:
            break;
    }
    NSString *newNameFieldValue = [[panel nameFieldStringValue] stringByDeletingPathExtension];
    newNameFieldValue = [newNameFieldValue stringByAppendingPathExtension:extension];
    [panel setNameFieldStringValue:newNameFieldValue];
}


- (BOOL)processSourceFileURL:(NSURL *)sourceFile withXDTprocess:(BOOL(^)(NSURL *outputFileURL))process
{
    __block BOOL retVal = NO;

    [_assemblerCartridgeNameTextFiled setStringValue:[[sourceFile URLByDeletingPathExtension] lastPathComponent]];
    [_gplCartridgeNameTextFiled setPlaceholderString:[[sourceFile URLByDeletingPathExtension] lastPathComponent]];
    NSSavePanel *panel = [NSSavePanel savePanel];
    [panel setCanCreateDirectories:YES];
    [panel setTitle:@"Select output file name"];
    [panel setDirectoryURL:[sourceFile URLByDeletingLastPathComponent]];
    [panel setAccessoryView:_actualOptionsView];
    [panel setNameFieldStringValue:[[_assemblerCartridgeNameTextFiled stringValue] stringByAppendingPathExtension:@"bin"]];

    NSUserDefaults *defaults = [[NSUserDefaultsController sharedUserDefaultsController] defaults];
    if (_actualOptionsView == _assemblerOptionsView) {
        [self observeValueForKeyPath:UserDefaultKeyAssemblerOptionOutputTypePopupIndex ofObject:defaults change:nil context:(__bridge void * _Nullable)(panel)];
        [defaults addObserver:self forKeyPath:UserDefaultKeyAssemblerOptionOutputTypePopupIndex options:NSKeyValueObservingOptionNew context:(__bridge void * _Nullable)(panel)];
    } else if (_actualOptionsView == _gplAssemblerOptionsView) {
        [self observeValueForKeyPath:UserDefaultKeyGPLOptionOutputTypePopupIndex ofObject:defaults change:nil context:(__bridge void * _Nullable)(panel)];
        [defaults addObserver:self forKeyPath:UserDefaultKeyGPLOptionOutputTypePopupIndex options:NSKeyValueObservingOptionNew context:(__bridge void * _Nullable)(panel)];
    } else if (_actualOptionsView == _basicOptionsView) {
        [self observeValueForKeyPath:UserDefaultKeyBasicOptionOutputTypePopupIndex ofObject:defaults change:nil context:(__bridge void * _Nullable)(panel)];
        [defaults addObserver:self forKeyPath:UserDefaultKeyBasicOptionOutputTypePopupIndex options:NSKeyValueObservingOptionNew context:(__bridge void * _Nullable)(panel)];
    }

    if (NSFileHandlingPanelOKButton == [panel runModal]) {
        process([panel URL]);
        retVal = YES;
    }

    if (_actualOptionsView == _assemblerOptionsView) {
        [defaults removeObserver:self forKeyPath:UserDefaultKeyAssemblerOptionOutputTypePopupIndex];
    } else if (_actualOptionsView == _gplAssemblerOptionsView) {
        [defaults removeObserver:self forKeyPath:UserDefaultKeyGPLOptionOutputTypePopupIndex];
    } else if (_actualOptionsView == _basicOptionsView) {
        [defaults removeObserver:self forKeyPath:UserDefaultKeyBasicOptionOutputTypePopupIndex];
    }

    return retVal;
}

@end
