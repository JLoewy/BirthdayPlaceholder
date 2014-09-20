//
//  ViewController.m
//  Birthday Formatting
//
//  Created by Jason Loewy on 9/20/14.
//  Copyright (c) 2014 Jason Loewy. All rights reserved.
//

#import "ViewController.h"

@interface ViewController () <UITextFieldDelegate>

@property (strong, nonatomic) IBOutlet UITextField *birthdayTextField;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [_birthdayTextField setDelegate:self];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [_birthdayTextField becomeFirstResponder];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/**
 * Responsible for handling the user text input for the birthday label
 * Must make sure the pseudo placeholder text appears throughout input
 * Must also make sure that only valid text is placed into the label for display (validates date entries)
 *
 * @PARAM textField The text field that is being worked on
 * @PARAM range     The range of characters that are attempting to be changed
 * @PARAM string    The new characters that are being added/deleted from the textfield
 *
 * @RETURN a boolean value that said if the content should be added to the text field from this function it is always NO because the text changes are handled in explicetly through the 'setTexts' in here
 */
static NSString* __placeholderText = @"MM/DD/YYYY";
static NSCharacterSet* __nonNumbersSet;
- (BOOL) textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    // Make sure that the non number set is lazily initialized
    if (__nonNumbersSet == nil)
        __nonNumbersSet = [[NSCharacterSet characterSetWithCharactersInString:@"0123456789"] invertedSet];
    
    NSString* preEditString = textField.text;
    __block NSInteger activeLength = 0;
    NSAttributedString* attributedString = _birthdayTextField.attributedText;
    [attributedString enumerateAttribute:NSForegroundColorAttributeName inRange:NSMakeRange(0, attributedString.length) options:NSAttributedStringEnumerationLongestEffectiveRangeNotRequired usingBlock:^(id value, NSRange range, BOOL *stop) {
        
        if ([value isKindOfClass:[UIColor class]])
        {
            CGFloat white;
            [((UIColor*)value) getWhite:&white alpha:nil];
            if (white != 1.0f)
                activeLength = range.location;
        }
        
    }];
    
    // If there is no pseudo placeholder text then that means it has reached the end
    if (activeLength == 0 &&
        _birthdayTextField.text.length == 10 &&
        ![_birthdayTextField.text isEqualToString:__placeholderText])
    {
        activeLength = _birthdayTextField.text.length;
    }
    
    // Perform the edits as long as the birthday text length limit hasnt been reached
    if (!(activeLength == 10 && string.length > 0))
    {
        if (string.length <= 0)
        {
            if (textField.text.length > 0)
            {
                //----
                // Determine if you need to just delete the last character or
                // the last two characterse (delete / as well)
                //----
                NSInteger deleteDelta = [[textField.text substringWithRange:NSMakeRange(activeLength-1, 1)] isEqualToString:@"/"] ? 2 : 1;
                if (activeLength <= deleteDelta)
                {
                    [_birthdayTextField setText:@""];
                    return NO;
                }
                else
                    [_birthdayTextField setText:[NSString stringWithFormat:@"%@", [_birthdayTextField.text substringToIndex:(activeLength - deleteDelta)]]];
            }
        }
        else if ([string rangeOfCharacterFromSet:__nonNumbersSet].location == NSNotFound)
        {
            // Enter here if the input was a numbe
            if (activeLength < 2)
            {
                // Check to make sure that the month field is 1-12
                NSInteger month = [[textField.text stringByAppendingString:string] integerValue];
                if (month <= 12 && month >= 0)
                {
                    if (textField.text.length == 0)
                    {
                        // Enter here to handle the first value being input
                        if ([string integerValue] > 1)
                        {
                            //----
                            // Enter here because you need to add the prefix 0 since they enetered a digit 2-9
                            // and that wont work as the first digit in a month
                            //----
                            [_birthdayTextField setText:[NSString stringWithFormat:@"0%@/", string]];
                        }
                        else
                            [_birthdayTextField setText:[NSString stringWithFormat:@"%@", string]];
                    }
                    else
                    {
                        //-----
                        // Enter here if entering the second digit of the month
                        // Need to make sure it reacts properly based off of the first digit in the month
                        //-----
                        if ([[textField.text substringToIndex:1] isEqualToString:@"0"] || [string integerValue] <= 2)
                            [textField setText:[NSString stringWithFormat:@"%@%@/", [textField.text substringToIndex:activeLength], string]];
                    }
                }
            }
            else if (activeLength < 6)
            {
                // Handle the day aspect of the birthday input
                if (activeLength == 3)
                {
                    //----
                    // Only allow 0-3 in the first day spot
                    // Otherwise prefix it with a 0
                    //----
                    if ([string isEqualToString:@"0"] || [string isEqualToString:@"1"] ||
                        [string isEqualToString:@"2"] || [string isEqualToString:@"3"])
                    {
                        [_birthdayTextField setText:[NSString stringWithFormat:@"%@%@", [_birthdayTextField.text substringToIndex:activeLength], string]];
                    }
                    else
                    {
                        [_birthdayTextField setText:[NSString stringWithFormat:@"%@0%@/", [_birthdayTextField.text substringToIndex:activeLength], string]];
                    }
                }
                else if (activeLength == 4)
                {
                    [_birthdayTextField setText:[NSString stringWithFormat:@"%@%@/", [_birthdayTextField.text substringToIndex:activeLength], string]];
                }
            }
            else if (activeLength < 11)
            {
                // Handle the year aspect of the birthday input
                BOOL addText;
                if (activeLength == 6)
                {
                    // Only allow for 19XX or 2XXX dates
                    addText = ([string isEqualToString:@"1"] || [string isEqualToString:@"2"]) ? YES : NO;
                }
                else
                    addText = YES;
                
                if (addText)
                    [_birthdayTextField setText:[NSString stringWithFormat:@"%@%@", [_birthdayTextField.text substringToIndex:activeLength], string]];
            }
        }
        
        //----
        // Add whatever placeholder text is supposed to be left
        // Only set the attributed text if it was changed during the process
        //----
        if (![textField.text isEqualToString:preEditString])
        {
            NSInteger offset = textField.text.length;
            NSMutableAttributedString* pseudoPlaceholder = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@%@", textField.text, [__placeholderText substringFromIndex:(__placeholderText.length-(__placeholderText.length-textField.text.length))]] attributes:nil];
            
            [pseudoPlaceholder addAttribute:NSForegroundColorAttributeName
                                      value:[UIColor colorWithWhite:.7843 alpha:1.0f]
                                      range:NSMakeRange(textField.text.length, pseudoPlaceholder.string.length - textField.text.length)];
            
            [textField setAttributedText:pseudoPlaceholder];
            [textField setSelectedTextRange:[textField textRangeFromPosition:[textField positionFromPosition:textField.beginningOfDocument offset:offset] toPosition:[textField positionFromPosition:textField.beginningOfDocument offset:offset]]];
        }
    }
    
    return NO;
}


@end
