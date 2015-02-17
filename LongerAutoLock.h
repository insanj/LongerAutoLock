#import <UIKit/UIKit.h>
#import <Cephei/HBPreferences.h>
#import <Foundation/NSDistributedNotificationCenter.h>
#import <Preferences/Preferences.h>
#import "substrate.h"

/*@interface PSListController : PSViewController <UITableViewDelegate, UITableViewDataSource>{
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
-(void)selectRowForSpecifier:(id)arg1;
-(void)tableView:(id)arg1 didSelectRowAtIndexPath:(id)arg2;
@end

@interface PSListItemsController : PSListController
-(id)tableView:(id)arg1 cellForRowAtIndexPath:(id)arg2;
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
-(void)setLongTapRecognizer:(UILongPressGestureRecognizer *)arg1;
-(void)setTitle:(NSString *)arg1;
-(NSString *)title;
@end
*/

@interface MCProfileConnection : NSObject

+ (MCProfileConnection *)sharedConnection;
- (void)setValue:(id)value forSetting:(id)setting;
- (id)effectiveParametersForValueSetting:(id)setting;
- (void)setParameters:(id)arg1 forValueSetting:(id)arg2;
 
@end

@interface UITableViewLabel : UILabel

- (void)setText:(NSString *)arg1;

@end
