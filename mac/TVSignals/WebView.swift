import SwiftUI
import WebKit

struct WebView: NSViewRepresentable {
    // The web app is online-only (live market data), so load it from its https origin —
    // this guarantees localStorage / fetch / WebSocket behave exactly as in a browser.
    static let appURL = URL(string: "https://danielhagever.github.io/tvsignals/")!

    func makeNSView(context: Context) -> WKWebView {
        let cfg = WKWebViewConfiguration()
        cfg.defaultWebpagePreferences.allowsContentJavaScript = true
        cfg.websiteDataStore = .default()   // persistent localStorage
        let wv = WKWebView(frame: .zero, configuration: cfg)
        wv.setValue(false, forKey: "drawsBackground")
        wv.load(URLRequest(url: WebView.appURL))
        return wv
    }
    func updateNSView(_ nsView: WKWebView, context: Context) {}
}
