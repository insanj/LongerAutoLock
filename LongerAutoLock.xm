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
		NSNumber *duration = [NSNumber numberWithInt:[durationText intValue]];
		if(!duration || [duration intValue] < 300){
			[[[[UIAlertView alloc] initWithTitle:@"Auto-Lock Duration Invalud" message:[NSString stringWithFormat:@"The requested duration, %@, is invalid. Make sure your requests are just numbers of minutes, nothing more or less.", durationText] delegate:nil cancelButtonTitle:@"Dismiss" otherButtonTitles:nil] autorelease] show];
			return;
		}

		NSError *error;
		NSFileManager *fileManager = [NSFileManager defaultManager];
		NSDictionary *finalized;
		if(![fileManager fileExistsAtPath:LLPREFS_PATH]){
			[fileManager createDirectoryAtPath:LLPREFS_PATH withIntermediateDirectories:YES attributes:nil error:&error];
			NSDictionary *newPrefs = @{duration : [[duration stringValue] stringByAppendingString:@" Minutes"]};
			finalized = newPrefs;
		}

		else{
			NSDictionary *savedPrefs = [NSDictionary dictionaryWithContentsOfFile:LLPREFS_PLIST];
			NSMutableDictionary *newPrefs = [[NSMutableDictionary alloc] init];
			for(NSNumber *val in [savedPrefs allKeys])
				if(![newPrefs objectForKey:val])
					[newPrefs setObject:[savedPrefs objectForKey:val] forKey:val];
			
			[newPrefs setObject:[[duration stringValue] stringByAppendingString:@" Minutes"] forKey:duration];

			NSArray *sortedKeys = [[newPrefs allKeys] sortedArrayUsingSelector:@selector(compare:)];
			NSMutableArray *sortedValues = [[NSMutableArray alloc] init];
			for(NSString *key in sortedKeys)
			    [sortedValues addObject:[newPrefs objectForKey:key]];

			finalized = [NSDictionary dictionaryWithObjects:sortedValues forKeys:sortedKeys];
		}

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

-(PSListController *)initForContentSize:(CGSize)arg1{
	PSListController *list = %orig();
	NSLog(@"------- fff: %@", list.view);
	//	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(longerautolock_promptUserForSpecifier)];
	[[NSDistributedNotificationCenter defaultCenter] addObserver:list selector:@selector(longerautolock_addSpecifierForNotification:) name:@"LLAddSpecifier" object:nil];
	return list;
}

%new -(void)longerautolock_promptUserForSpecifier{
	lldelegate = [[LLAlertViewDelegate alloc] init];
	UIAlertView *llalertview = [[UIAlertView alloc] initWithTitle:@"Add Auto-Lock Duration" message:@"Enter your desired longer auto-lock duration in minutes, then tap Done" delegate:lldelegate cancelButtonTitle:@"Cancel" otherButtonTitles:@"Done", nil];
	[llalertview setAlertViewStyle:UIAlertViewStylePlainTextInput];
    [[llalertview textFieldAtIndex:0] setPlaceholder:@"10 Minutes"];
    [llalertview release];
}

%new -(void)longerautolock_addSpecifierForNotification:(NSNotification *)notification{
	NSDictionary *addSpecifiers = [notification userInfo];
	NSArray *specifiers = [self specifiers];
	NSMutableArray *titles = [[NSMutableArray alloc] init];
	for(PSSpecifier *s in specifiers)
		[titles addObject:s.name];

	if(specifiers.count < 2)
		return;

	PSSpecifier *example = (PSSpecifier *)specifiers[1];

	[self beginUpdates];
	for(NSNumber *val in [addSpecifiers allKeys]){
		if(![titles containsObject:[addSpecifiers objectForKey:val]]){
			PSSpecifier *newSpecifier = [PSSpecifier preferenceSpecifierNamed:[addSpecifiers objectForKey:val] target:[example target] set:MSHookIvar<SEL>(example, "setter") get:MSHookIvar<SEL>(example, "getter") detail:[example detailControllerClass] cell:[example cellType] edit:[example editPaneClass]];
			[newSpecifier setValues:@[val]];
			[newSpecifier setTitleDictionary:@{val : [addSpecifiers objectForKey:val]}];
			[newSpecifier setShortTitleDictionary:@{val : [addSpecifiers objectForKey:val]}];
			[newSpecifier setButtonAction:[example buttonAction]];
			[self addSpecifier:newSpecifier animated:YES];
		}
	}
	[self endUpdates];
}

-(void)dealloc{
	[[NSDistributedNotificationCenter defaultCenter] removeObserver:self];

	lldelegate = nil;
	[lldelegate release];
	%orig();
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
			for(NSNumber *val in [savedPrefs allKeys]){
				PSSpecifier *newSpecifier = [PSSpecifier preferenceSpecifierNamed:[savedPrefs objectForKey:val] target:[first target] set:MSHookIvar<SEL>(first, "setter") get:MSHookIvar<SEL>(first, "getter") detail:[first detailControllerClass] cell:[first cellType] edit:[first editPaneClass]];
				[newSpecifier setValues:@[val]];
				[newSpecifier setTitleDictionary:@{val : [savedPrefs objectForKey:val]}];
				[newSpecifier setShortTitleDictionary:@{val : [savedPrefs objectForKey:val]}];
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

/*

Original -itemsFromParent array:
	0: "G:  0x178365400",
   
    1: "1 Minute        ID:1 Minute 0x178365100        target:<GeneralController 0x147d40570: navItem <UINavigationItem: 0x1781c9ba0>, view <UITableView: 0x148075c00; frame = (0 0; 320 568); clipsToBounds = YES; autoresize = W+H; gestureRecognizers = <NSArray: 0x178242430>; layer = <CALayer: 0x178237320>; contentOffset: {0, 212}>>",

    2: "2 Minutes        ID:2 Minutes 0x1783654c0        target:<GeneralController 0x147d40570: navItem <UINavigationItem: 0x1781c9ba0>, view <UITableView: 0x148075c00; frame = (0 0; 320 568); clipsToBounds = YES; autoresize = W+H; gestureRecognizers = <NSArray: 0x178242430>; layer = <CALayer: 0x178237320>; contentOffset: {0, 212}>>",
	  
	3: "3 Minutes        ID:3 Minutes 0x178365580        target:<GeneralController 0x147d40570: navItem <UINavigationItem: 0x1781c9ba0>, view <UITableView: 0x148075c00; frame = (0 0; 320 568); clipsToBounds = YES; autoresize = W+H; gestureRecognizers = <NSArray: 0x178242430>; layer = <CALayer: 0x178237320>; contentOffset: {0, 212}>>",
	
	4: "4 Minutes        ID:4 Minutes 0x178365640        target:<GeneralController 0x147d40570: navItem <UINavigationItem: 0x1781c9ba0>, view <UITableView: 0x148075c00; frame = (0 0; 320 568); clipsToBounds = YES; autoresize = W+H; gestureRecognizers = <NSArray: 0x178242430>; layer = <CALayer: 0x178237320>; contentOffset: {0, 212}>>",
	
	5: "5 Minutes        ID:5 Minutes 0x178365700        target:<GeneralController 0x147d40570: navItem <UINavigationItem: 0x1781c9ba0>, view <UITableView: 0x148075c00; frame = (0 0; 320 568); clipsToBounds = YES; autoresize = W+H; gestureRecognizers = <NSArray: 0x178242430>; layer = <CALayer: 0x178237320>; contentOffset: {0, 212}>>",
	
	6: "Never        ID:Never 0x1783657c0        target:<GeneralController 0x147d40570: navItem <UINavigationItem: 0x1781c9ba0>, view <UITableView: 0x148075c00; frame = (0 0; 320 568); clipsToBounds = YES; autoresize = W+H; gestureRecognizers = <NSArray: 0x178242430>; layer = <CALayer: 0x178237320>; contentOffset: {0, 212}>>"

*/