#import <UIKit/UIKit.h>
#import <Preferences/PSListController.h>

@interface OCBRootListController : PSListController
@end

@implementation OCBRootListController
- (NSArray *)specifiers {
    if (!_specifiers) {
        _specifiers = [self loadSpecifiersFromPlistName:@"Root" target:self];
    }
    return _specifiers;
}
@end
