import SwiftUI
import WebKit

struct WebView: UIViewRepresentable {
    let htmlString: String
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }
    
    func makeUIView(context: Context) -> WKWebView {
        let webViewConfiguration = WKWebViewConfiguration()
        webViewConfiguration.preferences.javaScriptEnabled = true

        // Set up user content controller for message handling (logging)
        let userContentController = WKUserContentController()
        userContentController.add(context.coordinator, name: "consoleLog")

        // Inject JavaScript to override console.log
        let scriptSource = """
        window.console.log = (function(log) {
            return function() {
                var message = Array.from(arguments).join(' ');
                log.apply(console, arguments);
                window.webkit.messageHandlers.consoleLog.postMessage(message);
            }
        })(console.log);
        """
        
        let script = WKUserScript(source: scriptSource, injectionTime: .atDocumentStart, forMainFrameOnly: false)
        userContentController.addUserScript(script)
        
        // Add the user content controller to the configuration
        webViewConfiguration.userContentController = userContentController
        
        let webView = WKWebView(frame: .zero, configuration: webViewConfiguration)
        webView.navigationDelegate = context.coordinator
        
        // Load the provided HTML string
        webView.loadHTMLString(htmlString, baseURL: nil)
        
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        // Handle any updates if necessary
    }
    
    class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        var parent: WebView
        
        init(_ parent: WebView) {
            self.parent = parent
        }
        
        // This is where JavaScript messages are received
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            if message.name == "consoleLog", let messageBody = message.body as? String {
                print("JavaScript Console: \(messageBody)") // Log to Xcode console
            }
        }
        
        // Handle navigation actions
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            if navigationAction.navigationType == .linkActivated {
                decisionHandler(.cancel)
            } else {
                decisionHandler(.allow)
            }
        }
    }
}

struct ContentView: View {
    var body: some View {
        VStack {
            WebView(htmlString: """
            <html>
                <head>
                    <title>Procaptcha Demo</title>
                    <script type="module" src="https://js.prosopo.io/js/procaptcha.bundle.js" async defer></script>
                </head>
                <body>
                    <form action="" method="POST">
                        <input type="text" name="email" placeholder="Email" />
                        <input type="password" name="password" placeholder="Password" />
                        <div class="procaptcha" data-sitekey="5FWCbfR7pH9QiZqLgmm5Rw4QbFwyU5EaMqUV4G6xrvrTZDtC
"></div>
                        <br />
                        <input type="submit" value="Submit" />
                    </form>
                </body>
            </html>
                """)
            // WebView(url: URL(string: "https://prosopo.io")!)
                .frame(height: 400)
            
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundColor(.accentColor)
            Text("Hello, world!")
        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
