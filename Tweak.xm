#import <SpringBoard/SpringBoard.h>

@interface SBAppSwitcherController : UIViewController
@property(retain, nonatomic) NSArray *displayItems;
-(void)switcherScroller:(id)arg1 displayItemWantsToBeRemoved:(id)arg2 ;
-(void)launchAppWithIdentifier:(id)arg1 url:(id)arg2 actions:(id)arg3 ;
-(void)forceDismissAnimated:(BOOL)arg1 ;
-(void)switcherScroller:(id)arg1 itemTapped:(id)arg2;
-(void)closeAllApplications:(BOOL)includeWhitelist;
-(void)launchApplications:(NSMutableArray *)itemsToRun;
@end

@interface SBDisplayItem : NSObject
@property (nonatomic,readonly) NSString* displayIdentifier;
@end

@interface SBDisplayLayout : NSObject
-(NSArray *)displayItems;
@end

@interface SBAppSwitcherPageViewController
-(NSArray *)displayLayouts;
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
-(void)closeAllApplications:(BOOL)includeWhitelist;
-(void)launchApplications:(NSMutableArray *)itemsToRun;
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
static NSString *const kQuickAction = @"QuickAction";
static BOOL callOrig = NO;
static BOOL isShowingAlert = NO;
static BOOL isClosingAll = NO;

static void PreferencesChanged() {
	CFPreferencesAppSynchronize(CFSTR("com.dgh0st.alertclose"));
}

static BOOL boolValueForKey(NSString *key){ // get bool value of preference
	NSNumber *result = (__bridge NSNumber *)CFPreferencesCopyAppValue((CFStringRef)key, (CFStringRef)identifier);
	BOOL temp = result ? [result boolValue] : NO;
	[result release];
	return temp;
}

static NSString* stringValueForKey(NSString *key, NSString *textReplacement){ // get string value of preference
	NSString *settingsPath = [NSHomeDirectory() stringByAppendingPathComponent:@"/Library/Preferences/com.dgh0st.alertclose.plist"];
	NSString *temp = [[NSDictionary dictionaryWithContentsOfFile:settingsPath] objectForKey:key];
	if([temp isEqualToString:@""] || temp == nil){
		temp = @"What would you like to do with [app]? Choose wisely...";
	}
	return [temp stringByReplacingOccurrencesOfString:@"[app]" withString:textReplacement];
}

static CGFloat floatValueForKey(NSString *key, CGFloat defaultValue){ // get float value of preference
	NSNumber *result = (__bridge NSNumber *)CFPreferencesCopyAppValue((CFStringRef)key, (CFStringRef)identifier);
	CGFloat temp = result ? [result floatValue] : defaultValue;
	[result release];
	return temp;
}

static NSInteger intValueForKey(NSString *key, NSInteger defaultValue){ // get int value of preference
	NSNumber *result = (__bridge NSNumber *)CFPreferencesCopyAppValue((CFStringRef)key, (CFStringRef)identifier);
	NSInteger temp = result ? [result intValue] : defaultValue;
	[result release];
	return temp;
}

static BOOL getPerApp(NSString *appId, NSString *prefix) { // get bool value of preference of specific application (AppList)
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
		if([_item.displayIdentifier isEqualToString:@"com.apple.springboard"]){ // homescreen
			actionSheet.title = stringValueForKey(kCustomText, _item.displayIdentifier);
			actionSheet.delegate = self;
			[_actionSheet addButtonWithTitle:@"Respring"];
			[_actionSheet addButtonWithTitle:@"Kill-All Applications"];
			[_actionSheet addButtonWithTitle:@"Relaunch-All Applications"];
			cancelButtonIndex = [_actionSheet addButtonWithTitle:@"Cancel"];
		} else { // everything else
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
	if([_mode isEqualToString:@"Cancel"]){ // cancel
		if(_controller != nil){
			[_page cancelPossibleRemovalOfDisplayItem:_item];
		}
		_mode = @"Alert";
	} else if([_mode isEqualToString:@"Close Application"]){ // close application
		if(_controller != nil){
			callOrig = YES;
			[_controller switcherScroller:_page displayItemWantsToBeRemoved:_item];
		} else if(_deckController != nil && _container != nil && [_container displayItem] != nil){
			callOrig = YES;
			[_deckController killDisplayItemOfContainer:_container withVelocity:_velocity];
		}
		_mode = @"Alert";
	} else if([_mode isEqualToString:@"Relaunch Application"]){ // relaunch application
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
	} else if([_mode isEqualToString:@"Dismiss Switcher"]){ // dismiss switcher
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
	} else if([_mode isEqualToString:@"Respring"]){ // respring
		[[%c(FBSystemService) sharedInstance] exitAndRelaunch:YES];
		_mode = @"Alert";
	} else if([_mode isEqualToString:@"Kill-All Applications"]){ // kill-all applications
		if(_controller != nil){
			[_controller closeAllApplications:YES];
			if([_controller respondsToSelector:@selector(forceDismissAnimated:)]){
				[_controller forceDismissAnimated:YES];
			} else {
				SBDisplayItem *returnDisplayItem = MSHookIvar<SBDisplayItem *>(_controller, "_returnToDisplayItem");
				[_controller switcherScroller:_page itemTapped:returnDisplayItem];
			}
		}
		if(_deckController != nil){
			[_deckController closeAllApplications:YES];
			SBDisplayItem *returnDisplayItem = MSHookIvar<SBDisplayItem *>(_deckController, "_returnToDisplayItem");
			SBDeckSwitcherItemContainer *returnContainer = [_deckController _itemContainerForDisplayItem:returnDisplayItem];
			SBDeckSwitcherPageView *returnPage = MSHookIvar<SBDeckSwitcherPageView *>(returnContainer, "_pageView");
			[returnContainer _handlePageViewTap:returnPage];
		}
		_mode = @"Alert";
	} else if([_mode isEqualToString:@"Relaunch-All Applications"]){ // Relaunch-All applications
		if(_controller != nil){
			NSMutableArray *items = [[NSMutableArray alloc] initWithArray:[_controller displayItems]];
			[_controller closeAllApplications:NO];
			[_controller launchApplications:items];
			[items release];
		}
		if(_deckController != nil){
			NSMutableArray *items = [[NSMutableArray alloc] initWithArray:[_deckController displayItems]];
			[_deckController closeAllApplications:NO];
			[_deckController launchApplications:items];
			[items release];
		}
	}
	_alertWindow.hidden = YES;
	_alertWindow.rootViewController = nil;
	[self autorelease];
	isShowingAlert = NO;
}

-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
	return (toInterfaceOrientation != UIInterfaceOrientationPortraitUpsideDown) || ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad);
}
@end

%hook SBAppSwitcherController
-(void)switcherIconScroller:(SBAppSwitcherPageViewController *)arg1 contentOffsetChanged:(CGFloat)arg2 {
	NSInteger quickActionIndicator = intValueForKey(kQuickAction, 0);
	if (callOrig) {
		%orig;
	} else if (boolValueForKey(kIsEnabled) && quickActionIndicator != 0 && arg2 < 0.0f &&  (-1.0f * arg2) > floatValueForKey(kVerticalScroll, 0.175)) {
		if (quickActionIndicator == 1) { // respring
			[[%c(FBSystemService) sharedInstance] exitAndRelaunch:YES];
		} else if (quickActionIndicator == 2) { // kill-all applications
			[self closeAllApplications:YES];
			if([self respondsToSelector:@selector(forceDismissAnimated:)]){
				[self forceDismissAnimated:YES];
			} else {
				SBDisplayItem *returnDisplayItem = MSHookIvar<SBDisplayItem *>(self, "_returnToDisplayItem");
				[self switcherScroller:arg1 itemTapped:returnDisplayItem];
			}
		} else if (quickActionIndicator == 3) { // relaunch-all applications
			NSMutableArray *items = [[NSMutableArray alloc] initWithArray:[self displayItems]];
			[self closeAllApplications:NO];
			[self launchApplications:items];
			[items release];
		} else if (quickActionIndicator == 4) { // launch application
			NSMutableArray *items = [[NSMutableArray alloc] initWithArray:[[[arg1 displayLayouts] objectAtIndex:0] displayItems]];
			SBDisplayItem *_item = [items objectAtIndex:0];
			[self switcherScroller:arg1 itemTapped:_item];
		} else if (quickActionIndicator == 5) { // close application
			callOrig = YES;
			NSMutableArray *items = [[NSMutableArray alloc] initWithArray:[[[arg1 displayLayouts] objectAtIndex:0] displayItems]];
			SBDisplayItem *_item = [items objectAtIndex:0];
			[self switcherScroller:arg1 displayItemWantsToBeRemoved:_item];
			[items release];
		} else if (quickActionIndicator == 6) { // relaunch application
			callOrig = YES;
			NSMutableArray *items = [[NSMutableArray alloc] initWithArray:[[[arg1 displayLayouts] objectAtIndex:0] displayItems]];
			SBDisplayItem *_item = [items objectAtIndex:0];
			[self switcherScroller:arg1 displayItemWantsToBeRemoved:_item];
			if([self respondsToSelector:@selector(launchAppWithIdentifier:url:actions:)]) {
				[self launchAppWithIdentifier:_item.displayIdentifier url:nil actions:nil];
			} else {
				[(SpringBoard *)[UIApplication sharedApplication] launchApplicationWithIdentifier:_item.displayIdentifier suspended:NO];
			}
			[items release];
		} else if (quickActionIndicator == 7) { // dismiss switcher
			if([self respondsToSelector:@selector(forceDismissAnimated:)]) {
				[self forceDismissAnimated:YES];
			} else {
				SBDisplayItem *returnDisplayItem = MSHookIvar<SBDisplayItem *>(self, "_returnToDisplayItem");
				[self switcherScroller:arg1 itemTapped:returnDisplayItem];
			}
		}
	} else {
		%orig;
	}
}

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
-(void)closeAllApplications:(BOOL)includeWhitelist {
	isClosingAll = YES;
	NSString *nowPlayingBundleIdentifier = [[[%c(SBMediaController) sharedInstance] nowPlayingApplication] bundleIdentifier];
	NSMutableArray *items = [[NSMutableArray alloc] initWithArray:[self displayItems]];
	[items removeObjectAtIndex:0];
	SBAppSwitcherPageViewController *pageController = MSHookIvar<SBAppSwitcherPageViewController *>(self, "_pageController");
	for(SBDisplayItem *item in items){ // close applications
		if (includeWhitelist){
			if(!boolValueForKey(kWhitelist) || !getPerApp(item.displayIdentifier, kPerAppKill)){
				if (boolValueForKey(kIsNowPlayingEnabled) && [item.displayIdentifier isEqualToString:nowPlayingBundleIdentifier]) {
					continue;
				}
				[self switcherScroller:pageController displayItemWantsToBeRemoved:item];
			}
		} else {
			[self switcherScroller:pageController displayItemWantsToBeRemoved:item];
		}
	}
	isClosingAll = NO;
	[items release];
}

%new
-(void)launchApplications:(NSMutableArray *)itemsToRun {
	for (SBDisplayItem *item in itemsToRun){ // launch
		if([self respondsToSelector:@selector(launchAppWithIdentifier:url:actions:)]) {
			[self launchAppWithIdentifier:item.displayIdentifier url:nil actions:nil];
		} else {
			[(SpringBoard *)[UIApplication sharedApplication] launchApplicationWithIdentifier:item.displayIdentifier suspended:NO];
		}
	}
}
%end

%hook SBDeckSwitcherViewController
-(void)scrollViewKillingProgressUpdated:(CGFloat)arg1 ofContainer:(SBDeckSwitcherItemContainer *)arg2 {
	SBDisplayItem *selected = [arg2 displayItem];
	NSInteger quickActionIndicator = intValueForKey(kQuickAction, 0);
	if (boolValueForKey(kIsEnabled) && quickActionIndicator != 0 && arg1 < 0.0f &&  (-1.0f * arg1) > floatValueForKey(kVerticalScroll, 0.175)) {
		if (quickActionIndicator == 1) { // respring
			[[%c(FBSystemService) sharedInstance] exitAndRelaunch:YES];
		} else if (quickActionIndicator == 2) { // kill-all applications
			[self closeAllApplications:YES];
			SBDisplayItem *returnDisplayItem = MSHookIvar<SBDisplayItem *>(self, "_returnToDisplayItem");
			SBDeckSwitcherItemContainer *returnContainer = [self _itemContainerForDisplayItem:returnDisplayItem];
			SBDeckSwitcherPageView *returnPage = MSHookIvar<SBDeckSwitcherPageView *>(returnContainer, "_pageView");
			[returnContainer _handlePageViewTap:returnPage];
		} else if (quickActionIndicator == 3) { // relaunch-all applications
			NSMutableArray *items = [[NSMutableArray alloc] initWithArray:[self displayItems]];
			[self closeAllApplications:NO];
			[self launchApplications:items];
			[items release];
		} else if (quickActionIndicator == 4) { // launch application
			SBDeckSwitcherPageView *returnPage = MSHookIvar<SBDeckSwitcherPageView *>(arg2, "_pageView");
			[arg2 _handlePageViewTap:returnPage];
		} else if (quickActionIndicator == 5) { // close application
			callOrig = YES;
			[self killDisplayItemOfContainer:arg2 withVelocity:1.0];
		} else if (quickActionIndicator == 6) { // relaunch application
			callOrig = YES;
			[self killDisplayItemOfContainer:arg2 withVelocity:1.0];
			[(SpringBoard *)[UIApplication sharedApplication] launchApplicationWithIdentifier:selected.displayIdentifier suspended:NO];
		} else if (quickActionIndicator == 7) { // dismiss switcher
			SBDisplayItem *returnDisplayItem = MSHookIvar<SBDisplayItem *>(self, "_returnToDisplayItem");
			SBDeckSwitcherItemContainer *returnContainer = [self _itemContainerForDisplayItem:returnDisplayItem];
			SBDeckSwitcherPageView *returnPage = MSHookIvar<SBDeckSwitcherPageView *>(returnContainer, "_pageView");
			[returnContainer _handlePageViewTap:returnPage];
		}
	} else if((boolValueForKey(kIsEnabled) && getPerApp(selected.displayIdentifier, kPerApp)) || !boolValueForKey(kIsEnabled) || (boolValueForKey(kIsEnabled) && !getPerApp(selected.displayIdentifier, kPerApp) && arg1 < floatValueForKey(kVerticalScroll, 0.175)) || isClosingAll || (!boolValueForKey(kHomescreen) && [selected.displayIdentifier isEqualToString:@"com.apple.springboard"])){
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
-(void)closeAllApplications:(BOOL)includeWhitelist{
	isClosingAll = YES;
	NSString *nowPlayingBundleIdentifier = [[[%c(SBMediaController) sharedInstance] nowPlayingApplication] bundleIdentifier];
	NSMutableArray *items = [[NSMutableArray alloc] initWithArray:[self displayItems]];
	[items removeObjectAtIndex:0];
	for(SBDisplayItem *item in items){ // close applications
		if(includeWhitelist){
			if(!boolValueForKey(kWhitelist) || !getPerApp(item.displayIdentifier, kPerAppKill)){
				if (boolValueForKey(kIsNowPlayingEnabled) &&  [item.displayIdentifier isEqualToString:nowPlayingBundleIdentifier]) {
					continue;
				}
				[self killDisplayItemOfContainer:[self _itemContainerForDisplayItem:item] withVelocity:1.0];
			}
		} else {
			[self killDisplayItemOfContainer:[self _itemContainerForDisplayItem:item] withVelocity:1.0];
		}
	}
	isClosingAll = NO;
	[items release];
}

%new
-(void)launchApplications:(NSMutableArray *)itemsToRun {
	for (SBDisplayItem *item in itemsToRun){ // launch applications
		[(SpringBoard *)[UIApplication sharedApplication] launchApplicationWithIdentifier:item.displayIdentifier suspended:NO];
	}
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
