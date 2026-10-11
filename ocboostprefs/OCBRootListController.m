#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <Preferences/PSListController.h>

// ===== Banner đầu trang =====
@interface OCBHeaderView : UIView
@property (nonatomic, strong) UIView *card;
@property (nonatomic, strong) CAGradientLayer *gradient;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *subLabel;
@property (nonatomic, strong) UILabel *creditLabel;
@end

@implementation OCBHeaderView
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _card = [[UIView alloc] init];
        _card.layer.cornerRadius = 22;
        _card.clipsToBounds = YES;

        _gradient = [CAGradientLayer layer];
        _gradient.colors = @[
            (id)[UIColor colorWithRed:0.45 green:0.20 blue:0.95 alpha:1].CGColor,
            (id)[UIColor colorWithRed:0.00 green:0.70 blue:1.00 alpha:1].CGColor ];
        _gradient.startPoint = CGPointMake(0, 0);
        _gradient.endPoint = CGPointMake(1, 1);
        [_card.layer addSublayer:_gradient];
        [self addSubview:_card];

        _titleLabel = [[UILabel alloc] init];
        _titleLabel.text = @"OCBoost";
        _titleLabel.textColor = UIColor.whiteColor;
        _titleLabel.font = [UIFont systemFontOfSize:36 weight:UIFontWeightHeavy];
        [_card addSubview:_titleLabel];

        _subLabel = [[UILabel alloc] init];
        _subLabel.text = @"Tối ưu hiệu năng · Mạng siêu tốc";
        _subLabel.textColor = [UIColor colorWithWhite:1 alpha:0.9];
        _subLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightMedium];
        [_card addSubview:_subLabel];

        _creditLabel = [[UILabel alloc] init];
        _creditLabel.text = @"Dev: Nguyễn Minh, Nam Khang";
        _creditLabel.textColor = [UIColor colorWithWhite:1 alpha:0.85];
        _creditLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightSemibold];
        [_card addSubview:_creditLabel];
    }
    return self;
}
- (void)layoutSubviews {
    [super layoutSubviews];
    CGRect b = CGRectInset(self.bounds, 16, 10);
    _card.frame = b;
    _gradient.frame = _card.bounds;
    CGFloat w = b.size.width - 40;
    _titleLabel.frame = CGRectMake(20, 24, w, 44);
    _subLabel.frame = CGRectMake(20, 72, w, 22);
    _creditLabel.frame = CGRectMake(20, b.size.height - 38, w, 20);
}
@end

// ===== Màn hình cài đặt =====
@interface OCBRootListController : PSListController
@end

@implementation OCBRootListController
- (NSArray *)specifiers {
    if (!_specifiers) {
        _specifiers = [self loadSpecifiersFromPlistName:@"Root" target:self];
    }
    return _specifiers;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    UIColor *accent = [UIColor colorWithRed:0.45 green:0.20 blue:0.95 alpha:1];
    self.view.tintColor = accent;
    [UISwitch appearanceWhenContainedInInstancesOfClasses:@[[OCBRootListController class]]].onTintColor = accent;

    OCBHeaderView *h = [[OCBHeaderView alloc] initWithFrame:CGRectMake(0, 0, self.table.bounds.size.width, 180)];
    h.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    self.table.tableHeaderView = h;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self reloadSpecifiers];
}

// Hiện nhiệt độ máy (đọc từ thermalState của iOS)
- (id)thermalText:(id)specifier {
    switch ([NSProcessInfo processInfo].thermalState) {
        case NSProcessInfoThermalStateNominal:  return @"Mát (bình thường)";
        case NSProcessInfoThermalStateFair:     return @"Hơi ấm";
        case NSProcessInfoThermalStateSerious:  return @"Nóng";
        case NSProcessInfoThermalStateCritical: return @"Rất nóng";
    }
    return @"Không rõ";
}
@end
