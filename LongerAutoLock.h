#import <UIKit/UIKit.h>
#import <Cephei/HBPreferences.h>
#import <Foundation/NSDistributedNotificationCenter.h>
#import <Preferences/Preferences.h>
#import "substrate.h"

#ifdef DEBUG
    #define LOG(fmt, ...) NSLog((@"[LongerAutoLock] %s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)
#else
    #define LOG(fmt, ...) 
#endif

#define NSStringFromBool(a) a?@"are":@"aren't"

#define GENERAL_TEXT  [[NSBundle mainBundle] localizedStringForKey:@"General" value:@"General" table:@"General"]
#define AUTOLOCK_TEXT  [[NSBundle mainBundle] localizedStringForKey:@"AUTOLOCK" value:@"Auto-Lock" table:@"General"]
#define LOCALIZE_NUM_TEXT [[NSBundle mainBundle] localizedStringForKey:@"10_MINUTES" value:@"%@ Minutes" table:@"General"]

#define LOCALIZE_NUM(str) [NSString stringWithFormat:LOCALIZE_NUM_TEXT, str]

static NSString * kLongerAutoLockIdentifier = @"com.insanj.longerautolock";
static NSString * kLongerAutoLockTimesIdentifier = @"LongerAutoLock.Times", *kLongerAutoLockSelectedRowIdentifier = @"LongerAutoLock.Row", *kLongerAutoLockLastSelectedTitleIdentifier = @"LongerAutoLock.Title";
