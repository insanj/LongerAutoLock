#import "LongerAutoLock.h"
#define NSStringFromBool(a) a?@"are":@"aren't"
#define LLPREFS_PATH [NSHomeDirectory() stringByAppendingPathComponent:@"/Library/Application Support/LongerAutoLock"]
#define LLPREFS_PLIST [NSHomeDirectory() stringByAppendingPathComponent:@"/Library/Application Support/LongerAutoLock/Preferences.plist"]
#define LLDEFAULT_TITLES @[@"1 Minute", @"2 Minutes", @"3 Minutes", @"4 Minutes", @"5 Minutes", @"Never"]

@interface LLAlertViewDelegate : NSObject <UIAlertViewDelegate>
-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex;
@end

@implementation LLAlertViewDelegate
-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
	if(buttonIndex != 0){
		NSString *durationText = [alertView textFieldAtIndex:0].text;
		NSNumber *duration = [NSNumber numberWithInt:[durationText intValue] * 60];
		if(!duration || [duration intValue] <= 300){
			[[[UIAlertView alloc] initWithTitle:@"Auto-Lock Duration Invalud" message:[NSString stringWithFormat:@"The requested duration, %@, is invalid. Make sure your requests are new, minute-long durations, nothing more or less.", durationText] delegate:nil cancelButtonTitle:@"Dismiss" otherButtonTitles:nil] show];
			return;
		}

		NSError *error;
		NSFileManager *fileManager = [NSFileManager defaultManager];
		NSDictionary *finalized;
		BOOL isDuplicate = NO;
		if(![fileManager fileExistsAtPath:LLPREFS_PATH]){
			[fileManager createDirectoryAtPath:LLPREFS_PATH withIntermediateDirectories:YES attributes:nil error:&error];
			NSDictionary *newPrefs = @{[duration stringValue] : [durationText stringByAppendingString:@" Minutes"]};
			finalized = newPrefs;
		}

		else{
			NSDictionary *savedPrefs = [NSDictionary dictionaryWithContentsOfFile:LLPREFS_PLIST];
			isDuplicate = [[savedPrefs allKeys] containsObject:[duration stringValue]];
			NSMutableDictionary *newPrefs = [[NSMutableDictionary alloc] init];

			for(NSString *key in [savedPrefs allKeys])
				if(![key isEqualToString:[duration stringValue]] && ![newPrefs objectForKey:key])
					[newPrefs setObject:[savedPrefs objectForKey:key] forKey:[NSNumber numberWithInt:[key intValue]]];
			
			if(!isDuplicate)
				[newPrefs setObject:[durationText stringByAppendingString:@" Minutes"] forKey:duration];

			NSArray *sortedKeys = [[newPrefs allKeys] sortedArrayUsingSelector:@selector(compare:)];
			NSMutableArray *sortedValues = [[NSMutableArray alloc] init];
			for(NSNumber *key in sortedKeys)
			    [sortedValues addObject:[newPrefs objectForKey:key]];

			NSMutableArray *sortedStringKeys = [[NSMutableArray alloc] init];
			for(int i = 0; i < sortedKeys.count; i++)
				[sortedStringKeys addObject:[sortedKeys[i] stringValue]];

			finalized = [NSDictionary dictionaryWithObjects:sortedValues forKeys:sortedStringKeys];
		}

		NSLog(@"[LongerAutoLock]: Wrote the augmented specifier plist (%@) to file %@.", finalized, LLPREFS_PLIST);
		[finalized writeToFile:LLPREFS_PLIST atomically:YES];
		[[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"LLAddSpecifier" object:nil userInfo:finalized];

		if(isDuplicate)
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

	if([self.navigationItem.title isEqualToString:@"Auto-Lock"]){
		self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCompose target:self action:@selector(longerautolock_promptUserForSpecifier)];
		[[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(longerautolock_addSpecifierForNotification:) name:@"LLAddSpecifier" object:nil];
		[[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(longerautolock_reselectSpecifier) name:@"LLReselectSpecifier" object:nil];
	}
}

-(void)viewWillDisappear:(BOOL)animated{
	[[NSDistributedNotificationCenter defaultCenter] removeObserver:self];
}

%new -(void)longerautolock_promptUserForSpecifier{
	NSLog(@"[LongerAutoLock]: Prompting user for additional specifier creation.");

	lldelegate = [[LLAlertViewDelegate alloc] init];
	UIAlertView *llalertview = [[UIAlertView alloc] initWithTitle:@"Modify Auto-Lock Options" message:@"Enter your desired longer auto-lock duration in minutes to add it, or an already-existing duration to remove it, then tap Done." delegate:lldelegate cancelButtonTitle:@"Cancel" otherButtonTitles:@"Done", nil];
	[llalertview setAlertViewStyle:UIAlertViewStylePlainTextInput];
    [[llalertview textFieldAtIndex:0] setPlaceholder:@"e.g. 6, 8, 10"];
    [[llalertview textFieldAtIndex:0] setKeyboardType:UIKeyboardTypeNumberPad];
    llalertview.tag = 0;
    [llalertview show];
}

%new -(void)longerautolock_addSpecifierForNotification:(NSNotification *)notification{
	NSLog(@"[LongerAutoLock]: Refreshing tableView (%@) for additional specifiers (%@)", [self table], [notification userInfo]);
	[self reloadSpecifiers];
}

%new -(void)longerautolock_reselectSpecifier{
	[self tableView:[self table] didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
	//[self selectRowForSpecifier:[[self specifiers] objectAtIndex:1]];
}

%end

@interface PSListItemsController (LongerAutoLock)
-(void)longerautolock_addFooterToView;
@end

%hook PSListItemsController
static UILabel *llfooterLabel;
static LLAlertViewDelegate *lldeleteDelegate;

-(void)viewWillAppear:(BOOL)arg1{
	%orig();

	if([self.navigationItem.title isEqualToString:@"Auto-Lock"])
		[self longerautolock_addFooterToView];
}

-(void)reloadSpecifiers{
	%orig();

	if([self.navigationItem.title isEqualToString:@"Auto-Lock"])
		[self longerautolock_addFooterToView];
}

%new -(void)longerautolock_addFooterToView{
	if(llfooterLabel){
		[llfooterLabel removeFromSuperview];
		llfooterLabel = nil;
	}

	NSString *footerText = @"Shorter Auto-Lock times are more secure. Using a custom LongerAutoLock time forfeits possible privacy and battery life for convenience. Please use responsibly.";
	CGSize footerSize = [footerText boundingRectWithSize:CGSizeMake([UIApplication sharedApplication].keyWindow.frame.size.width - 40.0, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName : [UIFont systemFontOfSize:13.0]} context:nil].size;
		
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
	PSSpecifier *first = items.count > 0?items[1]:nil;
	BOOL inAutoLock = first && [first.name isEqualToString:@"1 Minute"];

	NSLog(@"[LongerAutoLock] Received call to -itemsFromParent, appears we %@ in Auto-Lock pane (%@)", NSStringFromBool(inAutoLock), self);
	
	if(inAutoLock){
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