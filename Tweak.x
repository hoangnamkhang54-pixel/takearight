#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <pthread.h>

static NSString *const kDomain = @"com.namkhang.ocboost";
static BOOL gEnabled = NO;
static BOOL gNet = NO;
static BOOL gNoLPM = NO;
static float gAnim = 1.3f;
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

// Tối đa: animation nhanh theo thanh trượt + QoS cao nhất. Chế độ khác: về bình thường.
static void refreshWindows(void) {
    dispatch_async(dispatch_get_main_queue(), ^{
        BOOL max = gEnabled && [effectiveMode() isEqualToString:@"max"];
        if (max) pthread_set_qos_class_self_np(QOS_CLASS_USER_INTERACTIVE, 0);
        float speed = max ? gAnim : 1.0f;
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
    gNoLPM = [d boolForKey:@"nolpm"];
    gMode = [d stringForKey:@"mode"] ?: @"balanced";
    float a = [d objectForKey:@"animspeed"] ? [d floatForKey:@"animspeed"] : 1.3f;
    gAnim = MAX(1.0f, MIN(2.0f, a));

    // Mạng siêu tốc: cache lớn hơn cho tải lại nhanh hơn
    if (gEnabled && gNet) {
        NSURLCache *c = [NSURLCache sharedURLCache];
        if (c.memoryCapacity < 64u * 1024 * 1024) c.memoryCapacity = 64u * 1024 * 1024;
        if (c.diskCapacity < 512u * 1024 * 1024) c.diskCapacity = 512u * 1024 * 1024;
    }
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

// App tự giảm chất lượng khi Tiết kiệm pin: cho app thấy là đang tắt
%hook NSProcessInfo
- (BOOL)isLowPowerModeEnabled {
    if (gEnabled && gNoLPM) return NO;
    return %orig;
}
%end

// Mạng siêu tốc: 24 kết nối song song/host, pipelining, chờ mạng thay vì báo lỗi ngay
static void tuneNet(NSURLSessionConfiguration *c) {
    if (gEnabled && gNet) {
        c.HTTPMaximumConnectionsPerHost = 24;
        c.HTTPShouldUsePipelining = YES;
        c.waitsForConnectivity = YES;
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
