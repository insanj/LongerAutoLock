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