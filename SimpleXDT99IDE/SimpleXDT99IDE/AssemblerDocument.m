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

#import "NSColorAdditions.h"

#import "AppDelegate.h"
#import "HighlighterDelegate.h"

#import <XDTools99/XDAssembler.h>
#import <XDTMessage.h>


@interface AssemblerDocument ()

@property (retain) IBOutlet NSView *specialLogOptionView;
@property (retain) IBOutlet NSView *programImageGeneratorOptionsView;
@property (retain) IBOutlet NSView *objectCodeGeneratorOptionsView;
@property (retain) IBOutlet NSView *basicGeneratorOptionsView;
@property (retain) IBOutlet NSView *rawBinGeneratorOptionsView;
@property (retain) IBOutlet NSView *rawTextGeneratorOptionsView;
@property (retain) IBOutlet NSView *messCartGeneratorOptionsView;

@property (retain) IBOutlet NSButton *assemblerTextModeRadioButton;
@property (retain) IBOutlet NSButton *basicTextModeRadioButton;
@property (retain) IBOutlet NSButton *cTextModeRadioButton;

@property (assign) NSUInteger outputFormatPopupButtonIndex;

/* Special generator options */
@property (assign) BOOL shouldCompressObjectCode;
@property (assign) BOOL shouldUseRegisterSymbols;
@property (assign) BOOL shouldBeStrict;
@property (assign) BOOL shouldUseWord;
@property (assign) BOOL shouldUseLittleEndian;
@property (assign) NSUInteger baseAddress;
@property (retain) NSString *cartridgeName;

@property (assign) XDTGenerateTextMode binaryTextMode;

/* Log options */
@property (assign, nonatomic) BOOL shouldShowListingInLog;
@property (assign, nonatomic) BOOL shouldShowSymbolsInListing;
@property (assign, nonatomic) BOOL shouldShowSymbolsAsEqus;

@property (retain) XDTAs99Objcode *assemblingResult;
@property (readonly) NSString *listOutput;
@property (readonly) NSString *symbolsOutput;

@property (retain) HighlighterDelegate *highlighterDelegate;

@property (readonly) XDTAs99TargetType targetType;

- (void)refreshHighlighting;

- (BOOL)assembleCode:(XDTAs99TargetType)xdtTargetType error:(NSError **)error;
- (BOOL)exportBinaries:(XDTAs99TargetType)xdtTargetType compressObjectCode:(BOOL)shouldCompressObjectCode error:(NSError **)error;

- (void)valueDidChangeForOutputFormatPopupButtonIndex:(XDTAs99TargetType)newTarget;

- (IBAction)switchTextMode:(id)sender;

@end


@implementation AssemblerDocument

- (instancetype)init
{
    self = [super init];
    if (nil == self) {
        return nil;
    }

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
    [_syntaxHighlighter release];
    
    [super dealloc];
#endif
}


- (void)windowControllerDidLoadNib:(NSWindowController *)aController {
    [super windowControllerDidLoadNib:aController];

    [self setLogOptionsPlaceholderView:_specialLogOptionView];

    NSToolbarItem *optionsItem = [self xdt99OptionsToolbarItem];
    if (nil != optionsItem) {
        [optionsItem setView:[self xdt99OptionsToolbarView]];
    }

    [self addObserver:self forKeyPath:NSStringFromSelector(@selector(outputFormatPopupButtonIndex)) options:NSKeyValueObservingOptionNew context:nil];

    /* Setup documents options, before any data can read and processed */
    NSUserDefaults *defaults = [[NSUserDefaultsController sharedUserDefaultsController] defaults];
    [self setShouldUseRegisterSymbols:[defaults boolForKey:UserDefaultKeyAssemblerOptionUseRegisterSymbols]];
    [self setShouldBeStrict:[defaults boolForKey:UserDefaultKeyAssemblerOptionDisableXDTExtensions]];
    [self setShouldShowListingInLog:[defaults boolForKey:UserDefaultKeyAssemblerOptionGenerateListOutput]];
    [self setShouldShowSymbolsInListing:[defaults boolForKey:UserDefaultKeyAssemblerOptionGenerateSymbolTable]];
    [self setShouldShowSymbolsAsEqus:[defaults boolForKey:UserDefaultKeyAssemblerOptionGenerateSymbolsAsEqus]];
    [self setBaseAddress:[defaults integerForKey:UserDefaultKeyAssemblerOptionBaseAddress]];
    [self setOutputFormatPopupButtonIndex:[defaults integerForKey:UserDefaultKeyAssemblerOptionOutputTypePopupIndex]];
    [self setBinaryTextMode:(XDTGenerateTextMode)[defaults integerForKey:UserDefaultKeyAssemblerOptionTextMode]];

    [self setShouldUseWord:0 != (_binaryTextMode & XDTGenerateTextModeOptionWord)];
    [self setShouldUseLittleEndian:0 != (_binaryTextMode & XDTGenerateTextModeOptionReverse)];
    
    switch (_binaryTextMode & XDTGenerateTextModeOutputMask) {
        case XDTGenerateTextModeOutputAssembler:
            _assemblerTextModeRadioButton.state = NSOnState;
            break;
        case XDTGenerateTextModeOutputBasic:
            _basicTextModeRadioButton.state = NSOnState;
            break;
        case XDTGenerateTextModeOutputC:
            _cTextModeRadioButton.state = NSOnState;
            break;

        default:
            /* invalid configurations of the text mode export option will be corrected to a default value */
            self.binaryTextMode = XDTGenerateTextModeOutputAssembler | (_binaryTextMode & !XDTGenerateTextModeOutputMask);
            _assemblerTextModeRadioButton.state = NSOnState;
            break;
    }

    /* Setup syntax highlighting */
    (void)[self setupSyntaxHighlighting];

    /* After syntax highlighting, messages get to be highlighted. */
    [self checkCode:nil];

// test begin
#if 0
    [self.assemblingResult enumerateSegmentsUsingBlock:^(NSUInteger bank, NSUInteger finalLineCount, BOOL reloc, BOOL dummy, NSArray * _Nonnull code) {
        return;
    }];
    XDTAs99Directives *directives = [XDTAs99Directives directives];
    BOOL hasDings = [directives checkDirective:@"dings"];
    BOOL hasCOPY = [directives checkDirective:@"COPY"];
    NSArray *ignos = directives.ignored;
#endif
// test end

    /* Recursive load nested files */
    BOOL openNestedFiles = [defaults boolForKey:UserDefaultKeyDocumentOptionOpenNestedFiles];
    if (openNestedFiles) {
        NSError *error = nil;
        if (![self openNestedFiles:&error]) {
            [self presentError:error];
        }
    }
}


- (void)canCloseDocumentWithDelegate:(id)delegate shouldCloseSelector:(SEL)shouldCloseSelector contextInfo:(void *)contextInfo
{
    [self removeObserver:self forKeyPath:NSStringFromSelector(@selector(outputFormatPopupButtonIndex))];

    /* Save the latest assembler options to user defaults before closing. */
    NSUserDefaults *defaults = [[NSUserDefaultsController sharedUserDefaultsController] defaults];
    [defaults setBool:_shouldUseRegisterSymbols forKey:UserDefaultKeyAssemblerOptionUseRegisterSymbols];
    [defaults setBool:_shouldBeStrict forKey:UserDefaultKeyAssemblerOptionDisableXDTExtensions];
    [defaults setBool:_shouldShowListingInLog forKey:UserDefaultKeyAssemblerOptionGenerateListOutput];
    [defaults setBool:_shouldShowSymbolsInListing forKey:UserDefaultKeyAssemblerOptionGenerateSymbolTable];
    [defaults setBool:_shouldShowSymbolsAsEqus forKey:UserDefaultKeyAssemblerOptionGenerateSymbolsAsEqus];
    [defaults setInteger:_outputFormatPopupButtonIndex forKey:UserDefaultKeyAssemblerOptionOutputTypePopupIndex];
    [defaults setInteger:_baseAddress forKey:UserDefaultKeyAssemblerOptionBaseAddress];
    _binaryTextMode = (_binaryTextMode & XDTGenerateTextModeOutputMask) +
                        (_shouldUseWord? XDTGenerateTextModeOptionWord : 0) +
                        (_shouldUseLittleEndian? XDTGenerateTextModeOptionReverse : 0);
    [defaults setInteger:_binaryTextMode forKey:UserDefaultKeyAssemblerOptionTextMode];

    [super canCloseDocumentWithDelegate:delegate shouldCloseSelector:shouldCloseSelector contextInfo:contextInfo];
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (object == self && [NSStringFromSelector(@selector(outputFormatPopupButtonIndex)) isEqualToString:keyPath]) {
        XDTAs99TargetType target = self.targetType;
        [self valueDidChangeForOutputFormatPopupButtonIndex:target];
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}


- (void)valueDidChangeForOutputFormatPopupButtonIndex:(XDTAs99TargetType)newTarget
{
    switch (newTarget) {
        case XDTAs99TargetTypeProgramImage:
            self.outputFileName = [self.outputFileName.stringByDeletingPathExtension stringByAppendingPathExtension:@"image"];
            [self setGeneratorOptionsPlaceholderView:_programImageGeneratorOptionsView];
            break;
        case XDTAs99TargetTypeObjectCode:
            self.outputFileName = [self.outputFileName.stringByDeletingPathExtension stringByAppendingPathExtension:@"obj"];
            [self setGeneratorOptionsPlaceholderView:_objectCodeGeneratorOptionsView];
            break;
        case XDTAs99TargetTypeEmbededXBasic:
            self.outputFileName = [self.outputFileName.stringByDeletingPathExtension stringByAppendingPathExtension:@"xb"];
            [self setGeneratorOptionsPlaceholderView:_basicGeneratorOptionsView];
            break;
        case XDTAs99TargetTypeRawBinary:
            self.outputFileName = [self.outputFileName.stringByDeletingPathExtension stringByAppendingPathExtension:@"bin"];
            [self setGeneratorOptionsPlaceholderView:_rawBinGeneratorOptionsView];
            break;
        case XDTAs99TargetTypeTextBinaryAsm:
        case XDTAs99TargetTypeTextBinaryBas:
        case XDTAs99TargetTypeTextBinaryC:
            self.outputFileName = [self.outputFileName.stringByDeletingPathExtension stringByAppendingPathExtension:@"dat"];
            [self setGeneratorOptionsPlaceholderView:_rawTextGeneratorOptionsView];
            break;
        case XDTAs99TargetTypeMESSCartridge:
            self.outputFileName = [self.outputFileName.stringByDeletingPathExtension stringByAppendingPathExtension:@"card"];
            self.baseAddress = 0x6000;
            [self setGeneratorOptionsPlaceholderView:_messCartGeneratorOptionsView];
            break;
            /* TODO: Since version 1.7.0 of xas99, there is a new option to export an EQU listing to a text file.
             This feature is open to implement.
             */

        default:
            break;
    }

    self.contentMinWidth.constant = self.xdt99OptionsToolbarItem.minSize.width + 16;
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

    return YES;
}


#pragma mark - Accessor Methods


- (void)setSourceCode:(NSString *)newSourceCode
{
    super.sourceCode = newSourceCode;
    if (nil != self.parser) {
        [self refreshHighlighting];
        [self checkCode:nil];
    }
}


+ (NSSet *)keyPathsForValuesAffectingListOutput
{
    return [NSSet setWithObjects:NSStringFromSelector(@selector(assemblingResult)), NSStringFromSelector(@selector(shouldShowSymbolsInListing)), NSStringFromSelector(@selector(shouldShowSymbolsAsEqus)), nil];
}


- (NSString *)listOutput
{
    NSString *retVal = nil;
    if (nil == _assemblingResult) {
        return nil;
    }

    NSError *error = nil;
    NSData *data = [_assemblingResult generateListing:NO error:&error];
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


+ (NSSet<NSString *> *)keyPathsForValuesAffectingGeneratedLogMessage
{
    NSSet *retVal = [[super superclass] keyPathsForValuesAffectingGeneratedLogMessage];

    NSMutableSet *newSet = [NSMutableSet setWithSet:retVal];
    [newSet addObject:NSStringFromSelector(@selector(shouldShowListingInLog))];
    [newSet unionSet:[self keyPathsForValuesAffectingListOutput]];
    retVal = newSet;

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
        __block NSFont *monacoFont = nil;

        NSString *listOut = [self listOutput];
        if (nil != listOut && 0 < [listOut length]) {
            [listOut enumerateLinesUsingBlock:^(NSString * _Nonnull line, BOOL * _Nonnull stop) {
                if (nil == monacoFont) {
                    /* formatting generator information */
                    NSAttributedString *formattedLine = [[NSAttributedString alloc] initWithString:(0 < retVal.length)? [NSString stringWithFormat:@"\n%@\n", line] : [line stringByAppendingString:@"\n"]
                                                                                        attributes:@{NSForegroundColorAttributeName: textColor}];
                    [retVal appendAttributedString:formattedLine];
                    monacoFont = [NSFont fontWithName:@"Monaco" size:0.0];
                } else {
                    /* formatting generated listing (first line is header) */
                    NSMutableAttributedString *formattedLine = [NSMutableAttributedString alloc];
                    formattedLine = [formattedLine initWithString:[line stringByAppendingString:@"\n"]
                                                       attributes:@{NSFontAttributeName: monacoFont}];
                    NSRange range = NSMakeRange(0, MIN(18, line.length));
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
                                                                                                 NSFontAttributeName: monacoFont
                                                                                                 }];
                [retVal appendAttributedString:formattedLine];
            }
        }
    }
    
    return retVal;
}


- (NSString *)commandLineInstruction
{
    NSURL *baseURL = self.outputBasePathURL;
    if (nil == baseURL) {
        baseURL = self.fileURL.URLByDeletingLastPathComponent;
    }
    NSMutableArray<NSString *> *cliOptions = [NSMutableArray arrayWithCapacity:8];

    NSURL *pythonModuleUrl = [NSBundle.mainBundle.resourceURL URLByAppendingPathComponent:[NSString stringWithFormat:@"%s.py", XDTAs99ModuleName]];
    [cliOptions addObject:[pythonModuleUrl.path stringByReplacingOccurrencesOfString:@" " withString:@"\\ "]];

    switch (self.targetType) {
        case XDTAs99TargetTypeProgramImage:
            [cliOptions addObject:@"-i"];
            break;

        case XDTAs99TargetTypeMESSCartridge:
            [cliOptions addObject:@"-c"];
            if (nil != self.cartridgeName) {
                NSString *cartName = [self.cartridgeName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                if (0 < cartName.length) {
                    BOOL hasSpaces = NSNotFound != [cartName rangeOfCharacterFromSet:[NSCharacterSet whitespaceCharacterSet]].location;
                    [cliOptions addObject:[NSString stringWithFormat:(hasSpaces)? @"-n \"%@\"" : @"-n %@", cartName]];
                }
            }
            break;

        case XDTAs99TargetTypeRawBinary:
            [cliOptions addObject:@"-b"];
            if (0 < self.baseAddress && NSNotFound != self.baseAddress) {
                [cliOptions addObject:[NSString stringWithFormat:@"--base 0x%04X", (unsigned short)self.baseAddress]];
            }
            break;

        case XDTAs99TargetTypeTextBinaryAsm:
        case XDTAs99TargetTypeTextBinaryBas:
        case XDTAs99TargetTypeTextBinaryC:
            [cliOptions addObject:[NSString stringWithFormat:@"-t %s", [XDTAs99Objcode textConfigAsCString:_binaryTextMode]]];
            break;

        case XDTAs99TargetTypeEmbededXBasic:
            [cliOptions addObject:@"--embed-xb"];
            break;

        case XDTAs99TargetTypeObjectCode:
        default:
            if (self.shouldCompressObjectCode) {
                [cliOptions addObject:@"-C"];
            }
            break;
    }

    if (self.shouldBeStrict) {
        [cliOptions addObject:@"-s"];
    }
    if (!self.shouldShowWarningsInLog) {
        [cliOptions addObject:@"-w"];
    }
    if (self.shouldUseRegisterSymbols) {
        [cliOptions addObject:@"-R"];
    }
    if (self.shouldShowSymbolsInListing) {
        [cliOptions addObject:@"-S"];
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


- (void)checkCode:(id)sender
{
    [super checkCode:sender];
    if (self.isDocumentEdited) {
        return;
    }
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
    [super checkCode:sender];
    if (self.isDocumentEdited) {
        return;
    }
    NSError *error = nil;

    XDTAs99TargetType xdtTargetType = [self targetType];
    if (![self assembleCode:xdtTargetType error:&error] || nil != error ||
        ![self exportBinaries:xdtTargetType compressObjectCode:_shouldCompressObjectCode error:&error] || nil != error) {
        if (nil != error) {
            if (!self.shouldShowErrorsInLog || !self.shouldShowLog) {
                [self presentError:error modalForWindow:[self windowForSheet] delegate:nil didPresentSelector:nil contextInfo:nil];
            }
            return;
        }
    }
}


- (void)switchTextMode:(id)sender
{
    if (![sender isKindOfClass:[NSButton class]]) {
        return;
    }
    NSButton *button = (NSButton *)sender;
    _binaryTextMode = button.tag +
                        (_shouldUseWord? XDTGenerateTextModeOptionWord : 0) +
                        (_shouldUseLittleEndian? XDTGenerateTextModeOptionReverse : 0);
}


#pragma mark - Private Methods


- (void)refreshHighlighting
{
    if (nil == self.highlighterDelegate) {
        return;
    }

    NSMutableAttributedString *newSourceCode = self.attributedSourceCode.mutableCopy;
    [newSourceCode beginEditing];
    [newSourceCode.mutableString enumerateSubstringsInRange:(NSRange)NSMakeRange(0, newSourceCode.length)
                                                    options:NSStringEnumerationByLines + NSStringEnumerationSubstringNotRequired
                                                 usingBlock:^(NSString *line, NSRange lineRange, NSRange enclosingRange, BOOL *stop) {
                                                     [self.highlighterDelegate processAttributesOfText:newSourceCode inRange:lineRange];
                                                 }];
    [newSourceCode endEditing];
    self.attributedSourceCode = newSourceCode;
}


- (BOOL)setupSyntaxHighlighting
{
    BOOL useSyntaxHighlighting = [super setupSyntaxHighlighting];
    if (!useSyntaxHighlighting) {
        return NO;
    }

    if (nil == self.parser) {
        self.parser = [XDTAs99Parser parserForPath:self.fileURL.URLByDeletingLastPathComponent.path usingRegisterSymbol:self.shouldUseRegisterSymbols strictness:self.shouldBeStrict outputWarnings:self.shouldShowWarningsInLog];
        self.parser.source = self.sourceView.textStorage.mutableString;

        if (nil == self.highlighterDelegate) {
            self.highlighterDelegate = [HighlighterDelegate highlighterWithLineScanner:[XDTLineScanner scannerWithParser:self.parser
                                                                                                                 symbols:self.assemblingResult.symbols.symbolNames]];
        }
    }
    self.sourceView.textStorage.delegate = self.highlighterDelegate;

    [self refreshHighlighting];

    return useSyntaxHighlighting;
}


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
            xdtTargetType = XDTAs99TargetTypeObjectCode;
            break;
        case 2:
            xdtTargetType = XDTAs99TargetTypeEmbededXBasic;
            break;
        case 3:
            xdtTargetType = XDTAs99TargetTypeRawBinary;
            break;
        case 4:
            switch (_binaryTextMode & XDTGenerateTextModeOutputMask) {
                case XDTGenerateTextModeOutputAssembler:
                    xdtTargetType = XDTAs99TargetTypeTextBinaryAsm;
                    break;
                case XDTGenerateTextModeOutputBasic:
                    xdtTargetType = XDTAs99TargetTypeTextBinaryBas;
                    break;
                case XDTGenerateTextModeOutputC:
                    xdtTargetType = XDTAs99TargetTypeTextBinaryC;
                    break;

                default:
                    xdtTargetType = XDTAs99TargetTypeTextBinaryAsm;
                    break;
            }
            break;
        case 5:
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

    XDTAssembler *assembler = [XDTAssembler assemblerWithIncludeURL:[self fileURL] target:xdtTargetType usingRegisterSymbol:self.shouldUseRegisterSymbols strictness:self.shouldBeStrict outputWarnings:self.shouldShowWarningsInLog];

    NSError *tempErr = nil;
    XDTAs99Objcode *result = [assembler assembleSourceFile:[self fileURL] error:&tempErr];
    [self setAssemblingResult:result];
    [self setGeneratorMessages:assembler.messages];

#if 0
    if (nil != result) {
        //[(XDTAs99Parser *)self.parser setMessages:[XDTMessage message]];
        [XDTAs99Optimizer.optimizer optimizeCode:result usingParser:(XDTAs99Parser *)self.parser forMnemonic:@"B" arguments:@[@"@$+2"]];
        XDTMessage *m = [(XDTAs99Parser *)self.parser messages];
    }
#endif

    /* set the number of digits of line numbers in the superclass to configure the log format */
    [super setValue:@4 forKey:@"lineNumberDigits"];

    if (nil != error) {
        *error = tempErr;
    }
    return nil == tempErr;
}


- (BOOL)exportBinaries:(XDTAs99TargetType)xdtTargetType compressObjectCode:(BOOL)shouldCompressObjectCode error:(NSError **)error
{
    BOOL retVal = YES;

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
        case XDTAs99TargetTypeTextBinaryAsm:
        case XDTAs99TargetTypeTextBinaryBas:
        case XDTAs99TargetTypeTextBinaryC: {
            NSError *tempError = nil;
            // TODO: extend GUI for new configuration options
            _binaryTextMode = (_binaryTextMode & XDTGenerateTextModeOutputMask) +
                                (_shouldUseWord? XDTGenerateTextModeOptionWord : 0) +
                                (_shouldUseLittleEndian? XDTGenerateTextModeOptionReverse : 0);
            NSString *fileContent = [_assemblingResult generateTextAt:_baseAddress withMode:_binaryTextMode error:&tempError];
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
