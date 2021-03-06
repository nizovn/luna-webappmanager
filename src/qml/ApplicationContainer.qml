/*
 * Copyright (C) 2013 Simon Busch <morphis@gravedo.de>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>
 */

import QtQuick 2.0
import QtWebKit 3.0
import QtWebKit.experimental 1.0
import "extensionmanager.js" as ExtensionManager
import LunaNext.Common 0.1
import LuneOS.Components 1.0
import Connman 0.2
import "."

Flickable {
   id: webViewContainer

   anchors.fill: parent

   property int numRestarts: 0
   property int maxRestarts: 3

   NetworkManager {
       id: networkManager

       property string oldState: "unknown"

       onStateChanged: {
           // When we are online again reload the web view in order to start the application
           // which is still visible to the user
           if (webApp.internetConnectivityRequired &&
               oldState !== networkManager.state &&
               networkManager.state === "online")
               webView.reload();
       }
   }

    Rectangle {
        id: offlinePanel

        color: "white"
        visible: webApp.internetConnectivityRequired && networkManager.state !== "online"
        anchors.fill: parent

        z: 10

        Text {
            anchors.centerIn: parent
            color: "black"
            text: "Internet connectivity is required but not available"
            font.pixelSize: 20
            font.family: "Prelude"
        }
    }

    Component.onCompleted: {
        if (webApp.isLauncher())
            return;

        webViewLoader.sourceComponent = webViewComponent;
    }

    Loader {
        id: webViewLoader
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: keyboardContainer.top
    }

    Connections {
        target: webAppWindow
        onVisibleChanged: {
            if (!webApp.isLauncher())
                return;

            if (!webAppWindow.visible)
                return;

            if (webViewLoader.sourceComponent !== null)
                return;

            webViewLoader.sourceComponent = webViewComponent;
        }
    }

    Component {
        id: webViewComponent

        WebView {
            id: webView
            objectName: "webView"

            function _updateWebViewSize() {
                    webView.experimental.evaluateJavaScript("if (window.Mojo && window.Mojo.keyboardShown) {" +
                                                            "window.Mojo.keyboardShown(" + Qt.inputMethod.visible + ");}");

                    var positiveSpace = {
                        width: webViewContainer.width,
                        height: webViewContainer.height - (Qt.inputMethod ? Qt.inputMethod.keyboardRectangle.height : 0)
                    };

                    webView.experimental.evaluateJavaScript("if (window.Mojo && window.Mojo.positiveSpaceChanged) {" +
                                                            "window.Mojo.positiveSpaceChanged(" + positiveSpace.width +
                                                            "," + positiveSpace.height + ");}");

                    if (Qt.inputMethod.visible && webAppWindow.focus)
                        keyboardContainer.height = Qt.inputMethod.keyboardRectangle.height;
                    else
                        keyboardContainer.height = 0;
            }

            Connections {
                target: Qt.inputMethod
                onVisibleChanged: _updateWebViewSize();
                onKeyboardRectangleChanged: _updateWebViewSize();
            }

            UserAgent {
                id: userAgent
            }

            experimental.preferences.navigatorQtObjectEnabled: true
            experimental.preferences.localStorageEnabled: true
            experimental.preferences.offlineWebApplicationCacheEnabled: true
            experimental.preferences.webGLEnabled: true
            experimental.preferences.developerExtrasEnabled: true

            experimental.preferences.standardFontFamily: "Prelude"
            experimental.preferences.fixedFontFamily: "Courier new"
            experimental.preferences.serifFontFamily: "Times New Roman"
            experimental.preferences.cursiveFontFamily: "Prelude"

            experimental.transparentBackground: (webAppWindow.windowType === "dashboard" ||
                                                 webAppWindow.windowType === "popupalert")

            experimental.databaseQuotaDialog: Item {
                Component.onCompleted: {
                    console.log("Database quota extension request:");
                    console.log(" databaseName: " + model.databaseName);
                    console.log(" displayName: " + model.displayName);
                    console.log(" currentQuota: " + model.currentQuota);
                    console.log(" currentOriginUsage: " + model.currentOriginUsage);
                    console.log(" expectedUsage: " + model.expectedUsage);
                    console.log(" securityOrigin:");
                    console.log("   scheme: " + model.securityOrigin.scheme);
                    console.log("   host: " + model.securityOrigin.host);
                    console.log("   port: " + model.securityOrigin.port);

                    // we allow 5 MB for now
                    model.accept(5 * 1024 * 1024);
                }
            }

            function getUserAgentForApp(url) {
                /* if the app wants a specific user agent assign it instead of the default one */
                if (webApp.userAgent.length > 0)
                    return webApp.userAgent;

                return userAgent.defaultUA;
            }

            experimental.userAgent: getUserAgentForApp(null)

            experimental.authenticationDialog: AuthenticationDialog {
                serverURL: webView.url
                hostname: model.hostname
                onAccepted: {
                    //TODO: Need to implement password manager using KeyManager where possible
                    if (savePwd) {
                        //TODO Function to call and do the password management
                    }
                    model.accept(username, pass);
                }
            }
            experimental.certificateVerificationDialog: CertDialog {
                onViewCertificate: { /*TODO*/ }
                onTrust: {
                    model.accept();
                    if(always) { /*TODO*/ }
                }
                onReject: {
                    model.reject();
                    webview.stop();
                }
            }
            experimental.proxyAuthenticationDialog: ProxyAuthenticationDialog {
                hostname: model.hostname
                port: model.port
                onAccepted: {
                    //TODO: Need to implement password manager using KeyManager where possible
                    if (savePwd) {
                        //TODO Function to call and do the password management
                    }
                    model.accept(username, pass);
                }
            }
            experimental.alertDialog: AlertDialog {
                message: model.message
                onAccepted: model.dismiss();
            }
            experimental.confirmDialog: ConfirmDialog {
                message: model.message
                onAccepted: model.accept();
                onRejected: model.reject();
            }
            experimental.promptDialog: PromptDialog {
                message: model.message
                defaultValue: model.defaultValue
                onAccepted: model.accept(input.text);
                onRejected: model.reject();
            }
            experimental.filePicker: FilePicker {
                fileModel: model
            }
            experimental.itemSelector: ItemSelector {
                selectorModel: model;
            }

            onNavigationRequested: {
                var action = WebView.AcceptRequest;
                var url = request.url.toString();

                if (webApp.urlsAllowed && webApp.urlsAllowed.length !== 0) {
                    action = WebView.IgnoreRequest;
                    for (var i = 0; i < webApp.urlsAllowed.length; ++i) {
                        var pattern = webApp.urlsAllowed[i];
                        if (url.match(pattern)) {
                            action = WebView.AcceptRequest;
                            break;
                        }
                    }
                }

                request.action = action;

                // If we're not handling the URL forward it to be opened within the system
                // default web browser in a safe environment
                if (request.action === WebView.IgnoreRequest) {
                    Qt.openUrlExternally(url);
                    return;
                }

                webView.experimental.userAgent = getUserAgentForApp(url);
            }

            Component.onCompleted: {
                // Let the native side configure us as needed
                webAppWindow.configureWebView(webView);

                // Only when we have a system application we enable the webOS API and the
                // PalmServiceBridge to avoid remote applications accessing unwanted system
                // internals
                if (webAppWindow.trustScope === "system") {
                    if (experimental.hasOwnProperty('userScriptsInjectAtStart') &&
                        experimental.hasOwnProperty('userScriptsForAllFrames')) {
                        experimental.userScripts = webAppWindow.userScripts;
                        experimental.userScriptsInjectAtStart = true;
                        experimental.userScriptsForAllFrames = true;
                    }

                    if (experimental.preferences.hasOwnProperty("palmServiceBridgeEnabled"))
                        experimental.preferences.palmServiceBridgeEnabled = true;

                    if (experimental.preferences.hasOwnProperty("privileged"))
                        experimental.preferences.privileged = webApp.privileged;

                    if (experimental.preferences.hasOwnProperty("identifier"))
                        experimental.preferences.identifier = webApp.identifier;

                    if (webApp.allowCrossDomainAccess) {
                        if (experimental.preferences.hasOwnProperty("appRuntime"))
                            experimental.preferences.appRuntime = false;

                        experimental.preferences.universalAccessFromFileURLsAllowed = true;
                        experimental.preferences.fileAccessFromFileURLsAllowed = true;
                    }
                    else {
                        if (experimental.preferences.hasOwnProperty("appRuntime"))
                            experimental.preferences.appRuntime = true;

                        experimental.preferences.universalAccessFromFileURLsAllowed = false;
                        experimental.preferences.fileAccessFromFileURLsAllowed = false;
                    }
                }

                if (experimental.preferences.hasOwnProperty("logsPageMessagesToSystemConsole"))
                    experimental.preferences.logsPageMessagesToSystemConsole = true;

                if (experimental.preferences.hasOwnProperty("suppressIncrementalRendering"))
                    experimental.preferences.suppressIncrementalRendering = true;
            }

            experimental.onMessageReceived: {
                ExtensionManager.messageHandler(message);
            }

            Connections {
                target: webAppWindow

                onJavaScriptExecNeeded: {
                    webView.experimental.evaluateJavaScript(script);
                }

                onExtensionWantsToBeAdded: {
                    ExtensionManager.addExtension(name, object);
                }
            }

            Connections {
                target: webView.experimental
                onProcessDidCrash: {
                    if (numRestarts < maxRestarts) {
                        console.log("ERROR: The web process has crashed. Restart it ...");
                        webView.url = webAppWindow.url;
                        webView.reload();
                        numRestarts += 1;
                    }
                    else {
                        console.log("CRITICAL: restarted application " + numRestarts
                                    + " times. Closing it now");
                        Qt.quit();
                    }
                }
            }
        }
    }

    Item {
        id: keyboardContainer
        height: 0
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
    }
}
