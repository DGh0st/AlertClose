#import <SpringBoard/SpringBoard.h>

@interface SBAppSwitcherController
-(void)switcherScroller:(id)arg1 displayItemWantsToBeRemoved:(id)arg2 ;
-(void)launchAppWithIdentifier:(id)arg1 url:(id)arg2 actions:(id)arg3 ;
-(void)forceDismissAnimated:(BOOL)arg1 ;
@end

@interface SBDisplayItem : NSObject
@property (nonatomic,readonly) NSString* displayIdentifier;
@end

@interface SBAppSwitcherPageViewController
-(void)cancelPossibleRemovalOfDisplayItem:(id)arg1 ;
@end

@interface SBDeckSwitcherItemContainer
@property(readonly, retain, nonatomic) SBDisplayItem *displayItem;
- (void)_handlePageViewTap:(id)arg1;
@end

@interface SBDeckSwitcherViewController
@property(retain, nonatomic) NSArray *displayItems;
-(CGFloat)minimumVerticalTranslationForKillingOfContainer:(id)arg1;
-(void)killDisplayItemOfContainer:(id)arg1 withVelocity:(CGFloat)arg2;
-(id)_itemContainerForDisplayItem:(id)arg1;
@end

@interface SBDeckSwitcherPageView
@end

@interface UIApplication (AlertClose)
+(id)sharedApplication;
-(BOOL)launchApplicationWithIdentifier:(id)arg1 suspended:(BOOL)arg2;
@end

@interface SpringBoard (AlertClose)
-(BOOL)launchApplicationWithIdentifier:(id)arg1 suspended:(BOOL)arg2;
@end

__attribute__((visibility("hidden")))
@interface DGAlertClose : UIViewController <UIActionSheetDelegate>{
@private
	NSString *_mode;
	UIActionSheet *_actionSheet;
	UIWindow *_alertWindow;
	SBAppSwitcherController *_controller;
	SBAppSwitcherPageViewController *_page;
	SBDisplayItem *_item;
	SBDeckSwitcherItemContainer *_container;
	SBDeckSwitcherViewController *_deckController;
	CGFloat _velocity;
	NSInteger _reason;
}
@end

static NSString *const identifier = @"com.dgh0st.alertclose";
static NSString *const kIsEnabled = @"isEnabled";
static NSString *const kIsCloseEnabled = @"isCloseEnabled";
static NSString *const kIsRelaunchEnabled = @"isRelaunchEnabled";
static NSString *const kIsDismissEnabled = @"isDismissEnabled";
static NSString *const kIsCancelEnabled = @"isCancelEnabled";
static BOOL callOrig = NO;
static BOOL isShowingAlert = NO;

static void PreferencesChanged() {
	CFPreferencesAppSynchronize(CFSTR("com.dgh0st.alertclose"));
}

static BOOL boolValueForKey(NSString *key){
	NSNumber *result = (__bridge NSNumber *)CFPreferencesCopyAppValue((CFStringRef)key, (CFStringRef)identifier);
	BOOL temp = result ? [result boolValue] : NO;
	[result release];
	return temp;
}

static BOOL getPerApp(NSString *appId) {
    BOOL result = NO;
    NSArray *allKeys = (NSArray *)CFPreferencesCopyKeyList(CFSTR("com.dgh0st.alertclose"), kCFPreferencesCurrentUser, kCFPreferencesCurrentHost);
    for (NSString *key in allKeys) {
		if ([key hasPrefix:@"PerApp-"] && CFPreferencesGetAppIntegerValue((CFStringRef)key, CFSTR("com.dgh0st.alertclose"), NULL)) {
		    NSString *tempId = [key substringFromIndex:[@"PerApp-" length]];
		    if ([tempId isEqual:appId]) {
				result = YES;
				break;
		    }
		}
   	}
    [allKeys release];
    return result;
}

@implementation DGAlertClose
-(id)initWithMode:(NSString *)mode{
	if((self = [super init])){
		_mode = mode;
	}
	return self;
}
-(void)dealloc{
	[_actionSheet release];
	[_alertWindow release];
	[super dealloc];
}
-(void)show:(SBAppSwitcherController *)controller pageView:(SBAppSwitcherPageViewController *)page displayItem:(SBDisplayItem *)item velocity:(CGFloat)velocity deckController:(SBDeckSwitcherViewController *)deckController itemContainer:(SBDeckSwitcherItemContainer *)container reason:(NSInteger)reason{
	_controller = controller;
	_page = page;
	_item = item;
	_velocity = velocity;
	_deckController = deckController;
	_container = container;
	_reason	= reason;
	if(!_actionSheet){
		UIActionSheet *actionSheet = _actionSheet = [[%c(UIActionSheet) alloc] init];
		actionSheet.title =[NSString stringWithFormat:@"What would you like to do with %@? Choose wisely...",_item.displayIdentifier];
		actionSheet.delegate = self;
		if(boolValueForKey(kIsCloseEnabled)){
			[_actionSheet addButtonWithTitle:@"Close Application"];
		}
		if(boolValueForKey(kIsRelaunchEnabled)){
			[_actionSheet addButtonWithTitle:@"Relaunch Application"];
		}
		if(boolValueForKey(kIsDismissEnabled)){
			[_actionSheet addButtonWithTitle:@"Dismiss Switcher"];
		}
		NSInteger cancelButtonIndex = ((boolValueForKey(kIsCancelEnabled) || (!boolValueForKey(kIsCloseEnabled) && !boolValueForKey(kIsRelaunchEnabled) && !(boolValueForKey(kIsDismissEnabled)))))?[_actionSheet addButtonWithTitle:@"Cancel"]:0;
		if(!_alertWindow){
			_alertWindow = [[%c(UIWindow) alloc] initWithFrame:[%c(UIScreen) mainScreen].bounds];
			_alertWindow.windowLevel = 100.0f;
		}
		_alertWindow.hidden = NO;
		_alertWindow.rootViewController = self;
		if ([_alertWindow respondsToSelector:@selector(_updateToInterfaceOrientation:animated:)]){
			[_alertWindow _updateToInterfaceOrientation:[(SpringBoard *)UIApp _frontMostAppOrientation] animated:NO];
		}
		actionSheet.cancelButtonIndex = cancelButtonIndex;
		[actionSheet showInView:self.view];
	}
}
-(void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex{
	[self retain];
	_mode = [actionSheet buttonTitleAtIndex:buttonIndex];
	if([_mode isEqualToString:@"Cancel"]){
		if(_controller != nil){
			[_page cancelPossibleRemovalOfDisplayItem:_item];
		}
		_mode = @"Alert";
	} else if([_mode isEqualToString:@"Close Application"]){
		callOrig = YES;
		if(_controller != nil){
			[_controller switcherScroller:_page displayItemWantsToBeRemoved:_item];
		} else if(_deckController != nil && _container != nil && [_container displayItem] != nil){
			[_deckController killDisplayItemOfContainer:_container withVelocity:_velocity];
		}
		_mode = @"Alert";
	} else if([_mode isEqualToString:@"Relaunch Application"]){
		if(_controller != nil){
			callOrig = YES;
			[_controller switcherScroller:_page displayItemWantsToBeRemoved:_item];
			[_controller launchAppWithIdentifier:_item.displayIdentifier url:nil actions:nil];
		} else if(_deckController != nil && _container != nil && [_container displayItem] != nil){
			callOrig = YES;
			[_deckController killDisplayItemOfContainer:_container withVelocity:_velocity];
			[(SpringBoard *)[UIApplication sharedApplication] launchApplicationWithIdentifier:_item.displayIdentifier suspended:NO];
		}
		_mode = @"Alert";
	} else if([_mode isEqualToString:@"Dismiss Switcher"]){
		if(_controller != nil){
			[_controller forceDismissAnimated:YES];
		} else {
			SBDisplayItem *returnDisplayItem = MSHookIvar<SBDisplayItem *>(_deckController, "_returnToDisplayItem");
			SBDeckSwitcherItemContainer *returnContainer = [_deckController _itemContainerForDisplayItem:returnDisplayItem];
			SBDeckSwitcherPageView * returnPage = MSHookIvar<SBDeckSwitcherPageView *>(returnContainer, "_pageView");
			[returnContainer _handlePageViewTap:returnPage];
		}
		_mode = @"Alert";
	}
	_alertWindow.hidden = YES;
	_alertWindow.rootViewController = nil;
	[self autorelease];
	isShowingAlert = NO;
}
-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
	return (toInterfaceOrientation != UIInterfaceOrientationPortraitUpsideDown) || ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad);
}
@end

%hook SBAppSwitcherController
-(void)switcherScroller:(SBAppSwitcherPageViewController *)arg1 displayItemWantsToBeRemoved:(SBDisplayItem *)arg2 {
	if((boolValueForKey(kIsEnabled) && getPerApp(arg2.displayIdentifier)) || !boolValueForKey(kIsEnabled) || callOrig){
		%orig;
		callOrig = NO;
	} else {
		DGAlertClose *temp = [[%c(DGAlertClose) alloc] initWithMode:@"Alert"];
		[temp show:self pageView:arg1 displayItem:arg2 velocity:1.0 deckController:nil itemContainer:nil reason:1];
		[temp release];
		temp = nil;
	}
}
%end

%hook SBDeckSwitcherViewController
-(void)scrollViewKillingProgressUpdated:(CGFloat)arg1 ofContainer:(SBDeckSwitcherItemContainer *)arg2 {
	SBDisplayItem *selected = [arg2 displayItem];
	if([selected.displayIdentifier isEqualToString:@"com.apple.springboard"] || (boolValueForKey(kIsEnabled) && getPerApp(selected.displayIdentifier)) || !boolValueForKey(kIsEnabled) || (boolValueForKey(kIsEnabled) && !getPerApp(selected.displayIdentifier) && arg1 < 0.175)){
		%orig;
	} else if(!isShowingAlert) {
		isShowingAlert = YES;
		DGAlertClose *temp = [[%c(DGAlertClose) alloc] initWithMode:@"Alert"];
		[temp show:nil pageView:nil displayItem:selected velocity:1.0 deckController:self itemContainer:arg2 reason:1];
		[temp release];
		temp = nil;
	} else {
		%orig;
	}
}

-(_Bool)isDisplayItemOfContainerRemovable:(id)arg1{
	if(boolValueForKey(kIsEnabled) && !getPerApp([arg1 displayItem].displayIdentifier)){
		return NO;
	}
	return %orig(arg1);
}
%end

%ctor {
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
				    NULL,
				    (CFNotificationCallback)PreferencesChanged,
				    CFSTR("com.dgh0st.alertclose/settingschanged"),
				    NULL,
				    CFNotificationSuspensionBehaviorDeliverImmediately);
}
