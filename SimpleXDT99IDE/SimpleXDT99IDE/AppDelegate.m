//
//  AppDelegate.m
//  SimpleXDT99
//
//  Created by Henrik Wedekind on 02.12.16.
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

#import "AppDelegate.h"

#import "XDTAssembler.h"
#import "XDTAs99Objcode.h"
#import "XDTZipFile.h"
#import <XDTools99/XDBasic.h>
#import <XDTools99/XDGPL.h>

#import "PreferencesPaneController.h"
#import "SourceCodeDocument.h"
#import "AssemblerDocument.h"
#import "GPLAssemblerDocument.h"


NSErrorDomain const IDEErrorDomain = @"IDEErrorDomain";


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

- (IBAction)orderToFrontPreferencesPanel:(nullable id)sender;
- (IBAction)openEmbeddedFiles:(nullable id)sender;
- (IBAction)runAssembler:(nullable id)sender;
- (IBAction)runGPLAssembler:(nullable id)sender;
- (IBAction)runBasicEncoder:(nullable id)sender;
- (IBAction)hideShowAllLogs:(nullable id)sender;

- (nullable NSURL *)selectInputFileWithExtension:(NSString *)extension;

- (void)panel:(NSSavePanel *)panel didChangeAssemblerOutputType:(NSInteger) outputFileType;
- (void)panel:(NSSavePanel *)panel didChangeGPLOutputType:(NSInteger) outputFileType;
- (void)panel:(NSSavePanel *)panel didChangeBasicOutputType:(NSInteger) outputFileType;

- (BOOL)processSourceFileURL:(NSURL *)sourceFile withXDTprocess:(BOOL(^)(NSURL *outputFileURL))process;

@end
NS_ASSUME_NONNULL_END


@implementation AppDelegate

#pragma mark - NSApplicationDelegate Methods


- (void)applicationWillFinishLaunching:(NSNotification *)notification {
    NSData *emptyIndexSet = [NSKeyedArchiver archivedDataWithRootObject:NSIndexSet.indexSet];
    NSDictionary *defaultsDict = @{
                                   UserDefaultKeyDocumentOptionOpenNestedFiles: @YES,
                                   UserDefaultKeyDocumentOptionShowLog: @YES,
                                   UserDefaultKeyDocumentOptionShowErrorsInLog: @YES,
                                   UserDefaultKeyDocumentOptionShowWarningsInLog: @YES,
                                   UserDefaultKeyDocumentOptionSuppressedAlerts: @{
                                           IDEErrorDomain: emptyIndexSet,
                                           XDTErrorDomain: emptyIndexSet
                                           },
                                   UserDefaultKeyDocumentOptionEnableHighlighting: @YES,
                                   UserDefaultKeyDocumentOptionHighlightSyntax: @YES,
                                   UserDefaultKeyDocumentOptionHighlightMessages: @YES,
                                   UserDefaultKeyDocumentOptionTabBehaviour: [NSNumber numberWithUnsignedInteger:TabBehaviourTIStyle],
                                   UserDefaultKeyDocumentOptionTabWidth: @4,
                                   UserDefaultKeyDocumentOptionPrintUsingHighlighting: @NO,
                                   UserDefaultKeyDocumentOptionPrintListing: @NO,

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
                                   UserDefaultKeyGPLOptionGenerateListOutput: @NO,
                                   UserDefaultKeyGPLOptionGenerateSymbolTable: @NO,
                                   UserDefaultKeyGPLOptionGenerateSymbolsAsEqus: @NO,
                                   UserDefaultKeyGPLOptionAORGAddress: @0x0030,
                                   UserDefaultKeyGPLOptionGROMAddress: @0x6000
                                   };
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaultsDict];
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}


#pragma mark - Menu Action Methods


- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
    if (menuItem.action == @selector(openEmbeddedFiles:)) {
        SourceCodeDocument *doc = NSDocumentController.sharedDocumentController.currentDocument;
        return nil != doc && ([doc isKindOfClass:AssemblerDocument.class] || [doc isKindOfClass:GPLAssemblerDocument.class]);
    }

    if (menuItem.action == @selector(hideShowAllLogs:)) {
        BOOL logIsVisible = ((SourceCodeDocument *)NSDocumentController.sharedDocumentController.currentDocument).shouldShowLog;
        menuItem.title = (logIsVisible)? NSLocalizedString(@"Hide All Logs", @"Menu item titel for hiding all log view for every document.") : NSLocalizedString(@"Show All Logs", @"Menu item titel for showing all log view for every document.");
        return YES;
    }

    return YES;
}


- (IBAction)orderToFrontPreferencesPanel:(id)sender
{
    [PreferencesPaneController.sharedPreferencesPane showWindow:sender];
}


- (IBAction)openEmbeddedFiles:(id)sender
{
    SourceCodeDocument *doc = NSDocumentController.sharedDocumentController.currentDocument;
    NSError *error = nil;
    if (![doc openNestedFiles:&error]) {
        (void)[doc presentError:error];
    }
}


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
        XDTAs99TargetType xdtTargetType = XDTAs99TargetTypeObjectCode;
        BOOL compressedObjectCode = NO;
        switch (selectedTypeIndenx) {
            case 0:
                xdtTargetType = XDTAs99TargetTypeProgramImage;
                break;
            case 1:
            case 2:
                xdtTargetType = XDTAs99TargetTypeObjectCode;
                compressedObjectCode = selectedTypeIndenx == 1;
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
        XDTAssembler *assembler = [XDTAssembler assemblerWithIncludeURL:assemblerFileURL target:xdtTargetType usingRegisterSymbol:[[defaults objectForKey:UserDefaultKeyAssemblerOptionUseRegisterSymbols] boolValue] strictness:[[defaults objectForKey:UserDefaultKeyAssemblerOptionDisableXDTExtensions] boolValue] outputWarnings:[[defaults objectForKey:UserDefaultKeyDocumentOptionShowWarningsInLog] boolValue]];

        NSError *error = nil;
        XDTAs99Objcode *assemblingResult = [assembler assembleSourceFile:assemblerFileURL error:&error];
        if (nil != error) {
            NSAlert *errorAlert = [NSAlert alertWithError:error];
            [errorAlert runModal];
            /* TODO: Extend the alert with an additional button, so you can decide if the error log will be shown. */
            return NO;
        }

        XDTGenerateTextMode mode = 0;
        switch (xdtTargetType) {
            case XDTAs99TargetTypeProgramImage: {
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
            case XDTAs99TargetTypeRawBinary: {
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
                    NSURL *newOutputFileURL = [NSURL fileURLWithPath:[[[[outputFileURL lastPathComponent] stringByDeletingPathExtension] stringByAppendingString:fileNameAddition] stringByAppendingPathExtension:[outputFileURL pathExtension]]
                                                     relativeToURL:[outputFileURL URLByDeletingLastPathComponent]];
                    [data writeToURL:newOutputFileURL options:NSDataWritingAtomic error:&error];
                    if (nil != error) {
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
                NSUInteger baseAddress = [defaults integerForKey:UserDefaultKeyAssemblerOptionBaseAddress];
                // TODO: extend GUI for new configuration options
                NSString *fileContent = [assemblingResult generateTextAt:baseAddress
                                                                withMode:mode + XDTGenerateTextModeOptionWord
                                                                   error:&error];
                if (nil == error && nil != fileContent && [fileContent length] > 0) {
                    [fileContent writeToURL:outputFileURL atomically:YES encoding:NSUTF8StringEncoding error:&error];
                }
                break;
            }
            case XDTAs99TargetTypeObjectCode: {
                NSData *data = [assemblingResult generateObjCode:compressedObjectCode error:&error];
                if (nil == error && nil != data) {
                    [data writeToURL:outputFileURL options:NSDataWritingAtomic error:&error];
                }
                break;
            }
            case XDTAs99TargetTypeEmbededXBasic: {
                NSData *data = [assemblingResult generateBasicLoader:&error];
                if (nil == error && nil != data) {
                    [data writeToURL:outputFileURL options:NSDataWritingAtomic error:&error];
                }
                break;
            }
            case XDTAs99TargetTypeMESSCartridge: {
                NSString *cartName = [self->_assemblerCartridgeNameTextFiled stringValue];
                if (nil == cartName || [cartName length] == 0) {
                    NSAlert *errorAlert = [NSAlert new];
                    errorAlert.messageText = @"Missing Option";
                    [errorAlert addButtonWithTitle:@"Abort"];
                    errorAlert.informativeText = @"Please specify a name of the cartridge to create!";
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
        XDTGa99TargetType xdtTargetType = XDTGa99TargetTypePlainByteCode;
        switch (selectedTypeIndex) {
            case 0:
                xdtTargetType = XDTGa99TargetTypePlainByteCode;
                break;
            case 1:
                xdtTargetType = XDTGa99TargetTypeHeaderedByteCode;
                break;
            case 2:
                xdtTargetType = XDTGa99TargetTypeMESSCartridge;
                break;

            default:
                break;
        }
        NSInteger selectedStyleIndex = [defaults integerForKey:UserDefaultKeyGPLOptionSyntaxTypePopupIndex];
        XDTGa99SyntaxType xdtSyntaxType = XDTGa99SyntaxTypeNativeXDT99;
        switch (selectedStyleIndex) {
            case 0:
                xdtSyntaxType = XDTGa99SyntaxTypeNativeXDT99;
                break;
            case 1:
                xdtSyntaxType = XDTGa99SyntaxTypeTIImageTool;
                break;
                
            default:
                break;
        }
        XDTGPLAssembler *assembler = [XDTGPLAssembler gplAssemblerWithIncludeURL:gplFileURL grom:[[defaults objectForKey:UserDefaultKeyGPLOptionGROMAddress] unsignedIntegerValue] aorg:[[defaults objectForKey:UserDefaultKeyGPLOptionAORGAddress] unsignedIntegerValue] target:xdtTargetType syntax:xdtSyntaxType outputWarnings:[[defaults objectForKey:UserDefaultKeyDocumentOptionShowWarningsInLog] boolValue]];

        NSError *error = nil;
        XDTGa99Objcode *assemblingResult = [assembler assembleSourceFile:gplFileURL error:&error];
        if (nil != error) {
            NSAlert *errorAlert = [NSAlert alertWithError:error];
            [errorAlert runModal];
            /* TODO: Extend the alert with an additional button, so you can decide if the error log will be shown. */
            return NO;
        }

        switch (xdtTargetType) {
            case XDTGa99TargetTypePlainByteCode:    /* byte code */
                for (NSArray<id> *element in [assemblingResult generateByteCode:&error]) {
                    if (nil != error || nil == element) {
                        break;
                    }
                    NSNumber *address = [element objectAtIndex:0];
                    NSNumber *base = [element objectAtIndex:1];
                    NSData *data = [element objectAtIndex:2];

                    NSString *fileNameAddition = nil;
                    if ([base isMemberOfClass:[NSNull class]]) {
                        fileNameAddition = [NSString stringWithFormat:@"_%04x", [address unsignedIntValue]];
                    } else {
                        fileNameAddition = [NSString stringWithFormat:@"_%04x_b%d", [address unsignedIntValue], [base intValue]];
                    }
                    NSURL *newOutputFileURL = [NSURL fileURLWithPath:[[[[outputFileURL lastPathComponent] stringByDeletingPathExtension] stringByAppendingString:fileNameAddition] stringByAppendingPathExtension:[outputFileURL pathExtension]]
                                                     relativeToURL:[outputFileURL URLByDeletingLastPathComponent]];
                    [data writeToURL:newOutputFileURL options:NSDataWritingAtomic error:&error];
                    if (nil != error) {
                        break;
                    }
                }
                break;

            case XDTGa99TargetTypeHeaderedByteCode: { /* image */
                NSString *cartName = [self->_gplCartridgeNameTextFiled stringValue];
                if (nil == cartName || [cartName length] == 0) {
                    NSAlert *errorAlert = [NSAlert new];
                    errorAlert.messageText = @"Missing Option";
                    [errorAlert addButtonWithTitle:@"Abort"];
                    errorAlert.informativeText = @"Please specify a name of the cartridge to create!";
                    [errorAlert runModal];
                    return NO;
                }

                NSData *data = [assemblingResult generateImageWithName:cartName error:&error];
                if (nil == error && nil != data) {
                    [data writeToURL:outputFileURL options:NSDataWritingAtomic error:&error];
                }
                break;
            }

            case XDTGa99TargetTypeMESSCartridge: {
                NSString *cartName = [self->_gplCartridgeNameTextFiled stringValue];
                if (nil == cartName || [cartName length] == 0) {
                    NSAlert *errorAlert = [NSAlert new];
                    errorAlert.messageText = @"Missing Option";
                    [errorAlert addButtonWithTitle:@"Abort"];
                    errorAlert.informativeText = @"Please specify a name of the cartridge to create!";
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
        if ([defaults boolForKey:UserDefaultKeyGPLOptionGenerateListOutput]) {
            NSURL *listingURL = [[outputFileURL URLByDeletingPathExtension] URLByAppendingPathExtension:@"dv80"];
            BOOL outputSymbols = [defaults boolForKey:UserDefaultKeyGPLOptionGenerateSymbolTable];
            BOOL useEqus = [defaults boolForKey:UserDefaultKeyGPLOptionGenerateSymbolsAsEqus];
            NSData *data = [assemblingResult generateListing:outputSymbols && !useEqus error:&error];
            NSMutableString *retVal = [[NSMutableString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            if (nil == error && outputSymbols && useEqus) {
                data = [assemblingResult generateSymbols:YES error:&error];
                [retVal appendFormat:@"\n%@\n", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]];
            }
            if (nil == error && nil != retVal && [retVal length] > 0) {
                [retVal writeToURL:listingURL atomically:YES encoding:NSUTF8StringEncoding error:&error];
            }
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
                                  NSStringFromSelector(@selector(protect)): [defaults objectForKey:UserDefaultKeyBasicOptionShouldProtectFile],
                                  NSStringFromSelector(@selector(join)): [defaults objectForKey:UserDefaultKeyBasicOptionShouldJoinSourceLines]
                                  };
        XDTBasic *basic = [XDTBasic basic];
        if (nil == basic) {
            return NO;
        }
        [basic setValuesForKeysWithDictionary:options];
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


- (IBAction)hideShowAllLogs:(nullable id)sender
{
    const BOOL isLogVisible = ((SourceCodeDocument *)NSDocumentController.sharedDocumentController.currentDocument).shouldShowLog;
    [NSDocumentController.sharedDocumentController.documents enumerateObjectsUsingBlock:^(__kindof NSDocument *doc, NSUInteger idx, BOOL *stop) {
        if (![doc isKindOfClass:[SourceCodeDocument class]]) {
            return;
        }
        ((SourceCodeDocument *)doc).shouldShowLog = !isLogVisible;
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
        [panel setTitle:NSLocalizedString(@"Select assembler source file", @"Title for opening Assembler files in Open Panel")];
    } else if ([extension isEqualToString:@"gpl"]) {
        [panel setAllowedFileTypes:@[extension]];
        [panel setTitle:NSLocalizedString(@"Select GPL assembler source file", @"Title for opening GPL Assembler files in Open Panel")];
    } else if ([extension isEqualToString:@"bas"]) {
        [panel setAllowedFileTypes:@[extension, @"b99"]];
        [panel setTitle:NSLocalizedString(@"Select TI Basic source file", @"Title for opening TI Basics files in Open Panel")];
    } else {
        NSLog(@"%s ERROR: Cannot open source file with extension of '%@'", __FUNCTION__, extension);
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
        case 6:
        case 7:
            extension = @"dat";
            break;
        case 8:
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

    [self willChangeValueForKey:NSStringFromSelector(@selector(shouldCartridgeNameActivated))];
    _shouldCartridgeNameActivated = (7 == outputFileType);
    [self didChangeValueForKey:NSStringFromSelector(@selector(shouldCartridgeNameActivated))];

    [self willChangeValueForKey:NSStringFromSelector(@selector(shouldBaseAddressActivated))];
    _shouldBaseAddressActivated = (0 == outputFileType) || (4 == outputFileType) || (5 == outputFileType);
    [self didChangeValueForKey:NSStringFromSelector(@selector(shouldBaseAddressActivated))];
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

    [self willChangeValueForKey:NSStringFromSelector(@selector(shouldCartridgeNameActivated))];
    _shouldCartridgeNameActivated = (1 == outputFileType) || (2 == outputFileType);
    [self didChangeValueForKey:NSStringFromSelector(@selector(shouldCartridgeNameActivated))];
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
    [panel setTitle:NSLocalizedString(@"Select output file name", @"Title for saving imported source code files in Save Panel")];
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
