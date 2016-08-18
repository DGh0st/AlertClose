#import <SpringBoard/SpringBoard.h>

@interface SBAppSwitcherController : UIViewController
@property(retain, nonatomic) NSArray *displayItems;
-(void)switcherScroller:(id)arg1 displayItemWantsToBeRemoved:(id)arg2 ;
-(void)launchAppWithIdentifier:(id)arg1 url:(id)arg2 actions:(id)arg3 ;
-(void)forceDismissAnimated:(BOOL)arg1 ;
-(void)switcherScroller:(id)arg1 itemTapped:(id)arg2;
-(void)closeAllApplications;
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
-(void)scrollViewKillingProgressUpdated:(CGFloat)arg1 ofContainer:(id)arg2;
-(void)removeDisplayItem:(id)arg1 updateScrollPosition:(_Bool)arg2 forReason:(NSInteger)arg3 completion:(id)arg4;
-(CGFloat)minimumVerticalTranslationForKillingOfContainer:(id)arg1;
-(void)killDisplayItemOfContainer:(id)arg1 withVelocity:(CGFloat)arg2;
-(id)_itemContainerForDisplayItem:(id)arg1;
-(void)closeAllApplications;
@end

@interface SBDeckSwitcherPageView
@end

@interface UIApplication (AlertClose)
+(id)sharedApplication;
-(BOOL)launchApplicationWithIdentifier:(id)arg1 suspended:(BOOL)arg2;
@end

@interface SpringBoard (AlertClose)
-(BOOL)launchApplicationWithIdentifier:(id)arg1 suspended:(BOOL)arg2;
-(void)_handleMenuButtonEvent;
@end

@interface FBSystemService
+(id)sharedInstance;
-(void)exitAndRelaunch:(BOOL)arg1;
@end

@interface SBApplication (AlertClose)
-(id)bundleIdentifier;
@end

@interface SBMediaController (AlertClose)
+(id)sharedInstance;
-(SBApplication *)nowPlayingApplication;
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
static NSString *const kCustomText = @"customText";
static NSString *const kPerApp = @"PerApp-";
static NSString *const kHomescreen = @"isHomescreenEnabled";
static NSString *const kWhitelist = @"isWhitelistEnabled";
static NSString *const kPerAppKill = @"PerAppKill-";
static NSString *const kVerticalScroll = @"VerticalScroll";
static NSString *const kIsNowPlayingEnabled = @"isNowPlayingEnabled";
static BOOL callOrig = NO;
static BOOL isShowingAlert = NO;
static BOOL isClosingAll = NO;

static void PreferencesChanged() {
	CFPreferencesAppSynchronize(CFSTR("com.dgh0st.alertclose"));
}

static BOOL boolValueForKey(NSString *key){
	NSNumber *result = (__bridge NSNumber *)CFPreferencesCopyAppValue((CFStringRef)key, (CFStringRef)identifier);
	BOOL temp = result ? [result boolValue] : NO;
	[result release];
	return temp;
}

static NSString* stringValueForKey(NSString *key, NSString *textReplacement){
	NSString *settingsPath = [NSHomeDirectory() stringByAppendingPathComponent:@"/Library/Preferences/com.dgh0st.alertclose.plist"];
	NSString *temp = [[NSDictionary dictionaryWithContentsOfFile:settingsPath] objectForKey:key];
	if([temp isEqualToString:@""] || temp == nil){
		temp = @"What would you like to do with [app]? Choose wisely...";
	}
	return [temp stringByReplacingOccurrencesOfString:@"[app]" withString:textReplacement];
}

static CGFloat floatValueForKey(NSString *key, CGFloat defaultValue){
	NSNumber *result = (__bridge NSNumber *)CFPreferencesCopyAppValue((CFStringRef)key, (CFStringRef)identifier);
	CGFloat temp = result ? [result floatValue] : defaultValue;
	[result release];
	return temp;
}

static BOOL getPerApp(NSString *appId, NSString *prefix) {
    BOOL result = NO;
    NSArray *allKeys = (NSArray *)CFPreferencesCopyKeyList(CFSTR("com.dgh0st.alertclose"), kCFPreferencesCurrentUser, kCFPreferencesCurrentHost);
    for (NSString *key in allKeys) {
		if ([key hasPrefix:prefix] && CFPreferencesGetAppIntegerValue((CFStringRef)key, CFSTR("com.dgh0st.alertclose"), NULL)) {
		    NSString *tempId = [key substringFromIndex:[prefix length]];
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
		NSInteger cancelButtonIndex;
		if([_item.displayIdentifier isEqualToString:@"com.apple.springboard"]){
			actionSheet.title = stringValueForKey(kCustomText, _item.displayIdentifier);
			actionSheet.delegate = self;
			[_actionSheet addButtonWithTitle:@"Respring"];
			[_actionSheet addButtonWithTitle:@"Kill-All Applications"];
			cancelButtonIndex = [_actionSheet addButtonWithTitle:@"Cancel"];
		} else {
			actionSheet.title = stringValueForKey(kCustomText, _item.displayIdentifier);
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
			cancelButtonIndex = ((boolValueForKey(kIsCancelEnabled) || (!boolValueForKey(kIsCloseEnabled) && !boolValueForKey(kIsRelaunchEnabled) && !(boolValueForKey(kIsDismissEnabled)))))?[_actionSheet addButtonWithTitle:@"Cancel"]:0;
		}
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
		if(_controller != nil){
			callOrig = YES;
			[_controller switcherScroller:_page displayItemWantsToBeRemoved:_item];
		} else if(_deckController != nil && _container != nil && [_container displayItem] != nil){
			callOrig = YES;
			[_deckController killDisplayItemOfContainer:_container withVelocity:_velocity];
		}
		_mode = @"Alert";
	} else if([_mode isEqualToString:@"Relaunch Application"]){
		if(_controller != nil){
			callOrig = YES;
			[_controller switcherScroller:_page displayItemWantsToBeRemoved:_item];
			if([_controller respondsToSelector:@selector(launchAppWithIdentifier:url:actions:)]){
				[_controller launchAppWithIdentifier:_item.displayIdentifier url:nil actions:nil];
			} else {
				[(SpringBoard *)[UIApplication sharedApplication] launchApplicationWithIdentifier:_item.displayIdentifier suspended:NO];
			}
		} else if(_deckController != nil && _container != nil && [_container displayItem] != nil){
			callOrig = YES;
			[_deckController killDisplayItemOfContainer:_container withVelocity:_velocity];
			[(SpringBoard *)[UIApplication sharedApplication] launchApplicationWithIdentifier:_item.displayIdentifier suspended:NO];
		}
		_mode = @"Alert";
	} else if([_mode isEqualToString:@"Dismiss Switcher"]){
		if(_controller != nil){
			[_page cancelPossibleRemovalOfDisplayItem:_item];
			if([_controller respondsToSelector:@selector(forceDismissAnimated:)]){
				[_controller forceDismissAnimated:YES];
			} else {
				SBDisplayItem *returnDisplayItem = MSHookIvar<SBDisplayItem *>(_controller, "_returnToDisplayItem");
				[_controller switcherScroller:_page itemTapped:returnDisplayItem];
			}
		} else {
			SBDisplayItem *returnDisplayItem = MSHookIvar<SBDisplayItem *>(_deckController, "_returnToDisplayItem");
			SBDeckSwitcherItemContainer *returnContainer = [_deckController _itemContainerForDisplayItem:returnDisplayItem];
			SBDeckSwitcherPageView *returnPage = MSHookIvar<SBDeckSwitcherPageView *>(returnContainer, "_pageView");
			[returnContainer _handlePageViewTap:returnPage];
		}
		_mode = @"Alert";
	} else if([_mode isEqualToString:@"Respring"]){
		[[%c(FBSystemService) sharedInstance] exitAndRelaunch:YES];
		_mode = @"Alert";
	} else if([_mode isEqualToString:@"Kill-All Applications"]){
		if(_controller != nil){
			[_controller closeAllApplications];
			if([_controller respondsToSelector:@selector(forceDismissAnimated:)]){
				[_controller forceDismissAnimated:YES];
			} else {
				SBDisplayItem *returnDisplayItem = MSHookIvar<SBDisplayItem *>(_controller, "_returnToDisplayItem");
				[_controller switcherScroller:_page itemTapped:returnDisplayItem];
			}
		}
		if(_deckController != nil){
			[_deckController closeAllApplications];
			SBDisplayItem *returnDisplayItem = MSHookIvar<SBDisplayItem *>(_deckController, "_returnToDisplayItem");
			SBDeckSwitcherItemContainer *returnContainer = [_deckController _itemContainerForDisplayItem:returnDisplayItem];
			SBDeckSwitcherPageView *returnPage = MSHookIvar<SBDeckSwitcherPageView *>(returnContainer, "_pageView");
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
	if((boolValueForKey(kIsEnabled) && getPerApp(arg2.displayIdentifier, kPerApp)) || !boolValueForKey(kIsEnabled) || callOrig || isClosingAll || (!boolValueForKey(kHomescreen) && [arg2.displayIdentifier isEqualToString:@"com.apple.springboard"])){
		%orig;
		callOrig = NO;
	} else {
		DGAlertClose *temp = [[%c(DGAlertClose) alloc] initWithMode:@"Alert"];
		[temp show:self pageView:arg1 displayItem:arg2 velocity:1.0 deckController:nil itemContainer:nil reason:1];
		[temp release];
		temp = nil;
	}
}

-(_Bool)switcherScroller:(id)arg1 isDisplayItemRemovable:(SBDisplayItem *)arg2 {
    return %orig(arg1, arg2) || (boolValueForKey(kIsEnabled) && boolValueForKey(kHomescreen) && [arg2.displayIdentifier isEqualToString:@"com.apple.springboard"]);
}

%new
-(void)closeAllApplications{
	isClosingAll = YES;
	NSString *nowPlayingBundleIdentifier = [[[%c(SBMediaController) sharedInstance] nowPlayingApplication] bundleIdentifier];
	NSMutableArray *items = [[NSMutableArray alloc] initWithArray:[self displayItems]];
	[items removeObjectAtIndex:0];
	SBAppSwitcherPageViewController *pageController = MSHookIvar<SBAppSwitcherPageViewController *>(self, "_pageController");
	for(SBDisplayItem *item in items){
		if(!boolValueForKey(kWhitelist) || !getPerApp(item.displayIdentifier, kPerAppKill)){
			if (boolValueForKey(kIsNowPlayingEnabled) && [item.displayIdentifier isEqualToString:nowPlayingBundleIdentifier]) {
				continue;
			}
			[self switcherScroller:pageController displayItemWantsToBeRemoved:item];
		}
	}
	isClosingAll = NO;
	[items release];
}
%end

%hook SBDeckSwitcherViewController
-(void)scrollViewKillingProgressUpdated:(CGFloat)arg1 ofContainer:(SBDeckSwitcherItemContainer *)arg2 {
	SBDisplayItem *selected = [arg2 displayItem];
	if((boolValueForKey(kIsEnabled) && getPerApp(selected.displayIdentifier, kPerApp)) || !boolValueForKey(kIsEnabled) || (boolValueForKey(kIsEnabled) && !getPerApp(selected.displayIdentifier, kPerApp) && arg1 < floatValueForKey(kVerticalScroll, 0.175)) || isClosingAll || (!boolValueForKey(kHomescreen) && [selected.displayIdentifier isEqualToString:@"com.apple.springboard"])){
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
	if(boolValueForKey(kIsEnabled) && !getPerApp([arg1 displayItem].displayIdentifier, kPerApp)){
		return NO;
	}
	return %orig(arg1);
}

%new
-(void)closeAllApplications{
	isClosingAll = YES;
	NSString *nowPlayingBundleIdentifier = [[[%c(SBMediaController) sharedInstance] nowPlayingApplication] bundleIdentifier];
	NSMutableArray *items = [[NSMutableArray alloc] initWithArray:[self displayItems]];
	[items removeObjectAtIndex:0];
	for(SBDisplayItem *item in items){
		if(!boolValueForKey(kWhitelist) || !getPerApp(item.displayIdentifier, kPerAppKill)){
			if (boolValueForKey(kIsNowPlayingEnabled) &&  [item.displayIdentifier isEqualToString:nowPlayingBundleIdentifier]) {
				continue;
			}
			[self killDisplayItemOfContainer:[self _itemContainerForDisplayItem:item] withVelocity:1.0];
		}
	}
	isClosingAll = NO;
	[items release];
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
