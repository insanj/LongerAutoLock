#import "LongerAutoLock.h"
#define NSStringFromBool(a) a?@"are":@"aren't"

#define LLPREFS_PATH [NSHomeDirectory() stringByAppendingPathComponent:@"/Library/Application Support/LongerAutoLock"]
#define LLPREFS_PLIST [NSHomeDirectory() stringByAppendingPathComponent:@"/Library/Application Support/LongerAutoLock/SavedDurations.plist"]
#define LLLAST_PLIST [NSHomeDirectory() stringByAppendingPathComponent:@"/Library/Application Support/LongerAutoLock/LastSelected.plist"]
#define LLDEFAULT_TITLES @[[[NSBundle mainBundle] localizedStringForKey:@"1_MINUTES" value:@"1 Minute" table:@"General"], [[NSBundle mainBundle] localizedStringForKey:@"2_MINUTES" value:@"2 Minutes" table:@"General"], [[NSBundle mainBundle] localizedStringForKey:@"3_MINUTES" value:@"3 Minutes" table:@"General"], [[NSBundle mainBundle] localizedStringForKey:@"4_MINUTES" value:@"4 Minutes" table:@"General"], [[NSBundle mainBundle] localizedStringForKey:@"5_MINUTES" value:@"5 Minutes" table:@"General"], [[NSBundle mainBundle] localizedStringForKey:@"NEVER" value:@"Never" table:@"General"]]

#define LLGENERAL_TEXT  [[NSBundle mainBundle] localizedStringForKey:@"General" value:@"General" table:@"General"]
#define LLAUTOLOCK_TEXT  [[NSBundle mainBundle] localizedStringForKey:@"AUTOLOCK" value:@"Auto-Lock" table:@"General"]
#define LLLOCALIZE_TEXT [[NSBundle mainBundle] localizedStringForKey:@"10_MINUTES" value:@"%@ Minutes" table:@"General"]

#define LLLOCALIZE(str) [NSString stringWithFormat:LLLOCALIZE_TEXT, str]

@interface LLAlertViewDelegate : NSObject <UIAlertViewDelegate>
-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex;
@end

@implementation LLAlertViewDelegate
-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
	if(buttonIndex != 0){
		NSString *durationText = [alertView textFieldAtIndex:0].text;
		NSNumber *duration = [NSNumber numberWithInt:[durationText intValue] * 60];
		if(!duration || [duration intValue] <= 300){
			[[[UIAlertView alloc] initWithTitle:[LLAUTOLOCK_TEXT stringByAppendingString:@" Duration Invalid"] message:[NSString stringWithFormat:@"The requested duration, %@, is invalid. Make sure your requests are new, minute-long durations, nothing more or less.", durationText] delegate:nil cancelButtonTitle:@"Dismiss" otherButtonTitles:nil] show];
			return;
		}

		NSFileManager *fileManager = [NSFileManager defaultManager];
		NSDictionary *finalized;
		BOOL isDuplicate = NO;
		if(![fileManager fileExistsAtPath:LLPREFS_PLIST]){
			NSDictionary *newPrefs = @{[duration stringValue] : LLLOCALIZE(durationText)};
			finalized = newPrefs;
		}

		else{
			NSDictionary *savedPrefs = [NSDictionary dictionaryWithContentsOfFile:LLPREFS_PLIST];
			isDuplicate = [[savedPrefs allKeys] containsObject:[duration stringValue]];
			NSMutableDictionary *newPrefs = [[NSMutableDictionary alloc] init];

			for(NSString *key in [savedPrefs allKeys])
				if(![key isEqualToString:[duration stringValue]] && ![newPrefs objectForKey:key])
					[newPrefs setObject:[savedPrefs objectForKey:key] forKey:key];
			
			if(!isDuplicate)
				[newPrefs setObject:LLLOCALIZE(durationText) forKey:[duration stringValue]];

			finalized = newPrefs;
		}

		NSLog(@"[LongerAutoLock]: Wrote the augmented specifier plist (%@) to file %@.", finalized, LLPREFS_PLIST);
		[finalized writeToFile:LLPREFS_PLIST atomically:YES];
		[[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"LLAddSpecifier" object:nil userInfo:@{@"LLTitle" : LLLOCALIZE(durationText)}];

		if(isDuplicate && alertView.tag == [durationText intValue])
			[[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"LLReselectSpecifier" object:nil];
	}
}
@end

@interface PSListController (LongerAutoLock)
-(void)longerautolock_promptUserForSpecifier;
-(void)longerautolock_addSpecifierForNotification:(NSNotification *)notification;
-(void)longerautolock_reselectSpecifier;
@end

%hook PSListController
static LLAlertViewDelegate *lldelegate;

-(void)viewWillAppear:(BOOL)animated{
	%orig();

	if([self.navigationItem.title isEqualToString:LLGENERAL_TEXT])
		[self reloadSpecifiers];

	if([self.navigationItem.title isEqualToString:LLAUTOLOCK_TEXT]){
		self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCompose target:self action:@selector(longerautolock_promptUserForSpecifier)];
		[[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(longerautolock_addSpecifierForNotification:) name:@"LLAddSpecifier" object:nil];
		[[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(longerautolock_reselectSpecifier) name:@"LLReselectSpecifier" object:nil];

		NSError *error;
		NSFileManager *fileManager = [NSFileManager defaultManager];
		if(![fileManager fileExistsAtPath:LLPREFS_PATH])
			[fileManager createDirectoryAtPath:LLPREFS_PATH withIntermediateDirectories:YES attributes:nil error:&error];

		else{
			NSDictionary *savedPrefs = [NSDictionary dictionaryWithContentsOfFile:LLLAST_PLIST];
			[self tableView:[self table] didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:[savedPrefs[@"LLLastIndexPath"] intValue] inSection:0]];
		}
	}//end if
}

-(PSTableCell *)tableView:(UITableView *)arg1 cellForRowAtIndexPath:(NSIndexPath *)arg2{
	PSTableCell *cell = %orig();
	if([cell.title isEqualToString:LLAUTOLOCK_TEXT] && [NSDictionary dictionaryWithContentsOfFile:LLLAST_PLIST] != nil)
		for(UIView *subview in cell.contentView.subviews)
			if([subview isKindOfClass:[%c(UITableViewLabel) class]])
				[(UITableViewLabel *)subview setText:[NSDictionary dictionaryWithContentsOfFile:LLLAST_PLIST][@"LLLastText"]];

	return cell;
}

-(void)viewWillDisappear:(BOOL)animated{
	if([self.navigationItem.title isEqualToString:LLAUTOLOCK_TEXT]){
		[[NSDistributedNotificationCenter defaultCenter] removeObserver:self];

		for(int i = 0; i < [[self table] numberOfRowsInSection:0]; i++){
			PSTableCell *cell = (PSTableCell *)[[self table] cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
			if(cell.accessoryType == UITableViewCellAccessoryCheckmark){
				[@{@"LLLastIndexPath" : @(i), @"LLLastText" : cell.title} writeToFile:LLLAST_PLIST atomically:YES];
				break;
			}
		}
	}//end if

	%orig();
}

%new -(void)longerautolock_promptUserForSpecifier{
	NSLog(@"[LongerAutoLock]: Prompting user for additional specifier creation.");

	lldelegate = [[LLAlertViewDelegate alloc] init];
	UIAlertView *llalertview = [[UIAlertView alloc] initWithTitle:@"Modify Auto-Lock Options" message:@"Enter your desired longer auto-lock duration in minutes to add it, or an already-existing duration to remove it, then tap Done." delegate:lldelegate cancelButtonTitle:@"Cancel" otherButtonTitles:@"Done", nil];
	[llalertview setAlertViewStyle:UIAlertViewStylePlainTextInput];
    [[llalertview textFieldAtIndex:0] setPlaceholder:@"e.g. 10, 15"];
    [[llalertview textFieldAtIndex:0] setKeyboardType:UIKeyboardTypeNumberPad];

    for(int i = 0; i < [[self table] numberOfRowsInSection:0]; i++){
    	PSTableCell *cell = (PSTableCell *)[[self table] cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
    	if(cell.accessoryType == UITableViewCellAccessoryCheckmark)
    		llalertview.tag = [[[cell title] componentsSeparatedByString:@" "][0] intValue];
    }

    [llalertview show];
}

%new -(void)longerautolock_addSpecifierForNotification:(NSNotification *)notification{
	NSLog(@"[LongerAutoLock]: Refreshing tableView (%@) for given specifier title: %@", [self table], [notification userInfo][@"LLTitle"]);
	[self reloadSpecifiers];

   for(int i = 0; i < [[self table] numberOfRowsInSection:0]; i++){
    	PSTableCell *cell = (PSTableCell *)[[self table] cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
    	if([[cell title] isEqualToString:[notification userInfo][@"LLTitle"]]){
			[self tableView:[self table] didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
			return;
    	}
   }
}

%new -(void)longerautolock_reselectSpecifier{
	[self tableView:[self table] didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
}

%end

@interface PSListItemsController (LongerAutoLock)
-(void)longerautolock_addFooterToView;
@end

%hook PSListItemsController
static UILabel *llfooterLabel;
static LLAlertViewDelegate *lldeleteDelegate;
static BOOL lladdedHeavyLine;

-(void)viewWillAppear:(BOOL)arg1{
	lladdedHeavyLine = NO;
	%orig();

	if([self.navigationItem.title isEqualToString:LLAUTOLOCK_TEXT])
		[self longerautolock_addFooterToView];
}

-(void)reloadSpecifiers{
	lladdedHeavyLine = NO;
	%orig();

	if([self.navigationItem.title isEqualToString:LLAUTOLOCK_TEXT])
		[self longerautolock_addFooterToView];
}

-(id)tableView:(id)arg1 cellForRowAtIndexPath:(id)arg2{
	PSTableCell *cell = (PSTableCell *)%orig();

	int minutes = [[[cell title] componentsSeparatedByString:@" "][0] intValue];
	if([self.navigationItem.title isEqualToString:LLAUTOLOCK_TEXT] && minutes > 5 && !lladdedHeavyLine){
		lladdedHeavyLine = YES;
		
		UIView *heavyLine = [[UIView alloc] initWithFrame:CGRectMake(15.0, 0.0, arg1.frame.size.width - 15.0, 2.0)];
		[heavyLine setBackgroundColor:[UIColor lightGrayColor]];
        [cell.contentView addSubview:heavyLine];
	}

	return cell;
}

%new -(void)longerautolock_addFooterToView{
	if(llfooterLabel){
		[llfooterLabel removeFromSuperview];
		llfooterLabel = nil;
	}

	NSString *footerText = @"Shorter Auto-Lock times are more secure. Using a custom LongerAutoLock time forfeits possible privacy and battery life for convenience. Please use responsibly.";
	CGSize footerSize = [footerText boundingRectWithSize:CGSizeMake(self.view.superview.frame.size.width - 20.0, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName : [UIFont systemFontOfSize:13.0]} context:nil].size;
		
    llfooterLabel = [[UILabel alloc] initWithFrame:CGRectMake(10.0, [[self table] rectForSection:0].size.height + 25.0, footerSize.width, footerSize.height)];
	llfooterLabel.numberOfLines = 0;
	[llfooterLabel setUserInteractionEnabled:NO];
	[llfooterLabel setBackgroundColor:[UIColor clearColor]];
	[llfooterLabel setText:footerText];
	[llfooterLabel setFont:[UIFont systemFontOfSize:13.0]];
	[llfooterLabel setTextColor:[UIColor darkGrayColor]];
	[self.view addSubview:llfooterLabel];
}	

-(id)itemsFromParent{
	NSArray *items = %orig();
	NSLog(@"[LongerAutoLock] Received call to -itemsFromParent, appears we %@ in Auto-Lock pane (%@)", NSStringFromBool([self.navigationItem.title isEqualToString:LLAUTOLOCK_TEXT]), self);
	
	if([self.navigationItem.title isEqualToString:LLAUTOLOCK_TEXT]){
		PSSpecifier *first = items.count > 0?items[1]:nil;
		NSMutableArray *additional = [[NSMutableArray alloc] init];
		for(int i = 0; i < items.count - 1; i++)
			[additional addObject:items[i]];

		NSDictionary *savedPrefs = [NSDictionary dictionaryWithContentsOfFile:LLPREFS_PLIST];

		if(savedPrefs){
			for(int i = [savedPrefs allKeys].count - 1; i >= 0; i--){
				NSString *key = [[savedPrefs allKeys] objectAtIndex:i];
				NSNumber *val = [NSNumber numberWithInt:[key intValue]];
				NSString *name = [savedPrefs objectForKey:key];

				PSSpecifier *newSpecifier = [PSSpecifier preferenceSpecifierNamed:name target:[first target] set:MSHookIvar<SEL>(first, "setter") get:MSHookIvar<SEL>(first, "getter") detail:[first detailControllerClass] cell:[first cellType] edit:[first editPaneClass]];
				[newSpecifier setValues:@[val]];
				[newSpecifier setTitleDictionary:@{val : name}];
				[newSpecifier setShortTitleDictionary:@{val : name}];

				NSLog(@"[LongerAutoLock] Modifying requested specifier with name:%@ and value:%@, raw:%@", name, val, newSpecifier);
				[additional addObject:newSpecifier];
			}	
		}
	
		[additional addObject:[items lastObject]];
		items = [[NSArray alloc] initWithArray:additional];
		
		NSLog(@"[LongerAutoLock] Finished augmenting specifiers (%@) to create: %@", savedPrefs, items);
	}

	return items;
}

%end
