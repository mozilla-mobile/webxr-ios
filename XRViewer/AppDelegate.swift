import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        registerDefaultsFromSettingsBundle()

        DDLog.add(DDTTYLogger.sharedInstance) // TTY = Xcode console

        UIApplication.shared.isIdleTimerDisabled = true

        let sendUsageData: Bool = UserDefaults.standard.bool(forKey: Constant.useAnalyticsKey())
        AnalyticsManager.sharedInstance.initialize(sendUsageData: sendUsageData)

        return true
    }

    func registerDefaultsFromSettingsBundle() {
        guard let settingsBundle = Bundle.main.url(forResource: "Settings", withExtension: "bundle") else {
            print("Could not find Settings.bundle")
            return
        }

        guard let settings = NSDictionary(contentsOf: settingsBundle.appendingPathComponent("Root.plist")) else {
            print("Could not find settings dictionary")
            return
        }
        let preferences = settings["PreferenceSpecifiers"] as? [[AnyHashable : Any]]

        var defaultsToRegister = [AnyHashable : Any]()
        for prefSpecification: [AnyHashable : Any] in preferences ?? [] {
            let key = prefSpecification["Key"] as? String
            if key != nil {
                defaultsToRegister[key] = prefSpecification["DefaultValue"]
            }
        }

        if let aRegister = defaultsToRegister as? [String : Any] {
            UserDefaults.standard.register(defaults: aRegister)
        }

        if UserDefaults.standard.integer(forKey: Constant.secondsInBackgroundKey()) == 0 {
            UserDefaults.standard.set(Constant.sessionInBackgroundDefaultTimeInSeconds(), forKey: Constant.secondsInBackgroundKey())
        }

        if UserDefaults.standard.float(forKey: Constant.distantAnchorsDistanceKey()) == 0.0 {
            UserDefaults.standard.set(Constant.distantAnchorsDefaultDistanceInMeters(), forKey: Constant.distantAnchorsDistanceKey())
        }
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        //Be ready to open URLs like "wxrv://ios-viewer.webxrexperiments.com/viewer.html"
        if (url.scheme == "wxrv") {
            // Extract the scheme part of the URL
            let absoluteString = url.absoluteString
            let index = absoluteString.index(absoluteString.startIndex, offsetBy: 7)
            var urlString = String(absoluteString.suffix(from: index))
            urlString = "https://\(urlString)"

            DDLogDebug("WebXR-iOS viewer opened with URL: \(urlString)")
            UserDefaults.standard.set(urlString, forKey: REQUESTED_URL_KEY)

            return true
        }
        return false
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        AnalyticsManager.sharedInstance.sendEvent(category: EventCategory.action, method: EventMethod.foreground, object: EventObject.app)
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        AnalyticsManager.sharedInstance.sendEvent(category: EventCategory.action, method: EventMethod.background, object: EventObject.app)
    }
}
