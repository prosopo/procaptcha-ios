import SwiftUI
import WebKit

struct WebView: UIViewRepresentable {
    let url: URL
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        let request = URLRequest(url: url)
        webView.load(request)
        
        
        // Inject JavaScript to redirect console.log to the user content controller
        let scriptSource = """
        window.console.log = (function(log) {
            return function() {
                var message = Array.from(arguments).join(' ');
                log.apply(console, arguments);
                window.webkit.messageHandlers.consoleLog.postMessage(message); // Send message to Swift
            }
        })(console.log);
        """

        let script = WKUserScript(source: scriptSource, injectionTime: .atDocumentStart, forMainFrameOnly: false)
        userContentController.addUserScript(script) // Add the script to the user content controller
        
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        // Handle any updates to the view if necessary
    }

    class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        var parent: WebView
        
        init(_ parent: WebView) {
            self.parent = parent
        }
        
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            if message.name == "consoleLog", let messageBody = message.body as? String {
                print("JavaScript Console: \(messageBody)") // Print console logs to Xcode console
            }
        }
        
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
            WebView(url: URL(string: "https://prosopo.io")!)
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
