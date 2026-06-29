import SwiftUI
import WebKit

struct WebView: NSViewRepresentable {
    // The web app is online-only (live market data), so load it from its https origin —
    // this guarantees localStorage / fetch / WebSocket behave exactly as in a browser.
    // Pushing changes to the live site updates this app automatically (no rebuild).
    static let appURL = URL(string: "https://danielhagever.github.io/tvsignals/")!

    func makeNSView(context: Context) -> WKWebView {
        let cfg = WKWebViewConfiguration()
        cfg.defaultWebpagePreferences.allowsContentJavaScript = true
        cfg.websiteDataStore = .default()   // persistent localStorage across launches
        let wv = WKWebView(frame: .zero, configuration: cfg)
        if #available(macOS 13.3, *) { wv.isInspectable = true }   // allow Safari Web Inspector
        wv.setValue(false, forKey: "drawsBackground")
        // Always pull a fresh copy of the page so pushed web changes show up immediately
        // (GitHub Pages sends a 10-min cache header that WKWebView would otherwise honor).
        wv.load(URLRequest(url: WebView.appURL, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 30))
        return wv
    }
    func updateNSView(_ nsView: WKWebView, context: Context) {}
}
