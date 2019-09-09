//
//  GPLAssemblerDocument.m
//  SimpleXDT99IDE
//
//  Created by Henrik Wedekind on 16.12.16.
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

#import "GPLAssemblerDocument.h"

#import "NSColorAdditions.h"

#import "AppDelegate.h"
#import "HighlighterDelegate.h"

#import <XDTools99/XDGPL.h>


@interface GPLAssemblerDocument ()

@property (retain) IBOutlet NSView *specialLogOptionView;

/* Special generator options */
@property (assign) NSUInteger gromAddress;
@property (assign) NSUInteger aorgAddress;
@property (retain) NSString *cartridgeName;
@property (readonly) BOOL shouldUseCartName;

@property (assign) NSUInteger outputFormatPopupButtonIndex;
@property (assign) NSUInteger syntaxFormatPopupButtonIndex;

/* Log options */
@property (assign) BOOL shouldShowListingInLog;
@property (assign) BOOL shouldShowSymbolsInListing;
@property (assign) BOOL shouldShowSymbolsAsEqus;

@property (retain) XDTGa99Objcode *assemblingResult;
@property (readonly) NSString *listOutput;
@property (readonly) NSString *symbolsOutput;

@property (readonly) XDTGa99TargetType targetType;
@property (readonly) XDTGa99SyntaxType syntaxType;

- (BOOL)assembleCode:(XDTGa99TargetType)xdtTargetType error:(NSError **)error;
- (BOOL)exportBinaries:(XDTGa99TargetType)xdtTargetType error:(NSError **)error;

- (void)valueDidChangeForOutputFormatPopupButtonIndex:(XDTGa99TargetType)newTarget;

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

    [self setLogOptionsPlaceholderView:_specialLogOptionView];

    [self addObserver:self forKeyPath:NSStringFromSelector(@selector(outputFormatPopupButtonIndex)) options:NSKeyValueObservingOptionNew context:nil];

    NSToolbarItem *optionsItem = [self xdt99OptionsToolbarItem];
    if (nil != optionsItem) {
        [optionsItem setView:[self xdt99OptionsToolbarView]];
    }

    self.contentMinWidth.constant = self.xdt99OptionsToolbarItem.minSize.width + 16;

    (void)[self setupSyntaxHighlighting];

    if (nil != self.fileURL) {
        NSError *err = nil;
        NSDictionary *docOptions = @{
                                     NSDocumentTypeDocumentOption: NSPlainTextDocumentType,
                                     NSCharacterEncodingDocumentOption: [NSNumber numberWithUnsignedInteger:NSUTF8StringEncoding],
                                     NSDefaultAttributesDocumentOption: @{NSForegroundColorAttributeName: [NSColor XDTSourceTextColor],
                                                                          NSFontAttributeName: [NSFont fontWithName:@"Menlo" size:0.0]}
                                     };
        NSAttributedString *sourceCode = [[NSAttributedString alloc] initWithURL:self.fileURL options:docOptions documentAttributes:nil error:&err];
        if (nil == sourceCode) {
            [self presentError:err];
        } else {
            self.sourceView.textStorage.attributedString = sourceCode;
        }
    }
    
    /* Recursive load nested files */
    NSUserDefaults *defaults = [[NSUserDefaultsController sharedUserDefaultsController] defaults];
    BOOL openNestedFiles = [defaults boolForKey:UserDefaultKeyDocumentOptionOpenNestedFiles];
    if (openNestedFiles) {
        NSError *error = nil;
        if (![self openNestedFiles:&error]) {
            (void)[self presentError:error];
        }
    }
}


- (void)canCloseDocumentWithDelegate:(id)delegate shouldCloseSelector:(SEL)shouldCloseSelector contextInfo:(void *)contextInfo
{
    [self removeObserver:self forKeyPath:NSStringFromSelector(@selector(outputFormatPopupButtonIndex))];

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


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (object == self && [NSStringFromSelector(@selector(outputFormatPopupButtonIndex)) isEqualToString:keyPath]) {
        XDTGa99TargetType target = self.targetType;
        [self valueDidChangeForOutputFormatPopupButtonIndex:target];
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}


- (void)valueDidChangeForOutputFormatPopupButtonIndex:(XDTGa99TargetType)newTarget
{
    switch (newTarget) {
        case 0: /* Plain GPL byte code */
            self.outputFileName = [self.outputFileName.stringByDeletingPathExtension stringByAppendingPathExtension:@"gbc"];
            break;
        case 1: /* Image: GPL with header */
            self.outputFileName = [self.outputFileName.stringByDeletingPathExtension stringByAppendingPathExtension:@"bin"];
            break;
        case 2: /* MESS cartridge */
            self.outputFileName = [self.outputFileName.stringByDeletingPathExtension stringByAppendingPathExtension:@"rpk"];
            break;

        default:
            break;
    }
}


- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError {
    if (![@"Xga99DocumentType" isEqualToString:typeName]) {
        if (outError) {
            *outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:nil];
        }
        return nil;
    }
    NSData *retVal = [self.sourceView.attributedString dataFromRange:NSMakeRange(0, self.sourceView.attributedString.length)
                                                  documentAttributes:@{NSDocumentTypeDocumentAttribute: NSPlainTextDocumentType,
                                                                       NSCharacterEncodingDocumentAttribute: [NSNumber numberWithUnsignedInteger:NSUTF8StringEncoding]
                                                                       }
                                                               error:outError];
    return retVal;
}


- (BOOL)readFromURL:(NSURL *)url ofType:(NSString *)typeName error:(NSError **)outError
{
    if (![@"Xga99DocumentType" isEqualToString:typeName]) {
        if (outError) {
            *outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:kPOSIXErrorEFTYPE userInfo:nil];
        }
        return NO;
    }

    self.cartridgeName = url.lastPathComponent.stringByDeletingPathExtension;
    self.outputFileName = [_cartridgeName stringByAppendingString:@"-obj"];
    self.outputBasePathURL = url.URLByDeletingLastPathComponent;

    return YES;
}


- (BOOL)setupSyntaxHighlighting
{
    BOOL useSyntaxHighlighting = [super setupSyntaxHighlighting];

    if (nil == self.parser) {
        self.parser = [XDTGa99Parser parserForPath:self.fileURL.URLByDeletingLastPathComponent.path
                                   usingSyntaxType:self.syntaxType

                                    outputWarnings:self.shouldShowWarningsInLog];
        self.parser.source = self.sourceView.textStorage.mutableString;
    }

    if (nil == self.highlighterDelegate) {
        self.highlighterDelegate = [HighlighterDelegate highlighterWithLineScanner:[XDTLineScanner scannerWithParser:self.parser symbols:self.assemblingResult.symbols.symbolNames]];
    }

    return useSyntaxHighlighting;
}


#pragma mark - Accessor Methods


+ (NSSet *)keyPathsForValuesAffectingShouldUseCartName
{
    return [NSSet setWithObject:NSStringFromSelector(@selector(outputFormatPopupButtonIndex))];
}


- (BOOL)shouldUseCartName
{
    return (1 == _outputFormatPopupButtonIndex) || (2 == _outputFormatPopupButtonIndex);
}


+ (NSSet *)keyPathsForValuesAffectingListOutput
{
    return [NSSet setWithObjects:NSStringFromSelector(@selector(assemblingResult)), NSStringFromSelector(@selector(shouldShowSymbolsInListing)), NSStringFromSelector(@selector(shouldShowSymbolsAsEqus)), nil];
}


- (NSString *)listOutput
{
    NSMutableString *retVal = nil;
    if (nil == _assemblingResult) {
        return nil;
    }

    NSError *error = nil;
    NSData *data = [_assemblingResult generateListing:NO error:&error];
    if (nil == error && nil != data) {
        retVal = [[NSMutableString alloc] initWithData:data encoding:NSUTF8StringEncoding];
#if !__has_feature(objc_arc)
        [retVal autorelease];
#endif
    }
    if (nil != error) {
        [self presentError:error modalForWindow:[self windowForSheet] delegate:nil didPresentSelector:nil contextInfo:nil];
        return nil;
    }
    return retVal;
}


- (NSString *)symbolsOutput
{
    NSString *retVal = nil;
    if (nil == _assemblingResult) {
        return nil;
    }

    NSError *error = nil;
    NSData *data = [_assemblingResult generateSymbols:_shouldShowSymbolsAsEqus error:&error];
    if (nil == error && nil != data) {
        retVal = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
#if !__has_feature(objc_arc)
        [retVal autorelease];
#endif
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
        retVal = newSet;
    }
    return retVal;
}


- (NSAttributedString *)generatedLogMessage
{
    NSMutableAttributedString *retVal = [super generatedLogMessage];
    if (nil == retVal || ![self shouldShowLog]) {
        return retVal;
    }

    if (_shouldShowListingInLog) {
        NSColor *textColor = [NSColor textColor];
        NSColor *systemGrayColor = [NSColor systemGrayColor];
        __block NSFont *monoSpacedFont = nil;

        NSString *listOut = [self listOutput];
        if (nil != listOut && 0 < [listOut length]) {
            [listOut enumerateLinesUsingBlock:^(NSString * _Nonnull line, BOOL * _Nonnull stop) {
                if (nil == monoSpacedFont) {
                    /* formatting generator information */
                    NSAttributedString *formattedLine = [[NSAttributedString alloc] initWithString:(0 < retVal.length)? [NSString stringWithFormat:@"\n%@\n", line] : [line stringByAppendingString:@"\n"]
                                                                                        attributes:@{NSForegroundColorAttributeName: textColor}];
                    [retVal appendAttributedString:formattedLine];
                    monoSpacedFont = [NSFont fontWithName:@"Menlo" size:0.0];
                } else {
                    /* formatting generated listing (first line is NOT header, like xas99 has) */
                    NSMutableAttributedString *formattedLine = [NSMutableAttributedString alloc];
                    formattedLine = [formattedLine initWithString:[line stringByAppendingString:@"\n"]
                                                       attributes:@{NSFontAttributeName: monoSpacedFont}];
                    NSRange range = NSMakeRange(0, MIN(15, line.length));
                    [formattedLine addAttribute:NSForegroundColorAttributeName value:systemGrayColor range:range];
                    range.location += range.length;
                    range.length = line.length - range.length;
                    [formattedLine addAttribute:NSForegroundColorAttributeName value:textColor range:range];
                    [retVal appendAttributedString:formattedLine];
                }
            }];
        }

        if (_shouldShowSymbolsInListing) {
            NSString *symbolsOut = [self symbolsOutput];
            if (nil != symbolsOut && 0 < [symbolsOut length]) {
                NSAttributedString *formattedLine = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"\n%@\n", symbolsOut]
                                                                                    attributes:@{
                                                                                                 NSForegroundColorAttributeName: textColor,
                                                                                                 NSFontAttributeName: monoSpacedFont
                                                                                                 }];
                [retVal appendAttributedString:formattedLine];
            }
        }
    }

    return retVal;
}


- (NSURL *)urlForIncludedFile:(NSString *)name
{
    NSError *error = nil;

    XDTGa99Parser *parser = [XDTGa99Parser parserForPath:self.fileURL.URLByDeletingLastPathComponent.path usingSyntaxType:self.syntaxType outputWarnings:self.shouldShowWarningsInLog];
    NSString *filePath = [parser findFile:name error:&error];
    if (nil != error) {
        NSLog(@"File not found: %@/%@", self.fileURL.URLByDeletingLastPathComponent.path, name);
        [self presentError:error modalForWindow:[self windowForSheet] delegate:nil didPresentSelector:nil contextInfo:nil];
        return nil;
    }

    NSURL *retVal = [NSURL fileURLWithPath:filePath];
    return retVal;
}


- (NSString *)commandLineInstruction
{
    NSURL *baseURL = self.outputBasePathURL;
    if (nil == baseURL) {
        baseURL = self.fileURL.URLByDeletingLastPathComponent;
    }
    NSMutableArray<NSString *> *cliOptions = [NSMutableArray arrayWithCapacity:10];

    NSURL *pythonModuleUrl = [NSBundle.mainBundle.resourceURL URLByAppendingPathComponent:[NSString stringWithFormat:@"%s.py", XDTGa99ModuleName]];
    [cliOptions addObject:[pythonModuleUrl.path stringByReplacingOccurrencesOfString:@" " withString:@"\\ "]];

    switch (self.syntaxType) {
        case XDTGa99SyntaxTypeRAGGPL:       /* R.A.G GPL is obsolete and included in the native type */
        case XDTGa99SyntaxTypeNativeXDT99:
            break;
        case XDTGa99SyntaxTypeTIImageTool:
            [cliOptions addObject:@"-y mizapf"];
            break;

        default:
            break;
    }

    switch (self.targetType) {
        case XDTGa99TargetTypeHeaderedByteCode:
            [cliOptions addObject:@"-i"];
            break;
        case XDTGa99TargetTypePlainByteCode:
            break;
        case XDTGa99TargetTypeMESSCartridge:
            [cliOptions addObject:@"-c"];
            break;

        default:
            break;
    }

    if (0 < self.aorgAddress && NSNotFound != self.aorgAddress) {
        [cliOptions addObject:[NSString stringWithFormat:@"-A 0x%04X", (unsigned short)self.aorgAddress]];
    }
    if (0 < self.gromAddress && NSNotFound != self.gromAddress) {
        [cliOptions addObject:[NSString stringWithFormat:@"-G 0x%04X", (unsigned short)self.gromAddress]];
    }

    if (nil != self.cartridgeName && (XDTGa99TargetTypeHeaderedByteCode == self.targetType || XDTGa99TargetTypeMESSCartridge == self.targetType)) {
        NSString *cartName = [self.cartridgeName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        if (0 < cartName.length) {
            BOOL hasSpaces = NSNotFound != [cartName rangeOfCharacterFromSet:[NSCharacterSet whitespaceCharacterSet]].location;
            [cliOptions addObject:[NSString stringWithFormat:(hasSpaces)? @"-n \"%@\"" : @"-n %@", cartName]];
        }
    }
    if (self.shouldShowSymbolsAsEqus) {
        NSString *symbolsFileName = self.fileURL.lastPathComponent.stringByDeletingPathExtension;
        NSURL *listFileUrl = [[NSURL fileURLWithPath:symbolsFileName relativeToURL:baseURL] URLByAppendingPathExtension:@"sym"];
        [cliOptions addObject:[NSString stringWithFormat:@"-E %@", [listFileUrl.relativePath stringByReplacingOccurrencesOfString:@" " withString:@"\\ "]]];
    }
    if (self.shouldShowListingInLog) {
        NSString *listFileName = self.fileURL.lastPathComponent.stringByDeletingPathExtension;
        NSURL *listFileUrl = [[NSURL fileURLWithPath:listFileName relativeToURL:baseURL] URLByAppendingPathExtension:@"lst"];
        [cliOptions addObject:[NSString stringWithFormat:@"-L %@", [listFileUrl.relativePath stringByReplacingOccurrencesOfString:@" " withString:@"\\ "]]];
        if (self.shouldShowSymbolsInListing) {
            [cliOptions addObject:@"-S"];
        }
    }

    if (nil != self.outputFileName) {
        NSString *outputFileName = [self.outputFileName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        if (0 < outputFileName.length) {
            NSURL *outputFileUrl = [NSURL fileURLWithPath:outputFileName relativeToURL:baseURL];
            [cliOptions addObject:[NSString stringWithFormat:@"-o %@", [outputFileUrl.relativePath stringByReplacingOccurrencesOfString:@" " withString:@"\\ "]]];
        }
    }

    NSURL *inputFileUrl = [NSURL fileURLWithPath:self.fileURL.lastPathComponent relativeToURL:self.fileURL.URLByDeletingLastPathComponent];
    NSString *inputFileName = ([inputFileUrl.baseURL isNotEqualTo:baseURL])? inputFileUrl.path : inputFileUrl.relativePath;
    return [NSString stringWithFormat:@"%@ %@", [cliOptions componentsJoinedByString:@" "], [inputFileName stringByReplacingOccurrencesOfString:@" " withString:@"\\ "]];
}


#pragma mark - Action Methods


- (IBAction)checkCode:(id)sender
{
    [super checkCode:sender];
    if (self.isDocumentEdited) {
        return;
    }
    NSError *error = nil;

    XDTGa99TargetType xdtTargetType = [self targetType];
    if (![self assembleCode:xdtTargetType error:&error]) {
        if (nil != error) {
            (void)[self presentError:error];
        }
    }
}


- (IBAction)generateCode:(id)sender
{
    [super checkCode:sender];
    if (self.isDocumentEdited) {
        return;
    }
    NSError *error = nil;

    XDTGa99TargetType xdtTargetType = [self targetType];
    if (![self assembleCode:xdtTargetType error:&error] || nil != error ||
        ![self exportBinaries:xdtTargetType error:&error] || nil != error) {
        if (nil != error) {
            (void)[self presentError:error];
        }
    }
}


#pragma mark - Private Methods


+ (NSSet *)keyPathsForValuesAffectingTargetType
{
    return [NSSet setWithObject:NSStringFromSelector(@selector(outputFormatPopupButtonIndex))];
}


- (XDTGa99TargetType)targetType
{
    XDTGa99TargetType xdtTargetType = XDTGa99TargetTypePlainByteCode;
    switch (_outputFormatPopupButtonIndex) {
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
    return xdtTargetType;
}


+ (NSSet *)keyPathsForValuesAffectingSyntaxType
{
    return [NSSet setWithObject:NSStringFromSelector(@selector(syntaxFormatPopupButtonIndex))];
}


- (XDTGa99SyntaxType)syntaxType
{
    XDTGa99SyntaxType xdtSyntaxType = XDTGa99SyntaxTypeNativeXDT99;
    switch (_syntaxFormatPopupButtonIndex) {
        case 0:
            xdtSyntaxType = XDTGa99SyntaxTypeNativeXDT99;
            break;
        case 1:
            xdtSyntaxType = XDTGa99SyntaxTypeRAGGPL;
            break;
        case 2:
            xdtSyntaxType = XDTGa99SyntaxTypeTIImageTool;
            break;

        default:
            break;
    }
    return xdtSyntaxType;
}


- (BOOL)assembleCode:(XDTGa99TargetType)xdtTargetType error:(NSError **)error
{
    if (nil == [self fileURL]) {    // there must be a file which can be assembled
        return NO;
    }

    XDTGPLAssembler *assembler = [XDTGPLAssembler gplAssemblerWithIncludeURL:[self fileURL] grom:self.gromAddress aorg:self.aorgAddress target:self.targetType syntax:self.syntaxType outputWarnings:self.shouldShowWarningsInLog];

    NSError *tempErr = nil;
    XDTGa99Objcode *result = [assembler assembleSourceFile:[self fileURL] error:&tempErr];
    [self setAssemblingResult:result];
    [self setGeneratorMessages:assembler.messages];

    /* set the number of digits of line numbers in the superclass to configure the log format */
    [super setValue:@4 forKey:@"lineNumberDigits"];

    if (nil != error) {
        *error = tempErr;
    }
    return nil == tempErr;
}


- (BOOL)exportBinaries:(XDTGa99TargetType)xdtTargetType error:(NSError **)error
{
    BOOL retVal = YES;

    switch (xdtTargetType) {
        case XDTGa99TargetTypePlainByteCode:    /* byte code */
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

        case XDTGa99TargetTypeHeaderedByteCode: { /* image */
            if (nil == _cartridgeName || [_cartridgeName length] == 0) {
                NSDictionary *errorDict = @{
                                            NSLocalizedDescriptionKey: NSLocalizedString(@"Missing Option!", @"Error description of a missing option."),
                                            NSLocalizedRecoverySuggestionErrorKey: NSLocalizedString(@"The cartridge name is missing! Please specify a name of the cartridge to create!", @"Explanation for an error of a missing cartridge name option.")
                                            };
                NSError *missingOptionError = [NSError errorWithDomain:XDTErrorDomain code:XDTErrorCodeToolException userInfo:errorDict];
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

        case XDTGa99TargetTypeMESSCartridge: {
            if (nil == _cartridgeName || [_cartridgeName length] == 0) {
                NSDictionary *errorDict = @{
                                            NSLocalizedDescriptionKey: NSLocalizedString(@"Missing Option!", @"Error description of a missing option."),
                                            NSLocalizedRecoverySuggestionErrorKey: NSLocalizedString(@"The cartridge name is missing! Please specify a name of the cartridge to create!", @"Explanation for an error of a missing cartridge name option.")
                                            };
                NSError *missingOptionError = [NSError errorWithDomain:XDTErrorDomain code:XDTErrorCodeToolException userInfo:errorDict];
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
