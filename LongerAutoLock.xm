#import "LongerAutoLock.h"
#define LLPREFS_PATH [NSHomeDirectory() stringByAppendingPathComponent:@"/Library/Application Support/LongerAutoLock"]
#define LLPREFS_PLIST [NSHomeDirectory() stringByAppendingPathComponent:@"/Library/Application Support/LongerAutoLock/Preferences.plist"]

@interface LLAlertViewDelegate : NSObject <UIAlertViewDelegate>
-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex;
@end

@implementation LLAlertViewDelegate
-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
	if(buttonIndex != 0){
		NSString *durationText = [alertView textFieldAtIndex:0].text;
		NSNumber *duration = [NSNumber numberWithInt:[durationText intValue] * 60];
		if(!duration || [duration intValue] <= 300){
			[[[UIAlertView alloc] initWithTitle:@"Auto-Lock Duration Invalud" message:[NSString stringWithFormat:@"The requested duration, %@, is invalid. Make sure your requests are just numbers of minutes, nothing more or less.", durationText] delegate:nil cancelButtonTitle:@"Dismiss" otherButtonTitles:nil] show];
			return;
		}

		NSError *error;
		NSFileManager *fileManager = [NSFileManager defaultManager];
		NSDictionary *finalized;
		if(![fileManager fileExistsAtPath:LLPREFS_PATH]){
			[fileManager createDirectoryAtPath:LLPREFS_PATH withIntermediateDirectories:YES attributes:nil error:&error];
			NSDictionary *newPrefs = @{durationText : [durationText stringByAppendingString:@" Minutes"]};
			finalized = newPrefs;
		}

		else{
			NSDictionary *savedPrefs = [NSDictionary dictionaryWithContentsOfFile:LLPREFS_PLIST];
			NSMutableDictionary *newPrefs = [[NSMutableDictionary alloc] init];
			for(NSString *key in [savedPrefs allKeys])
				if(![newPrefs objectForKey:key])
					[newPrefs setObject:[savedPrefs objectForKey:key] forKey:key];
			
			[newPrefs setObject:[durationText stringByAppendingString:@" Minutes"] forKey:durationText];

			NSArray *sortedKeys = [[newPrefs allKeys] sortedArrayUsingSelector:@selector(compare:)];
			NSMutableArray *sortedValues = [[NSMutableArray alloc] init];
			for(NSString *key in sortedKeys)
			    [sortedValues addObject:[newPrefs objectForKey:key]];

			finalized = [NSDictionary dictionaryWithObjects:sortedValues forKeys:sortedKeys];
		}

		NSLog(@"[LongerAutoLock]: Wrote the additional specifier plist (%@) to file %@.", finalized, LLPREFS_PLIST);
		[finalized writeToFile:LLPREFS_PLIST atomically:YES];
		[[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"LLAddSpecifier" object:nil userInfo:finalized];
	}
}
@end

@interface PSListController (LongerAutoLock)
-(void)longerautolock_promptUserForSpecifier;
-(void)longerautolock_addSpecifierForNotification:(NSNotification *)notification;
@end

%hook PSListController
static LLAlertViewDelegate *lldelegate;

-(void)viewWillAppear:(BOOL)animated{
	%orig();

	if([self.navigationItem.title isEqualToString:@"Auto-Lock"]){
		self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(longerautolock_promptUserForSpecifier)];
		[[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(longerautolock_addSpecifierForNotification:) name:@"LLAddSpecifier" object:nil];
	}
}

-(void)viewWillDisappear:(BOOL)animated{
	[[NSDistributedNotificationCenter defaultCenter] removeObserver:self];
}

%new -(void)longerautolock_promptUserForSpecifier{
	NSLog(@"[LongerAutoLock]: Prompting user for additional specifier creation.");

	lldelegate = [[LLAlertViewDelegate alloc] init];
	UIAlertView *llalertview = [[UIAlertView alloc] initWithTitle:@"Add Auto-Lock Duration" message:@"Enter your desired longer auto-lock duration in minutes, then tap Done" delegate:lldelegate cancelButtonTitle:@"Cancel" otherButtonTitles:@"Done", nil];
	[llalertview setAlertViewStyle:UIAlertViewStylePlainTextInput];
    [[llalertview textFieldAtIndex:0] setPlaceholder:@"10 Minutes"];
    [llalertview show];
}

%new -(void)longerautolock_addSpecifierForNotification:(NSNotification *)notification{

	NSLog(@"[LongerAutoLock]: Refreshing tableView (%@) for additional specifiers (%@)", [self table], [notification userInfo]);
	[[self table] reloadData];
	[self reloadSpecifiers];
/*
	NSDictionary *addSpecifiers = [notification userInfo];
	NSArray *specifiers = [self specifiers];
	NSMutableArray *titles = [[NSMutableArray alloc] init];
	for(PSSpecifier *s in specifiers)
		[titles addObject:s.name];

	if(specifiers.count < 2)
		return;

	PSSpecifier *example = (PSSpecifier *)specifiers[1];

	[self beginUpdates];
	for(NSString *key in [addSpecifiers allKeys]){
		if(![titles containsObject:[addSpecifiers objectForKey:key]]){
			NSNumber *val = [NSNumber numberWithInt:[key intValue]];
			PSSpecifier *newSpecifier = [PSSpecifier preferenceSpecifierNamed:[addSpecifiers objectForKey:val] target:[example target] set:MSHookIvar<SEL>(example, "setter") get:MSHookIvar<SEL>(example, "getter") detail:[example detailControllerClass] cell:[example cellType] edit:[example editPaneClass]];
			[newSpecifier setValues:@[val]];
			[newSpecifier setTitleDictionary:@{val : [addSpecifiers objectForKey:val]}];
			[newSpecifier setShortTitleDictionary:@{val : [addSpecifiers objectForKey:val]}];
			[newSpecifier setButtonAction:[example buttonAction]];
			[self addSpecifier:newSpecifier animated:YES];
		}
	}
	[self endUpdates];

	NSLog(@"[LongerAutoLock]: Prompting user for additional specifier creation.");*/
}

%end

%hook PSListItemsController

-(id)itemsFromParent{
	NSArray *items = %orig();
	PSSpecifier *first = items.count > 0?items[1]:nil;
	BOOL inAutoLock = first && [first.name isEqualToString:@"1 Minute"];

	NSLog(@"[LongerAutoLock] Received call to -itemsFromParent, appears we %@ in Auto-Lock pane (%@)", NSStringFromBool(inAutoLock), self);
	
	if(inAutoLock){
		NSMutableArray *additional = [[NSMutableArray alloc] init];
		for(int i = 0; i < items.count - 1; i++)
			[additional addObject:items[i]];

		// Has to be greater than 1 Minute (value <60 doesn't seem to apply)
		/* PSSpecifier *tenMinutes = [PSSpecifier preferenceSpecifierNamed:@"10 Minutes" target:[first target] set:MSHookIvar<SEL>(first, "setter") get:MSHookIvar<SEL>(first, "getter") detail:[first detailControllerClass] cell:[first cellType] edit:[first editPaneClass]];
		[tenMinutes setValues:@[@600]];
		[tenMinutes setTitleDictionary:@{@600 : @"10 Minutes"}];
		[tenMinutes setShortTitleDictionary:@{@600 : @"10 Minutes"}];
		[tenMinutes setButtonAction:[first buttonAction]];
		[additional addObject:tenMinutes];

		[additional addObject:[items lastObject]]; */

		NSDictionary *savedPrefs = [NSDictionary dictionaryWithContentsOfFile:LLPREFS_PLIST];

		if(savedPrefs){
			for(NSString *key in [savedPrefs allKeys]){
				NSNumber *val = [NSNumber numberWithInt:[key intValue]];
				NSString *name = [savedPrefs objectForKey:key];

				PSSpecifier *newSpecifier = [PSSpecifier preferenceSpecifierNamed:name target:[first target] set:MSHookIvar<SEL>(first, "setter") get:MSHookIvar<SEL>(first, "getter") detail:[first detailControllerClass] cell:[first cellType] edit:[first editPaneClass]];
				[newSpecifier setValues:@[val]];
				[newSpecifier setTitleDictionary:@{val : name}];
				[newSpecifier setShortTitleDictionary:@{val : name}];
				[newSpecifier setButtonAction:[first buttonAction]];
				[additional addObject:newSpecifier];
			}	
		}
	
		[additional addObject:[items lastObject]];
		items = [[NSArray alloc] initWithArray:additional];
		
		NSLog(@"[LongerAutoLock] Inserted additional specifiers (%@) to create: %@", savedPrefs, items);
	}

	return items;
}

%end