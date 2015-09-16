#import <SpringBoard/SpringBoard.h>

@interface SBAppSwitcherController

-(void)switcherScroller:(id)arg1 displayItemWantsToBeRemoved:(id)arg2 ;

-(void)launchAppWithIdentifier:(id)arg1 url:(id)arg2 actions:(id)arg3 ;

-(void)forceDismissAnimated:(BOOL)arg1 ;

-(void)_quitAppWithDisplayItem:(id)arg1 ;

@end


@interface SBDisplayItem : NSObject

@property (nonatomic,readonly) NSString* displayIdentifier;

@end


@interface SBAppSwitcherPageViewController

-(void)cancelPossibleRemovalOfDisplayItem:(id)arg1 ;

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
}
@end

static BOOL callOrig = NO;

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
-(void)show:(SBAppSwitcherController *)controller pageView:(SBAppSwitcherPageViewController *)page displayItem:(SBDisplayItem *)item{
	_controller = controller;
	_page = page;
	_item = item;
	if(!_actionSheet){
		UIActionSheet *actionSheet = _actionSheet = [[%c(UIActionSheet) alloc] init];
		actionSheet.title =@"What would you like to do? Choose wisely...";
		actionSheet.delegate = self;
		[_actionSheet addButtonWithTitle:@"Close Application"];
		[_actionSheet addButtonWithTitle:@"Relaunch Application"];
		[_actionSheet addButtonWithTitle:@"Dismiss Switcher"];
		NSInteger cancelButtonIndex = [_actionSheet addButtonWithTitle:@"Cancel"];
		if(!_alertWindow){
			_alertWindow = [[%c(UIWindow) alloc] initWithFrame:[%c(UIScreen) mainScreen].bounds];
			_alertWindow.windowLevel = 1050.1f;
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
		[_page cancelPossibleRemovalOfDisplayItem:_item];
	} else if([_mode isEqualToString:@"Close Application"]){
		callOrig = YES;
		[_controller switcherScroller:_page displayItemWantsToBeRemoved:_item];
		_mode = @"Alert";
	} else if([_mode isEqualToString:@"Relaunch Application"]){
		callOrig = YES;
		[_controller switcherScroller:_page displayItemWantsToBeRemoved:_item];
		[_controller launchAppWithIdentifier:_item.displayIdentifier url:nil actions:nil];
		_mode = @"Alert";
	} else if([_mode isEqualToString:@"Dismiss Switcher"]){
		[_controller forceDismissAnimated:YES];
		_mode = @"Alert";
	}
	_actionSheet.delegate = nil;
	[_actionSheet release];
	_actionSheet = nil;
	_alertWindow.hidden = YES;
	_alertWindow.rootViewController = nil;
	[_alertWindow release];
	_alertWindow = nil;
	[self autorelease];
}
-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
	return (toInterfaceOrientation != UIInterfaceOrientationPortraitUpsideDown) || ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad);
}
@end

%hook SBAppSwitcherController
-(void)switcherScroller:(SBAppSwitcherPageViewController *)arg1 displayItemWantsToBeRemoved:(SBDisplayItem *)arg2 {
	if(callOrig){
		%orig;
		callOrig = NO;
	} else {
		DGAlertClose *temp = [[%c(DGAlertClose) alloc] initWithMode:@"Alert"];
		[temp show:self pageView:arg1 displayItem:arg2];
		[temp release];
		temp = nil;
	}
}

%end
