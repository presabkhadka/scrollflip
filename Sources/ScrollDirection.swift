import Foundation

/// Reads/writes macOS "Natural scrolling" (shared by trackpad and mouse).
/// Uses the private PreferencePanesSupport functions System Settings uses, so
/// changes apply instantly. Falls back to the defaults key (applies after logout).
enum ScrollDirection {
    private typealias Getter = @convention(c) () -> Bool
    private typealias Setter = @convention(c) (Bool) -> Void

    private static let handle = dlopen(
        "/System/Library/PrivateFrameworks/PreferencePanesSupport.framework/PreferencePanesSupport",
        RTLD_LAZY)

    private static let getter: Getter? = {
        guard let h = handle, let p = dlsym(h, "swipeScrollDirection") else { return nil }
        return unsafeBitCast(p, to: Getter.self)
    }()

    private static let setter: Setter? = {
        guard let h = handle, let p = dlsym(h, "setSwipeScrollDirection") else { return nil }
        return unsafeBitCast(p, to: Setter.self)
    }()

    private static let key = "com.apple.swipescrolldirection"

    /// True when the change takes effect immediately (private API available).
    static var appliesLive: Bool { setter != nil }

    static var isNatural: Bool {
        if let getter { return getter() }
        let v = CFPreferencesCopyValue(key as CFString, kCFPreferencesAnyApplication,
                                       kCFPreferencesCurrentUser, kCFPreferencesAnyHost)
        return (v as? Bool) ?? true
    }

    static func set(natural: Bool) {
        if let setter {
            setter(natural)
        } else {
            CFPreferencesSetValue(key as CFString, natural as CFBoolean, kCFPreferencesAnyApplication,
                                  kCFPreferencesCurrentUser, kCFPreferencesAnyHost)
            CFPreferencesSynchronize(kCFPreferencesAnyApplication, kCFPreferencesCurrentUser,
                                     kCFPreferencesAnyHost)
        }
        DistributedNotificationCenter.default().postNotificationName(
            Notification.Name("SwipeScrollDirectionDidChangeNotification"),
            object: nil, userInfo: nil, deliverImmediately: true)
    }

    @discardableResult
    static func toggle() -> Bool {
        let next = !isNatural
        set(natural: next)
        return next
    }
}
