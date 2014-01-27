#import <UIKit/UIKit.h>
#define NSStringFromBool(a) a?@"are":@"aren't"

@interface PSViewController : UIViewController
@end

@interface PSListController : PSViewController <UITableViewDelegate, UITableViewDataSource>{
    NSMutableDictionary *_cells;
    UITableView *_table;
    NSArray *_specifiers;
    NSMutableDictionary *_specifiersByID;
}

-(PSListController *)initForContentSize:(CGSize)arg1;
-(void)setSpecifiers:(NSArray *)arg1;
-(id)specifierAtIndex:(int)arg1;
-(UITableView *)table;
-(NSArray *)specifiers;
-(UITableViewCell *)tableView:(UITableView *)arg1 cellForRowAtIndexPath:(NSIndexPath *)arg2;
-(int)tableView:(UITableView *)arg1 numberOfRowsInSection:(int)arg2;
@end

@interface PSListItemsController : PSListController
-(id)itemsFromDataSource;
-(id)itemsFromParent;
@end

@interface PSSpecifier : NSObject {
	SEL getter;
	SEL setter;
	NSMutableDictionary *_properties;
}

@property(retain) NSString *name;
@property(retain) NSString *identifier;
@property(retain) NSArray *values;

+(PSSpecifier *)preferenceSpecifierNamed:(NSString *)arg1 target:(id)arg2 set:(SEL)arg3 get:(SEL)arg4 detail:(Class)arg5 cell:(int)arg6 edit:(Class)arg7;
-(PSSpecifier *)init;

-(void)setName:(NSString *)arg1;
-(void)setIdentifier:(NSString *)arg1;
-(void)setValues:(NSArray *)arg1;
-(void)setProperties:(NSMutableDictionary *)arg1;
-(void)setTarget:(id)arg1;
-(void)setCellType:(int)arg1;
-(void)setDetailControllerClass:(Class)arg1;
-(void)setEditPaneClass:(Class)arg1;
-(void)setUserInfo:(id)arg1;
-(void)setShortTitleDictionary:(id)arg1;
-(void)setTitleDictionary:(id)arg1;

-(NSString *)name;
-(NSString *)identifier;
-(NSArray *)values;
-(NSMutableDictionary *)properties;
-(id)target;
-(int)cellType;
-(Class)detailControllerClass;
-(Class)editPaneClass;
-(id)userInfo;
-(NSDictionary *)titleDictionary;
-(NSDictionary *)shortTitleDictionary;
@end

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

		PSSpecifier *ten = [PSSpecifier preferenceSpecifierNamed:@"10 Minutes" target:[first target] set:MSHookIvar<SEL>(first, "setter") get:MSHookIvar<SEL>(first, "getter") detail:[first detailControllerClass] cell:[first cellType] edit:[first editPaneClass]];
		[ten setValues:@[@600]];
		[ten setTitleDictionary:@{@60 : @"10 Minutes"}];
		[ten setShortTitleDictionary:@{@60 : @"10 Minutes"}];
		[additional addObject:ten];

		[additional addObject:[items lastObject]];
		items = [[NSArray alloc] initWithArray:additional];
		
		NSLog(@"[LongerAutoLock] Inserted additional specifier (%@) to create: %@", ten, items);
	}

	return items;
}

%end


/*

Original -itemsFromParent array:
	0: "G:  0x178365400",
   
    1: "1 Minute\t\tID:1 Minute 0x178365100\t\ttarget:<GeneralController 0x147d40570: navItem <UINavigationItem: 0x1781c9ba0>, view <UITableView: 0x148075c00; frame = (0 0; 320 568); clipsToBounds = YES; autoresize = W+H; gestureRecognizers = <NSArray: 0x178242430>; layer = <CALayer: 0x178237320>; contentOffset: {0, 212}>>",

    2: "2 Minutes\t\tID:2 Minutes 0x1783654c0\t\ttarget:<GeneralController 0x147d40570: navItem <UINavigationItem: 0x1781c9ba0>, view <UITableView: 0x148075c00; frame = (0 0; 320 568); clipsToBounds = YES; autoresize = W+H; gestureRecognizers = <NSArray: 0x178242430>; layer = <CALayer: 0x178237320>; contentOffset: {0, 212}>>",
	  
	3: "3 Minutes\t\tID:3 Minutes 0x178365580\t\ttarget:<GeneralController 0x147d40570: navItem <UINavigationItem: 0x1781c9ba0>, view <UITableView: 0x148075c00; frame = (0 0; 320 568); clipsToBounds = YES; autoresize = W+H; gestureRecognizers = <NSArray: 0x178242430>; layer = <CALayer: 0x178237320>; contentOffset: {0, 212}>>",
	
	4: "4 Minutes\t\tID:4 Minutes 0x178365640\t\ttarget:<GeneralController 0x147d40570: navItem <UINavigationItem: 0x1781c9ba0>, view <UITableView: 0x148075c00; frame = (0 0; 320 568); clipsToBounds = YES; autoresize = W+H; gestureRecognizers = <NSArray: 0x178242430>; layer = <CALayer: 0x178237320>; contentOffset: {0, 212}>>",
	
	5: "5 Minutes\t\tID:5 Minutes 0x178365700\t\ttarget:<GeneralController 0x147d40570: navItem <UINavigationItem: 0x1781c9ba0>, view <UITableView: 0x148075c00; frame = (0 0; 320 568); clipsToBounds = YES; autoresize = W+H; gestureRecognizers = <NSArray: 0x178242430>; layer = <CALayer: 0x178237320>; contentOffset: {0, 212}>>",
	
	6: "Never\t\tID:Never 0x1783657c0\t\ttarget:<GeneralController 0x147d40570: navItem <UINavigationItem: 0x1781c9ba0>, view <UITableView: 0x148075c00; frame = (0 0; 320 568); clipsToBounds = YES; autoresize = W+H; gestureRecognizers = <NSArray: 0x178242430>; layer = <CALayer: 0x178237320>; contentOffset: {0, 212}>>"
*/
