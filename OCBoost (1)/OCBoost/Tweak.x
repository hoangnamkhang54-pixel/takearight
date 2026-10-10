#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <pthread.h>

static NSString *const kDomain = @"com.namkhang.ocboost";
static BOOL gEnabled = NO;
static BOOL gNet = NO;
static NSString *gMode = @"balanced"; // cool | balanced | max | smart

// Chế độ thực tế đang áp dụng (Thông minh = tự chọn theo nhiệt độ)
static NSString *effectiveMode(void) {
    if (![gMode isEqualToString:@"smart"]) return gMode;
    switch ([NSProcessInfo processInfo].thermalState) {
        case NSProcessInfoThermalStateNominal: return @"max";
        case NSProcessInfoThermalStateFair:    return @"balanced";
        default:                               return @"cool";
    }
}

// Tối đa: animation nhanh 1.3x + QoS cao nhất. Các chế độ khác: về bình thường.
static void refreshWindows(void) {
    dispatch_async(dispatch_get_main_queue(), ^{
        BOOL max = gEnabled && [effectiveMode() isEqualToString:@"max"];
        if (max) pthread_set_qos_class_self_np(QOS_CLASS_USER_INTERACTIVE, 0);
        float speed = max ? 1.3f : 1.0f;
        for (UIScene *s in [UIApplication sharedApplication].connectedScenes) {
            if (![s isKindOfClass:[UIWindowScene class]]) continue;
            for (UIWindow *w in ((UIWindowScene *)s).windows) w.layer.speed = speed;
        }
    });
}

static void loadPrefs(void) {
    NSUserDefaults *d = [[NSUserDefaults alloc] initWithSuiteName:kDomain];
    gEnabled = [d boolForKey:@"enabled"];
    gNet = [d boolForKey:@"netboost"];
    gMode = [d stringForKey:@"mode"] ?: @"balanced";
    refreshWindows();
}

static void prefsChanged(CFNotificationCenterRef c, void *o, CFStringRef n, const void *obj, CFDictionaryRef u) {
    loadPrefs();
}

// Mát mẻ: giới hạn 60 FPS để máy bớt nóng
static NSInteger clampFPS(NSInteger fps) {
    if (gEnabled && [effectiveMode() isEqualToString:@"cool"]) {
        if (fps == 0 || fps > 60) return 60;
    }
    return fps;
}

%hook CADisplayLink
- (void)setPreferredFramesPerSecond:(NSInteger)fps {
    %orig(clampFPS(fps));
}
- (void)addToRunLoop:(NSRunLoop *)rl forMode:(NSRunLoopMode)mode {
    [self setPreferredFramesPerSecond:self.preferredFramesPerSecond];
    %orig;
}
%end

%hook UIWindow
- (void)makeKeyAndVisible {
    %orig;
    refreshWindows();
}
%end

// Mạng siêu tốc: nhiều kết nối song song hơn + pipelining (áp dụng cho session tạo mới)
static void tuneNet(NSURLSessionConfiguration *c) {
    if (gEnabled && gNet) {
        c.HTTPMaximumConnectionsPerHost = 16;
        c.HTTPShouldUsePipelining = YES;
    }
}

%hook NSURLSessionConfiguration
+ (NSURLSessionConfiguration *)defaultSessionConfiguration {
    NSURLSessionConfiguration *c = %orig;
    tuneNet(c);
    return c;
}
+ (NSURLSessionConfiguration *)ephemeralSessionConfiguration {
    NSURLSessionConfiguration *c = %orig;
    tuneNet(c);
    return c;
}
%end

%ctor {
    loadPrefs();
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, prefsChanged,
        CFSTR("com.namkhang.ocboost/prefschanged"), NULL, CFNotificationSuspensionBehaviorCoalesce);
    [[NSNotificationCenter defaultCenter] addObserverForName:NSProcessInfoThermalStateDidChangeNotification
        object:nil queue:nil usingBlock:^(NSNotification *n) { refreshWindows(); }];
}
