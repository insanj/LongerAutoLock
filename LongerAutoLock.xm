#import "LongerAutoLock.h"

static HBPreferences *longerAutoLockPreferences;
static HBPreferences *getLongerAutoLockPreferences() {
	if (!longerAutoLockPreferences) {
		longerAutoLockPreferences = [[HBPreferences alloc] initWithIdentifier:kLongerAutoLockIdentifier];
	}

	return longerAutoLockPreferences;
}

%hook PSListController

- (void)viewWillAppear:(BOOL)animated {
	%orig();

	// Make sure the proper value text appears (such as when backing out from the Auto Lock pane)
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

	if ([self.navigationItem.title isEqualToString:GENERAL_TEXT]) {
		NSString *lastSelectedTitle = (NSString *)[getLongerAutoLockPreferences() objectForKey:kLongerAutoLockLastSelectedTitleIdentifier default:nil];

		// Set the detail text of the "Auto Lock" main cell (in General)
		if (lastSelectedTitle && [cell.title isEqualToString:AUTOLOCK_TEXT]) {
			cell.value = lastSelectedTitle;
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

		NSInteger lastSelectedRow = [getLongerAutoLockPreferences() integerForKey:kLongerAutoLockSelectedRowIdentifier default:-1];
		if (lastSelectedRow > -1 && lastSelectedRow < [[self table] numberOfRowsInSection:0]) {
			[self tableView:[self table] didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:lastSelectedRow inSection:0]];
		}
	}
}

/*                               _           _   _             
                                | |         | | (_)            
  ___  __ ___   _____   ___  ___| | ___  ___| |_ _  ___  _ __  
 / __|/ _` \ \ / / _ \ / __|/ _ \ |/ _ \/ __| __| |/ _ \| '_ \ 
 \__ \ (_| |\ V /  __/ \__ \  __/ |  __/ (__| |_| | (_) | | | |
 |___/\__,_| \_/ \___| |___/\___|_|\___|\___|\__|_|\___/|_| |_|
*/
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	%orig();

	if ([self.navigationItem.title isEqualToString:AUTOLOCK_TEXT]) {
		// Save the row every time a cell is selected, because once we set a value here it's trusted to ALWAYS be accurate (above)
		HBPreferences *preferences = getLongerAutoLockPreferences();
		[preferences setInteger:indexPath.row forKey:kLongerAutoLockSelectedRowIdentifier];
		[preferences setObject:[[((PSSpecifier *)[self itemsFromParent][indexPath.row+1]).shortTitleDictionary allValues] firstObject] forKey:kLongerAutoLockLastSelectedTitleIdentifier];
	}
}

%new - (void)longerautolock_addButtonTapped:(UIBarButtonItem *)sender {
	UIAlertView *optionsPrompt = [[UIAlertView alloc] initWithTitle:@"Longer Auto Lock" message:[LOCALIZE_NUM(@"How many") stringByAppendingString:@"?"] delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Done", nil];
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
	if ([self.navigationItem.title isEqualToString:AUTOLOCK_TEXT] && buttonIndex != [alertView cancelButtonIndex]) {
		NSString *durationText = [alertView textFieldAtIndex:0].text;
		NSNumber *duration = @([durationText intValue] * 60);

		if (!duration || [duration floatValue] <= 300) {
			[[[UIAlertView alloc] initWithTitle:[AUTOLOCK_TEXT stringByAppendingString:@" Duration Invalid"] message:[NSString stringWithFormat:@"The requested duration, %@, is invalid. Make sure your requests are new, minute-long durations, nothing more or less.", durationText] delegate:nil cancelButtonTitle:@"Dismiss" otherButtonTitles:nil] show];
			return;
		}

		HBPreferences *preferences = getLongerAutoLockPreferences();
		NSArray *savedDurations = [preferences objectForKey:kLongerAutoLockTimesIdentifier default:nil];

		if (!savedDurations || ![savedDurations isKindOfClass:[NSArray class]]) {
			savedDurations = @[duration];
		}

		else if ([savedDurations containsObject:duration]) {
			NSMutableArray *duplicateRemovingDurations = [savedDurations mutableCopy];
			[duplicateRemovingDurations removeObject:duration];
			savedDurations = [NSArray arrayWithArray:duplicateRemovingDurations];
		}

		else {
			savedDurations = [@[duration] arrayByAddingObjectsFromArray:savedDurations];
		}

		NSMutableArray *sortedDurations = [savedDurations mutableCopy];
		[sortedDurations sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"self" ascending:YES]]];
		[preferences setObject:sortedDurations forKey:kLongerAutoLockTimesIdentifier];

		[self longerautolock_reselectSpecifier];
	}
}

/*
  _   _                           _           _   
 | | (_)                         | |         | |  
 | |_ _ _ __ ___   ___   ___  ___| | ___  ___| |_ 
 | __| | '_ ` _ \ / _ \ / __|/ _ \ |/ _ \/ __| __|
 | |_| | | | | | |  __/ \__ \  __/ |  __/ (__| |_ 
  \__|_|_| |_| |_|\___| |___/\___|_|\___|\___|\__|
*/
%new - (void)longerautolock_reselectSpecifier {
	[self reloadSpecifiers];

	NSInteger lastSelectedRow = [getLongerAutoLockPreferences() integerForKey:kLongerAutoLockSelectedRowIdentifier default:-1];
	if (lastSelectedRow >= 0) {
		[self tableView:[self table] didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:lastSelectedRow inSection:0]];
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
- (id)itemsFromParent {
	NSArray *items = %orig();
	
	if ([self.navigationItem.title isEqualToString:AUTOLOCK_TEXT]) {
		NSArray *appendableItems = [items subarrayWithRange:NSMakeRange(0, items.count - 1)];
		NSArray *savedTimes = (NSArray *)[getLongerAutoLockPreferences() objectForKey:kLongerAutoLockTimesIdentifier default:nil];
		if (savedTimes) {
			PSSpecifier *firstRealSpecifier = items.count > 0 ? items[1] : nil;

			for (int i = 0; i < savedTimes.count; i++){
				NSNumber *savedTime = (NSNumber *)savedTimes[i];
				NSString *savedTimeName = LOCALIZE_NUM(@([savedTime integerValue] / 60.0));

				PSSpecifier *savedTimeSpecifier = [PSSpecifier preferenceSpecifierNamed:savedTimeName target:[firstRealSpecifier target] set:MSHookIvar<SEL>(firstRealSpecifier, "setter") get:MSHookIvar<SEL>(firstRealSpecifier, "getter") detail:[firstRealSpecifier detailControllerClass] cell:[firstRealSpecifier cellType] edit:[firstRealSpecifier editPaneClass]];
				[savedTimeSpecifier setValues:@[savedTime]];
				[savedTimeSpecifier setTitleDictionary:@{savedTime : savedTimeName}];
				[savedTimeSpecifier setShortTitleDictionary:@{savedTime : savedTimeName}];
				appendableItems = [appendableItems arrayByAddingObject:savedTimeSpecifier];
			}	
		}
	
		// last object being a funky group specifier
		return [appendableItems arrayByAddingObject:[items lastObject]];
	}

	return items;
}

%end
