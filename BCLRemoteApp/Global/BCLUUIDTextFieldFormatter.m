//
//  BCLUUIDTextFieldFormatter.m
//  BCLRemoteApp
//
// Copyright (c) 2015, Upnext Technologies Sp. z o.o.
// All rights reserved.
//
// This source code is licensed under the BSD 3-Clause License found in the
// LICENSE.txt file in the root directory of this source tree.
//

#import "BCLUUIDTextFieldFormatter.h"

@interface BCLUUIDTextFieldFormatter () {
    NSString *previousTextFieldContent;
    UITextRange *previousSelection;
}
@end

@implementation BCLUUIDTextFieldFormatter

- (void)reformatAsUUID:(UITextField *)textField
{
    NSUInteger targetCursorPosition =
            [textField offsetFromPosition:textField.beginningOfDocument
                               toPosition:textField.selectedTextRange.start];

    NSString *uuidWithoutSpaces =
            [self removeNonDigits:textField.text
        andPreserveCursorPosition:&targetCursorPosition];

    if ([uuidWithoutSpaces length] > 32) {
        [textField setText:previousTextFieldContent];
        textField.selectedTextRange = previousSelection;
        return;
    }

    NSString *uuidWithDashes =
            [self insertDashes:uuidWithoutSpaces
     andPreserveCursorPosition:&targetCursorPosition];

    textField.text = uuidWithDashes;
    UITextPosition *targetPosition =
            [textField positionFromPosition:[textField beginningOfDocument]
                                     offset:targetCursorPosition];

    [textField setSelectedTextRange:
            [textField textRangeFromPosition:targetPosition
                                  toPosition:targetPosition]
    ];
}

- (BOOL)textField:(UITextField *)textField
        shouldChangeCharactersInRange:(NSRange)range
        replacementString:(NSString *)string
{
    previousTextFieldContent = textField.text;
    previousSelection = textField.selectedTextRange;

    return YES;
}

- (NSString *)removeNonDigits:(NSString *)string
    andPreserveCursorPosition:(NSUInteger *)cursorPosition
{
    NSUInteger originalCursorPosition = 0;
    if (cursorPosition) {
        originalCursorPosition = *cursorPosition;
    }
    NSMutableString *digitsOnlyString = [NSMutableString new];
    for (NSUInteger i=0; i<[string length]; i++) {
        unichar characterToAdd = [string characterAtIndex:i];
        if (isxdigit(characterToAdd)) {
            NSString *stringToAdd =
                    [NSString stringWithCharacters:&characterToAdd
                                            length:1];

            [digitsOnlyString appendString:stringToAdd];
        }
        else {
            if (cursorPosition && i < originalCursorPosition) {
                (*cursorPosition)--;
            }
        }
    }

    return digitsOnlyString;
}

- (NSString *)insertDashes:(NSString *)string andPreserveCursorPosition:(NSUInteger *)cursorPosition
{
    NSMutableString *stringWithAddedDashes = [NSMutableString new];
    NSUInteger cursorPositionInSpacelessString = *cursorPosition;
    for (NSUInteger i=0; i<[string length]; i++) {
        if ((i>7) && ((i % 4) == 0) && i <= 20) {
            [stringWithAddedDashes appendString:@"-"];
            if (i < cursorPositionInSpacelessString) {
                (*cursorPosition)++;
            }
        }
        unichar characterToAdd = [string characterAtIndex:i];
        NSString *stringToAdd =
                [NSString stringWithCharacters:&characterToAdd length:1];

        [stringWithAddedDashes appendString:stringToAdd];
    }

    return stringWithAddedDashes;
}

- (void)setTextField:(UITextField *)textField
{
    [_textField removeTarget:self action:nil forControlEvents:UIControlEventAllEvents];
    _textField = textField;
    [_textField addTarget:self action:@selector(reformatAsUUID:) forControlEvents:UIControlEventEditingChanged];
}

- (void)dealloc
{
    [_textField removeTarget:self action:nil forControlEvents:UIControlEventAllEvents];
}


- (BOOL)isValid
{
    NSString *uuidWithoutSpaces =
            [self removeNonDigits:self.textField.text
        andPreserveCursorPosition:nil];
    return uuidWithoutSpaces.length == 32;
}
@end
