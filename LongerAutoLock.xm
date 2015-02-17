#import "LongerAutoLock.h"

#define NSStringFromBool(a) a?@"are":@"aren't"

#define GENERAL_TEXT  [[NSBundle mainBundle] localizedStringForKey:@"General" value:@"General" table:@"General"]
#define AUTOLOCK_TEXT  [[NSBundle mainBundle] localizedStringForKey:@"AUTOLOCK" value:@"Auto-Lock" table:@"General"]
#define LOCALIZE_TEXT [[NSBundle mainBundle] localizedStringForKey:@"10_MINUTES" value:@"%@ Minutes" table:@"General"]

#define LOCALIZE(str) [NSString stringWithFormat:LOCALIZE_TEXT, str]

static NSString * kLongerAutoLockIdentifier = @"com.insanj.longerautolock";
static NSString * kLongerAutoLockTimesIdentifier = @"LongerAutoLock.Times", *kLongerAutoLockSelectedRowIdentifier = @"LongerAutoLock.Row", *kLongerAutoLockLastSelectedTitle = @"LongerAutoLock.Title";

static HBPreferences *longerAutoLockPreferences;

%hook PSListController

/*
                                  _  
                                 | | 
   __ _  ___ _ __   ___ _ __ __ _| | 
  / _` |/ _ \ '_ \ / _ \ '__/ _` | | 
 | (_| |  __/ | | |  __/ | | (_| | | 
  \__, |\___|_| |_|\___|_|  \__,_|_| 
   __/ |                             
  |___/                                                                    
*/
- (void)viewWillAppear:(BOOL)animated {
	%orig();

	// If we're in "General", make sure the specifiers are reloaded so the detail can be configured (cellForRow)
	if ([self.navigationItem.title isEqualToString:GENERAL_TEXT]) {
		[self reloadSpecifiers];
	}
}

/*      _                              _           _   _             
     | |                            | |         | | (_)            
  ___| |__   _____      __  ___  ___| | ___  ___| |_ _  ___  _ __  
 / __| '_ \ / _ \ \ /\ / / / __|/ _ \ |/ _ \/ __| __| |/ _ \| '_ \ 
 \__ \ | | | (_) \ V  V /  \__ \  __/ |  __/ (__| |_| | (_) | | | |
 |___/_| |_|\___/ \_/\_/   |___/\___|_|\___|\___|\__|_|\___/|_| |_|
*/                                                                                                                               
- (PSTableCell *)tableView:(UITableView *)arg1 cellForRowAtIndexPath:(NSIndexPath *)arg2 {
	PSTableCell *cell = %orig();

	// HBPreferences *preferencesConnection = [[HBPreferences alloc] initWithIdentifier:kLongerAutoLockIdentifier];
	// NSInteger lastSelectedRow = [longerAutoLockPreferences integerForKey:kLongerAutoLockSelectedRowIdentifier default:-1];
	// NSMutableArray *savedTimes = [preferencesConnection objectForKey:kLongerAutoLockTimesIdentifier];
	NSString *lastSelectedTitle = (NSString *)[longerAutoLockPreferences objectForKey:kLongerAutoLockLastSelectedTitle];

	// Set the detail text of the "Auto Lock" main cell (in General)
	if (lastSelectedTitle && [cell.title isEqualToString:AUTOLOCK_TEXT]) {
		for (UIView *subview in cell.contentView.subviews) {
			if ([subview isKindOfClass:[%c(UITableViewLabel) class]]) {
				[(UITableViewLabel *)subview setText:lastSelectedTitle];
// [NSNumberFormatter localizedStringFromNumber:(NSNumber *)savedTimes[lastSelectedRow] numberStyle:NSNumberFormatterDecimalStyle]
			}
		}
	}

	return cell;
}

%end

@interface PSListItemsController (LongerAutoLock) <UIAlertViewDelegate>

- (void)longerautolock_addButtonTapped:(UIBarButtonItem *)sender;
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex;
- (void)longerautolock_reselectSpecifier;

@end

%hook PSListItemsController

/*
              _          _            _    
             | |        | |          | |   
   __ _ _   _| |_ ___   | | ___   ___| | __
  / _` | | | | __/ _ \  | |/ _ \ / __| |/ /
 | (_| | |_| | || (_) | | | (_) | (__|   < 
  \__,_|\__,_|\__\___/  |_|\___/ \___|_|\_\                                        
*/                                  
- (void)viewWillAppear:(BOOL)animated {
	%orig();
	
	// If we're in the "Auto Lock" area, add the rightBarButtonItem and select the last-selected row
	if ([self.navigationItem.title isEqualToString:AUTOLOCK_TEXT]) {
		self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCompose target:self action:@selector(longerautolock_addButtonTapped:)];

		NSInteger lastSelectedRow = [longerAutoLockPreferences integerForKey:kLongerAutoLockSelectedRowIdentifier default:-1];
		if (lastSelectedRow >= 0) {
			[self tableView:[self table] didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:lastSelectedRow inSection:0]];
		}
	}
}

/*                                 _           _   _             
                                | |         | | (_)            
  ___  __ ___   _____   ___  ___| | ___  ___| |_ _  ___  _ __  
 / __|/ _` \ \ / / _ \ / __|/ _ \ |/ _ \/ __| __| |/ _ \| '_ \ 
 \__ \ (_| |\ V /  __/ \__ \  __/ |  __/ (__| |_| | (_) | | | |
 |___/\__,_| \_/ \___| |___/\___|_|\___|\___|\__|_|\___/|_| |_|
*/
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	// Save the row every time a cell is selected, because once we set a value here it's trusted to ALWAYS be accurate (above)
	[longerAutoLockPreferences setInteger:indexPath.row forKey:kLongerAutoLockSelectedRowIdentifier];
	%orig();
}

%new - (void)longerautolock_addButtonTapped:(UIBarButtonItem *)sender {
	UIAlertView *optionsPrompt = [[UIAlertView alloc] initWithTitle:@"Modify Auto-Lock Options" message:@"Enter your desired longer auto-lock duration in minutes to add it, or an already-existing duration to remove it, then tap Done." delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Done", nil];
	optionsPrompt.alertViewStyle = UIAlertViewStylePlainTextInput;

	UITextField *optionsPromptTextField = [optionsPrompt textFieldAtIndex:0];
    optionsPromptTextField.placeholder = @"e.g. 10, 15";
    optionsPromptTextField.keyboardType = UIKeyboardTypeNumberPad;

    [optionsPrompt show];
}

/*
            _     _   _   _                
           | |   | | | | (_)               
   __ _  __| | __| | | |_ _ _ __ ___   ___ 
  / _` |/ _` |/ _` | | __| | '_ ` _ \ / _ \
 | (_| | (_| | (_| | | |_| | | | | | |  __/
  \__,_|\__,_|\__,_|  \__|_|_| |_| |_|\___|
*/                                
%new - (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	if (buttonIndex != [alertView cancelButtonIndex]) {
		NSString *durationText = [alertView textFieldAtIndex:0].text;
		NSNumber *duration = @([durationText intValue] * 60);

		if (!duration || [duration floatValue] <= 300) {
			[[[UIAlertView alloc] initWithTitle:[AUTOLOCK_TEXT stringByAppendingString:@" Duration Invalid"] message:[NSString stringWithFormat:@"The requested duration, %@, is invalid. Make sure your requests are new, minute-long durations, nothing more or less.", durationText] delegate:nil cancelButtonTitle:@"Dismiss" otherButtonTitles:nil] show];
			return;
		}

		// HBPreferences *preferencesConnection = [[HBPreferences alloc] initWithIdentifier:kLongerAutoLockIdentifier];
		NSMutableArray *savedDurations = [longerAutoLockPreferences objectForKey:kLongerAutoLockTimesIdentifier];

		if (!savedDurations) {
			savedDurations = [NSMutableArray arrayWithArray:@[duration]];
			[longerAutoLockPreferences setObject:savedDurations forKey:kLongerAutoLockTimesIdentifier];
		}

		else {
			[savedDurations insertObject:duration atIndex:0];
			[longerAutoLockPreferences setObject:savedDurations forKey:kLongerAutoLockTimesIdentifier];
		}

		[longerAutoLockPreferences setInteger:([[self table] numberOfRowsInSection:0]+savedDurations.count-1) forKey:kLongerAutoLockSelectedRowIdentifier];
		[self longerautolock_reselectSpecifier];
	}
}

/*
  _       _           _     _   _                     
 (_)     (_)         | |   | | (_)                    
  _ _ __  _  ___  ___| |_  | |_ _ _ __ ___   ___  ___ 
 | | '_ \| |/ _ \/ __| __| | __| | '_ ` _ \ / _ \/ __|
 | | | | | |  __/ (__| |_  | |_| | | | | | |  __/\__ \
 |_|_| |_| |\___|\___|\__|  \__|_|_| |_| |_|\___||___/
        _/ |                                          
       |__/                                           
*/
- (NSArray *)itemsFromParent {
	NSArray *items = %orig();
	
	if ([self.navigationItem.title isEqualToString:AUTOLOCK_TEXT]) {
		NSMutableArray *mutableItems = [NSMutableArray arrayWithCapacity:items.count - 1];
		for(int i = 0; i < items.count - 1; i++) {
			[mutableItems addObject:items[i]];
		}

		NSMutableArray *savedTimes = (NSMutableArray *)[longerAutoLockPreferences objectForKey:kLongerAutoLockTimesIdentifier];
		if (savedTimes) {
			PSSpecifier *firstRealSpecifier = items.count > 0 ? items[1] : nil;

			for (int i = 0; i < savedTimes.count; i++){
				NSNumber *savedTime = (NSNumber *)savedTimes[i];
				NSString *savedTimeKey = [savedTime stringValue];

				PSSpecifier *savedTimeSpecifier = [PSSpecifier preferenceSpecifierNamed:savedTimeKey target:[firstRealSpecifier target] set:MSHookIvar<SEL>(firstRealSpecifier, "setter") get:MSHookIvar<SEL>(firstRealSpecifier, "getter") detail:[firstRealSpecifier detailControllerClass] cell:[firstRealSpecifier cellType] edit:[firstRealSpecifier editPaneClass]];
				[savedTimeSpecifier setValues:@[savedTime]];
				[savedTimeSpecifier setTitleDictionary:@{savedTime : savedTimeKey}];
				[savedTimeSpecifier setShortTitleDictionary:@{savedTime : savedTimeKey}];
				[mutableItems addObject:savedTimeSpecifier];
			}	
		}
	
		[mutableItems addObject:[items lastObject]]; // last object being a funky group specifier
		return [NSArray arrayWithArray:mutableItems];		
	}

	return items;
}

%new - (void)longerautolock_reselectSpecifier {
	[self reloadSpecifiers];

	NSInteger lastSelectedRow = [longerAutoLockPreferences integerForKey:kLongerAutoLockSelectedRowIdentifier default:-1];
	if (lastSelectedRow >= 0) {
		[self tableView:[self table] didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:lastSelectedRow inSection:0]];
	}
}

%end

%ctor {
	longerAutoLockPreferences = [[HBPreferences alloc] initWithIdentifier:kLongerAutoLockIdentifier];
}
