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


NS_ASSUME_NONNULL_BEGIN
@interface AppDelegate ()

/* Three views for save panel */
@property IBOutlet NSView *assemblerOptionsView;

@property IBOutlet NSPopUpButton *assemblerOutputTypePopUpButton;
@property IBOutlet NSTextField *assemblerCartridgeNameTextFiled;

@property (readonly) BOOL shouldCartridgeNameActivated;
@property (readonly) BOOL shouldBaseAddressActivated;

- (IBAction)runAssembler:(nullable id)sender;

- (nullable NSURL *)selectInputFileWithExtension:(NSString *)extension;
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
                                   UserDefaultKeyAssemblerOptionBaseAddress: [NSNumber numberWithInteger:0xa000]
                              };
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaultsDict];
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}


#pragma mark - menu handling


- (IBAction)runAssembler:(nullable id)sender
{
    NSURL *assemblerFileURL = [self selectInputFileWithExtension:@"a99"];
    if (nil == assemblerFileURL) {
        return;
    }

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
                xdtTargetType = XDTAssemblerTargetTypeJumpstart;
                break;
            case 6:
                xdtTargetType = XDTAssemblerTargetTypeMESSCartridge;
                break;
                
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
                for (NSData *data in [assemblingResult generateImageAt:baseAddress]) {
                    NSURL *countingFileURL = [[outputFileURL URLByDeletingLastPathComponent] URLByAppendingPathComponent:[countingFileName stringByAppendingPathExtension:[outputFileURL pathExtension]]];
                    [data writeToURL:countingFileURL atomically:YES];

                    unichar nextChar = [countingFileName characterAtIndex:[countingFileName length]-1] + 1;
                    countingFileName = [[countingFileName substringToIndex:[countingFileName length]-1] stringByAppendingFormat:@"%c", nextChar];
                }
                break;
            }
            case XDTAssemblerTargetTypeRawBinary: {
                NSUInteger baseAddress = [defaults integerForKey:UserDefaultKeyAssemblerOptionBaseAddress];
                for (NSArray<id> *element in [assemblingResult generateRawBinaryAt:baseAddress]) {
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
                    [data writeToURL:newOutputFileURL atomically:YES];
                }
                break;
            }
            case XDTAssemblerTargetTypeObjectCode: {
                NSData *data = [assemblingResult generateObjCode:compressedObjectCode];
                if (nil != data) {
                    [data writeToURL:outputFileURL atomically:YES];
                }
                break;
            }
            case XDTAssemblerTargetTypeEmbededXBasic: {
                NSData *data = [assemblingResult generateBasicLoader];
                if (nil != data) {
                    [data writeToURL:outputFileURL atomically:YES];
                }
                break;
            }
            case XDTAssemblerTargetTypeJumpstart: {
                NSData *data = [assemblingResult generateJumpstart];
                if (nil != data) {
                    [data writeToURL:outputFileURL atomically:YES];
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

                error = nil;
                XDTZipFile *zipfile = [XDTZipFile zipFileForWritingToURL:outputFileURL error:&error];
                if (nil != error) {
                    NSAlert *alert = [NSAlert alertWithError:error];
                    [alert runModal];
                    return NO;
                }
                
                if (nil != zipfile) {
                    NSDictionary *tripel = [assemblingResult generateMESSCartridgeWithName:cartName];
                    for (NSString *fName in [tripel keyEnumerator]) {
                        NSData *data = [tripel objectForKey:fName];
                        [zipfile writeFile:fName withData:data];
                    }
                }
                break;
            }
                
            default:
                break;
        }
        if ([defaults boolForKey:UserDefaultKeyAssemblerOptionGenerateListOutput]) {
            NSURL *listingURL = [[outputFileURL URLByDeletingPathExtension] URLByAppendingPathExtension:@"dv80"];
            NSData *data = [assemblingResult generateListing];
            if (nil != data) {
                [data writeToURL:listingURL atomically:YES];
            }
        }
        return YES;
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
    if ([UserDefaultKeyAssemblerOptionOutputTypePopupIndex isEqualToString:keyPath]) {
        NSSavePanel *panel = (__bridge NSSavePanel *)(context);
        NSUserDefaults *defaults = object;

        NSInteger outputFileType = [defaults integerForKey:UserDefaultKeyAssemblerOptionOutputTypePopupIndex];
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
                extension = @"dsk";
                break;
            case 6:
                extension = @"rpk";
                [defaults setObject:@0x6000 forKey:UserDefaultKeyAssemblerOptionBaseAddress];
                break;

            default:
                break;
        }
        NSString *newNameFieldValue = [[panel nameFieldStringValue] stringByDeletingPathExtension];
        newNameFieldValue = [newNameFieldValue stringByAppendingPathExtension:extension];
        [panel setNameFieldStringValue:newNameFieldValue];

        [self willChangeValueForKey:@"shouldCartridgeNameActivated"];
        _shouldCartridgeNameActivated = (6 == outputFileType);
        [self didChangeValueForKey:@"shouldCartridgeNameActivated"];

        [self willChangeValueForKey:@"shouldBaseAddressActivated"];
        _shouldBaseAddressActivated = (0 == outputFileType) || (4 == outputFileType);
        [self didChangeValueForKey:@"shouldBaseAddressActivated"];
    }
}


- (BOOL)processSourceFileURL:(NSURL *)sourceFile withXDTprocess:(BOOL(^)(NSURL *outputFileURL))process
{
    __block BOOL retVal = NO;

    [_assemblerCartridgeNameTextFiled setStringValue:[[sourceFile URLByDeletingPathExtension] lastPathComponent]];
    NSSavePanel *panel = [NSSavePanel savePanel];
    [panel setCanCreateDirectories:YES];
    [panel setTitle:@"Select output file name"];
    [panel setDirectoryURL:[sourceFile URLByDeletingLastPathComponent]];
    [panel setAccessoryView:_assemblerOptionsView];
    [panel setNameFieldStringValue:[[_assemblerCartridgeNameTextFiled stringValue] stringByAppendingPathExtension:@"bin"]];

    NSUserDefaults *defaults = [[NSUserDefaultsController sharedUserDefaultsController] defaults];
    [self observeValueForKeyPath:UserDefaultKeyAssemblerOptionOutputTypePopupIndex ofObject:defaults change:nil context:(__bridge void * _Nullable)(panel)];
    [defaults addObserver:self forKeyPath:UserDefaultKeyAssemblerOptionOutputTypePopupIndex options:NSKeyValueObservingOptionNew context:(__bridge void * _Nullable)(panel)];

    if (NSFileHandlingPanelOKButton == [panel runModal]) {
        process([panel URL]);
        retVal = YES;
    }

    [defaults removeObserver:self forKeyPath:UserDefaultKeyAssemblerOptionOutputTypePopupIndex];

    return retVal;
}

@end
