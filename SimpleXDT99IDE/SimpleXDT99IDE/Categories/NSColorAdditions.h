//
//  NSColorAdditions.h
//  SimpleXDT99IDE
//
//  Created by henrik on 03.07.19.
//  Copyright © 2019 hackmac. All rights reserved.
//

#import <Cocoa/Cocoa.h>


NS_ASSUME_NONNULL_BEGIN

@interface NSColor (NSColorAdditions)

@property (class, strong, readonly) NSColor *XDTErrorTextColor;
@property (class, strong, readonly) NSColor *XDTExceptionTextColor;
@property (class, strong, readonly) NSColor *XDTWarningTextColor;

@end

NS_ASSUME_NONNULL_END
