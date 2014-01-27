#import <UIKit/UIKit.h>
#define NSStringFromBool(a) a?@"are":@"aren't"

@interface NSDistributedNotificationCenter : NSNotificationCenter
@end

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
-(void)addSpecifier:(id)arg1;
-(void)addSpecifier:(id)arg1 animated:(BOOL)arg2;
-(UITableViewCell *)tableView:(UITableView *)arg1 cellForRowAtIndexPath:(NSIndexPath *)arg2;
-(int)tableView:(UITableView *)arg1 numberOfRowsInSection:(int)arg2;
-(void)endUpdates;
-(void)beginUpdates;
-(void)reloadSpecifiers;
@end

@interface PSListItemsController : PSListController
- (id)tableView:(id)arg1 cellForRowAtIndexPath:(id)arg2;
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
-(void)setButtonAction:(SEL)arg1;

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
-(SEL)buttonAction;
@end

@interface PSTableCell : UITableViewCell
@property(retain) PSSpecifier *specifier;
@property(retain) UILongPressGestureRecognizer *longTapRecognizer;

-(id)initWithStyle:(int)arg1 reuseIdentifier:(id)arg2 specifier:(id)arg3;
@end


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