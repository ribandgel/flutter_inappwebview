import 'dart:io';
import 'dart:async';
import 'dart:collection';
import 'dart:typed_data';
import 'dart:convert';
import 'dart:core';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'android/in_app_webview_controller.dart';
import 'ios/in_app_webview_controller.dart';

import '../context_menu.dart';
import '../types.dart';
import '../in_app_browser/in_app_browser.dart';
import '../web_storage/web_storage.dart';
import '../util.dart';

import 'headless_in_app_webview.dart';
import 'in_app_webview.dart';
import 'in_app_webview_options.dart';
import 'webview.dart';
import '_static_channel.dart';

///List of forbidden names for JavaScript handlers.
// ignore: non_constant_identifier_names
final _JAVASCRIPT_HANDLER_FORBIDDEN_NAMES = UnmodifiableListView<String>([
  "onLoadResource",
  "shouldInterceptAjaxRequest",
  "onAjaxReadyStateChange",
  "onAjaxProgress",
  "shouldInterceptFetchRequest",
  "onPrint",
  "onWindowFocus",
  "onWindowBlur",
  "callAsyncJavaScript",
  "evaluateJavaScriptWithContentWorld"
]);

///Controls a WebView, such as an [InAppWebView] widget instance, a [HeadlessInAppWebView] instance or [InAppBrowser] WebView instance.
///
///If you are using the [InAppWebView] widget, an [InAppWebViewController] instance can be obtained by setting the [InAppWebView.onWebViewCreated]
///callback. Instead, if you are using an [InAppBrowser] instance, you can get it through the [InAppBrowser.webViewController] attribute.
class InAppWebViewController {
  WebView? _webview;
  late MethodChannel _channel;
  static MethodChannel _staticChannel = IN_APP_WEBVIEW_STATIC_CHANNEL;
  Map<String, JavaScriptHandlerCallback> javaScriptHandlersMap =
      HashMap<String, JavaScriptHandlerCallback>();
  List<UserScript> _userScripts = [];

  // ignore: unused_field
  dynamic _id;

  InAppBrowser? _inAppBrowser;

  ///Android controller that contains only android-specific methods
  late AndroidInAppWebViewController android;

  ///iOS controller that contains only ios-specific methods
  late IOSInAppWebViewController ios;

  ///Provides access to the JavaScript [Web Storage API](https://developer.mozilla.org/en-US/docs/Web/API/Web_Storage_API): `window.sessionStorage` and `window.localStorage`.
  late WebStorage webStorage;

  InAppWebViewController(dynamic id, WebView webview) {
    this._id = id;
    this._channel =
        MethodChannel('com.pichillilorenzo/flutter_inappwebview_$id');
    this._channel.setMethodCallHandler(handleMethod);
    this._webview = webview;
    this._userScripts =
        List<UserScript>.from(webview.initialUserScripts ?? <UserScript>[]);
    this._init();
  }

  InAppWebViewController.fromInAppBrowser(
      MethodChannel channel,
      InAppBrowser inAppBrowser,
      UnmodifiableListView<UserScript>? initialUserScripts) {
    this._channel = channel;
    this._inAppBrowser = inAppBrowser;
    this._userScripts =
        List<UserScript>.from(initialUserScripts ?? <UserScript>[]);
    this._init();
  }

  void _init() {
    this.android = AndroidInAppWebViewController(channel: _channel);
    this.ios = IOSInAppWebViewController(channel: _channel);
    this.webStorage = WebStorage(
        localStorage: LocalStorage(this), sessionStorage: SessionStorage(this));
  }

  Future<dynamic> handleMethod(MethodCall call) async {
    switch (call.method) {
      case "onHeadlessWebViewCreated":
        if (_webview != null &&
            _webview is HeadlessInAppWebView &&
            _webview!.onWebViewCreated != null)
          _webview!.onWebViewCreated!(this);
        break;
      case "onLoadStart":
        if ((_webview != null && _webview!.onLoadStart != null) ||
            _inAppBrowser != null) {
          String? url = call.arguments["url"];
          Uri? uri = url != null ? Uri.parse(url) : null;
          if (_webview != null && _webview!.onLoadStart != null)
            _webview!.onLoadStart!(this, uri);
          else
            _inAppBrowser!.onLoadStart(uri);
        }
        break;
      case "onLoadStop":
        if ((_webview != null && _webview!.onLoadStop != null) ||
            _inAppBrowser != null) {
          String? url = call.arguments["url"];
          Uri? uri = url != null ? Uri.parse(url) : null;
          if (_webview != null && _webview!.onLoadStop != null)
            _webview!.onLoadStop!(this, uri);
          else
            _inAppBrowser!.onLoadStop(uri);
        }
        break;
      case "onLoadError":
        if ((_webview != null && _webview!.onLoadError != null) ||
            _inAppBrowser != null) {
          String? url = call.arguments["url"];
          int code = call.arguments["code"];
          String message = call.arguments["message"];
          Uri? uri = url != null ? Uri.parse(url) : null;
          if (_webview != null && _webview!.onLoadError != null)
            _webview!.onLoadError!(this, uri, code, message);
          else
            _inAppBrowser!.onLoadError(uri, code, message);
        }
        break;
      case "onLoadHttpError":
        if ((_webview != null && _webview!.onLoadHttpError != null) ||
            _inAppBrowser != null) {
          String? url = call.arguments["url"];
          int statusCode = call.arguments["statusCode"];
          String description = call.arguments["description"];
          Uri? uri = url != null ? Uri.parse(url) : null;
          if (_webview != null && _webview!.onLoadHttpError != null)
            _webview!.onLoadHttpError!(this, uri, statusCode, description);
          else
            _inAppBrowser!.onLoadHttpError(uri, statusCode, description);
        }
        break;
      case "onProgressChanged":
        if ((_webview != null && _webview!.onProgressChanged != null) ||
            _inAppBrowser != null) {
          int progress = call.arguments["progress"];
          if (_webview != null && _webview!.onProgressChanged != null)
            _webview!.onProgressChanged!(this, progress);
          else
            _inAppBrowser!.onProgressChanged(progress);
        }
        break;
      case "shouldOverrideUrlLoading":
        if ((_webview != null && _webview!.shouldOverrideUrlLoading != null) ||
            _inAppBrowser != null) {
          Map<String, dynamic> arguments =
              call.arguments.cast<String, dynamic>();
          NavigationAction navigationAction =
              NavigationAction.fromMap(arguments)!;

          if (_webview != null && _webview!.shouldOverrideUrlLoading != null)
            return (await _webview!.shouldOverrideUrlLoading!(
                    this, navigationAction))
                ?.toMap();
          return (await _inAppBrowser!
                  .shouldOverrideUrlLoading(navigationAction))
              ?.toMap();
        }
        break;
      case "onConsoleMessage":
        if ((_webview != null && _webview!.onConsoleMessage != null) ||
            _inAppBrowser != null) {
          Map<String, dynamic> arguments =
              call.arguments.cast<String, dynamic>();
          ConsoleMessage consoleMessage = ConsoleMessage.fromMap(arguments)!;
          if (_webview != null && _webview!.onConsoleMessage != null)
            _webview!.onConsoleMessage!(this, consoleMessage);
          else
            _inAppBrowser!.onConsoleMessage(consoleMessage);
        }
        break;
      case "onScrollChanged":
        if ((_webview != null && _webview!.onScrollChanged != null) ||
            _inAppBrowser != null) {
          int x = call.arguments["x"];
          int y = call.arguments["y"];
          if (_webview != null && _webview!.onScrollChanged != null)
            _webview!.onScrollChanged!(this, x, y);
          else
            _inAppBrowser!.onScrollChanged(x, y);
        }
        break;
      case "onDownloadStart":
        if ((_webview != null && _webview!.onDownloadStart != null) ||
            _inAppBrowser != null) {
          String url = call.arguments["url"];
          Uri uri = Uri.parse(url);
          if (_webview != null && _webview!.onDownloadStart != null)
            _webview!.onDownloadStart!(this, uri);
          else
            _inAppBrowser!.onDownloadStart(uri);
        }
        break;
      case "onLoadResourceCustomScheme":
        if ((_webview != null &&
                _webview!.onLoadResourceCustomScheme != null) ||
            _inAppBrowser != null) {
          String url = call.arguments["url"];
          Uri uri = Uri.parse(url);
          if (_webview != null && _webview!.onLoadResourceCustomScheme != null)
            return (await _webview!.onLoadResourceCustomScheme!(this, uri))
                ?.toMap();
          else
            return (await _inAppBrowser!.onLoadResourceCustomScheme(uri))
                ?.toMap();
        }
        break;
      case "onCreateWindow":
        if ((_webview != null && _webview!.onCreateWindow != null) ||
            _inAppBrowser != null) {
          Map<String, dynamic> arguments =
              call.arguments.cast<String, dynamic>();
          CreateWindowAction createWindowAction =
              CreateWindowAction.fromMap(arguments)!;

          if (_webview != null && _webview!.onCreateWindow != null)
            return await _webview!.onCreateWindow!(this, createWindowAction);
          else
            return await _inAppBrowser!.onCreateWindow(createWindowAction);
        }
        break;
      case "onCloseWindow":
        if (_webview != null && _webview!.onCloseWindow != null)
          _webview!.onCloseWindow!(this);
        else if (_inAppBrowser != null) _inAppBrowser!.onCloseWindow();
        break;
      case "onTitleChanged":
        if ((_webview != null && _webview!.onTitleChanged != null) ||
            _inAppBrowser != null) {
          String? title = call.arguments["title"];
          if (_webview != null && _webview!.onTitleChanged != null)
            _webview!.onTitleChanged!(this, title);
          else
            _inAppBrowser!.onTitleChanged(title);
        }
        break;
      case "onGeolocationPermissionsShowPrompt":
        if ((_webview != null &&
                _webview!.androidOnGeolocationPermissionsShowPrompt != null) ||
            _inAppBrowser != null) {
          String origin = call.arguments["origin"];
          if (_webview != null &&
              _webview!.androidOnGeolocationPermissionsShowPrompt != null)
            return (await _webview!.androidOnGeolocationPermissionsShowPrompt!(
                    this, origin))
                ?.toMap();
          else
            return (await _inAppBrowser!
                    .androidOnGeolocationPermissionsShowPrompt(origin))
                ?.toMap();
        }
        break;
      case "onGeolocationPermissionsHidePrompt":
        if (_webview != null &&
            _webview!.androidOnGeolocationPermissionsHidePrompt != null)
          _webview!.androidOnGeolocationPermissionsHidePrompt!(this);
        else if (_inAppBrowser != null)
          _inAppBrowser!.androidOnGeolocationPermissionsHidePrompt();
        break;
      case "shouldInterceptRequest":
        if ((_webview != null &&
                _webview!.androidShouldInterceptRequest != null) ||
            _inAppBrowser != null) {
          Map<String, dynamic> arguments =
              call.arguments.cast<String, dynamic>();
          WebResourceRequest request = WebResourceRequest.fromMap(arguments)!;

          if (_webview != null &&
              _webview!.androidShouldInterceptRequest != null)
            return (await _webview!.androidShouldInterceptRequest!(
                    this, request))
                ?.toMap();
          else
            return (await _inAppBrowser!.androidShouldInterceptRequest(request))
                ?.toMap();
        }
        break;
      case "onRenderProcessUnresponsive":
        if ((_webview != null &&
                _webview!.androidOnRenderProcessUnresponsive != null) ||
            _inAppBrowser != null) {
          String? url = call.arguments["url"];
          Uri? uri = url != null ? Uri.parse(url) : null;
          if (_webview != null &&
              _webview!.androidOnRenderProcessUnresponsive != null)
            return (await _webview!.androidOnRenderProcessUnresponsive!(
                    this, uri))
                ?.toMap();
          else
            return (await _inAppBrowser!
                    .androidOnRenderProcessUnresponsive(uri))
                ?.toMap();
        }
        break;
      case "onRenderProcessResponsive":
        if ((_webview != null &&
                _webview!.androidOnRenderProcessResponsive != null) ||
            _inAppBrowser != null) {
          String? url = call.arguments["url"];
          Uri? uri = url != null ? Uri.parse(url) : null;
          if (_webview != null &&
              _webview!.androidOnRenderProcessResponsive != null)
            return (await _webview!.androidOnRenderProcessResponsive!(
                    this, uri))
                ?.toMap();
          else
            return (await _inAppBrowser!.androidOnRenderProcessResponsive(uri))
                ?.toMap();
        }
        break;
      case "onRenderProcessGone":
        if ((_webview != null &&
                _webview!.androidOnRenderProcessGone != null) ||
            _inAppBrowser != null) {
          Map<String, dynamic> arguments =
              call.arguments.cast<String, dynamic>();
          RenderProcessGoneDetail detail =
              RenderProcessGoneDetail.fromMap(arguments)!;

          if (_webview != null && _webview!.androidOnRenderProcessGone != null)
            _webview!.androidOnRenderProcessGone!(this, detail);
          else
            _inAppBrowser!.androidOnRenderProcessGone(detail);
        }
        break;
      case "onFormResubmission":
        if ((_webview != null && _webview!.androidOnFormResubmission != null) ||
            _inAppBrowser != null) {
          String? url = call.arguments["url"];
          Uri? uri = url != null ? Uri.parse(url) : null;
          if (_webview != null && _webview!.androidOnFormResubmission != null)
            return (await _webview!.androidOnFormResubmission!(this, uri))
                ?.toMap();
          else
            return (await _inAppBrowser!.androidOnFormResubmission(uri))
                ?.toMap();
        }
        break;
      case "onScaleChanged":
        if ((_webview != null && _webview!.androidOnScaleChanged != null) ||
            _inAppBrowser != null) {
          double oldScale = call.arguments["oldScale"];
          double newScale = call.arguments["newScale"];
          if (_webview != null && _webview!.androidOnScaleChanged != null)
            _webview!.androidOnScaleChanged!(this, oldScale, newScale);
          else
            _inAppBrowser!.androidOnScaleChanged(oldScale, newScale);
        }
        break;
      case "onReceivedIcon":
        if ((_webview != null && _webview!.androidOnReceivedIcon != null) ||
            _inAppBrowser != null) {
          Uint8List icon =
              Uint8List.fromList(call.arguments["icon"].cast<int>());

          if (_webview != null && _webview!.androidOnReceivedIcon != null)
            _webview!.androidOnReceivedIcon!(this, icon);
          else
            _inAppBrowser!.androidOnReceivedIcon(icon);
        }
        break;
      case "onReceivedTouchIconUrl":
        if ((_webview != null &&
                _webview!.androidOnReceivedTouchIconUrl != null) ||
            _inAppBrowser != null) {
          String url = call.arguments["url"];
          bool precomposed = call.arguments["precomposed"];
          Uri uri = Uri.parse(url);
          if (_webview != null &&
              _webview!.androidOnReceivedTouchIconUrl != null)
            _webview!.androidOnReceivedTouchIconUrl!(this, uri, precomposed);
          else
            _inAppBrowser!.androidOnReceivedTouchIconUrl(uri, precomposed);
        }
        break;
      case "onJsAlert":
        if ((_webview != null && _webview!.onJsAlert != null) ||
            _inAppBrowser != null) {
          Map<String, dynamic> arguments =
              call.arguments.cast<String, dynamic>();
          JsAlertRequest jsAlertRequest = JsAlertRequest.fromMap(arguments)!;

          if (_webview != null && _webview!.onJsAlert != null)
            return (await _webview!.onJsAlert!(this, jsAlertRequest))?.toMap();
          else
            return (await _inAppBrowser!.onJsAlert(jsAlertRequest))?.toMap();
        }
        break;
      case "onJsConfirm":
        if ((_webview != null && _webview!.onJsConfirm != null) ||
            _inAppBrowser != null) {
          Map<String, dynamic> arguments =
              call.arguments.cast<String, dynamic>();
          JsConfirmRequest jsConfirmRequest =
              JsConfirmRequest.fromMap(arguments)!;

          if (_webview != null && _webview!.onJsConfirm != null)
            return (await _webview!.onJsConfirm!(this, jsConfirmRequest))
                ?.toMap();
          else
            return (await _inAppBrowser!.onJsConfirm(jsConfirmRequest))
                ?.toMap();
        }
        break;
      case "onJsPrompt":
        if ((_webview != null && _webview!.onJsPrompt != null) ||
            _inAppBrowser != null) {
          Map<String, dynamic> arguments =
              call.arguments.cast<String, dynamic>();
          JsPromptRequest jsPromptRequest = JsPromptRequest.fromMap(arguments)!;

          if (_webview != null && _webview!.onJsPrompt != null)
            return (await _webview!.onJsPrompt!(this, jsPromptRequest))
                ?.toMap();
          else
            return (await _inAppBrowser!.onJsPrompt(jsPromptRequest))?.toMap();
        }
        break;
      case "onJsBeforeUnload":
        if ((_webview != null && _webview!.androidOnJsBeforeUnload != null) ||
            _inAppBrowser != null) {
          Map<String, dynamic> arguments =
              call.arguments.cast<String, dynamic>();
          JsBeforeUnloadRequest jsBeforeUnloadRequest =
              JsBeforeUnloadRequest.fromMap(arguments)!;

          if (_webview != null && _webview!.androidOnJsBeforeUnload != null)
            return (await _webview!.androidOnJsBeforeUnload!(
                    this, jsBeforeUnloadRequest))
                ?.toMap();
          else
            return (await _inAppBrowser!
                    .androidOnJsBeforeUnload(jsBeforeUnloadRequest))
                ?.toMap();
        }
        break;
      case "onSafeBrowsingHit":
        if ((_webview != null && _webview!.androidOnSafeBrowsingHit != null) ||
            _inAppBrowser != null) {
          String url = call.arguments["url"];
          SafeBrowsingThreat? threatType =
              SafeBrowsingThreat.fromValue(call.arguments["threatType"]);
          Uri uri = Uri.parse(url);
          if (_webview != null && _webview!.androidOnSafeBrowsingHit != null)
            return (await _webview!.androidOnSafeBrowsingHit!(
                    this, uri, threatType))
                ?.toMap();
          else
            return (await _inAppBrowser!
                    .androidOnSafeBrowsingHit(uri, threatType))
                ?.toMap();
        }
        break;
      case "onReceivedLoginRequest":
        if ((_webview != null &&
                _webview!.androidOnReceivedLoginRequest != null) ||
            _inAppBrowser != null) {
          Map<String, dynamic> arguments =
              call.arguments.cast<String, dynamic>();
          LoginRequest loginRequest = LoginRequest.fromMap(arguments)!;

          if (_webview != null &&
              _webview!.androidOnReceivedLoginRequest != null)
            _webview!.androidOnReceivedLoginRequest!(this, loginRequest);
          else
            _inAppBrowser!.androidOnReceivedLoginRequest(loginRequest);
        }
        break;
      case "onReceivedHttpAuthRequest":
        if ((_webview != null && _webview!.onReceivedHttpAuthRequest != null) ||
            _inAppBrowser != null) {
          Map<String, dynamic> arguments =
              call.arguments.cast<String, dynamic>();
          HttpAuthenticationChallenge challenge =
              HttpAuthenticationChallenge.fromMap(arguments)!;

          if (_webview != null && _webview!.onReceivedHttpAuthRequest != null)
            return (await _webview!.onReceivedHttpAuthRequest!(this, challenge))
                ?.toMap();
          else
            return (await _inAppBrowser!.onReceivedHttpAuthRequest(challenge))
                ?.toMap();
        }
        break;
      case "onReceivedServerTrustAuthRequest":
        if ((_webview != null &&
                _webview!.onReceivedServerTrustAuthRequest != null) ||
            _inAppBrowser != null) {
          Map<String, dynamic> arguments =
              call.arguments.cast<String, dynamic>();
          ServerTrustChallenge challenge =
              ServerTrustChallenge.fromMap(arguments)!;

          if (_webview != null &&
              _webview!.onReceivedServerTrustAuthRequest != null)
            return (await _webview!.onReceivedServerTrustAuthRequest!(
                    this, challenge))
                ?.toMap();
          else
            return (await _inAppBrowser!
                    .onReceivedServerTrustAuthRequest(challenge))
                ?.toMap();
        }
        break;
      case "onReceivedClientCertRequest":
        if ((_webview != null &&
                _webview!.onReceivedClientCertRequest != null) ||
            _inAppBrowser != null) {
          Map<String, dynamic> arguments =
              call.arguments.cast<String, dynamic>();
          ClientCertChallenge challenge =
              ClientCertChallenge.fromMap(arguments)!;

          if (_webview != null && _webview!.onReceivedClientCertRequest != null)
            return (await _webview!.onReceivedClientCertRequest!(
                    this, challenge))
                ?.toMap();
          else
            return (await _inAppBrowser!.onReceivedClientCertRequest(challenge))
                ?.toMap();
        }
        break;
      case "onFindResultReceived":
        if ((_webview != null && _webview!.onFindResultReceived != null) ||
            _inAppBrowser != null) {
          int activeMatchOrdinal = call.arguments["activeMatchOrdinal"];
          int numberOfMatches = call.arguments["numberOfMatches"];
          bool isDoneCounting = call.arguments["isDoneCounting"];
          if (_webview != null && _webview!.onFindResultReceived != null)
            _webview!.onFindResultReceived!(
                this, activeMatchOrdinal, numberOfMatches, isDoneCounting);
          else
            _inAppBrowser!.onFindResultReceived(
                activeMatchOrdinal, numberOfMatches, isDoneCounting);
        }
        break;
      case "onPermissionRequest":
        if ((_webview != null &&
                _webview!.androidOnPermissionRequest != null) ||
            _inAppBrowser != null) {
          String origin = call.arguments["origin"];
          List<String> resources = call.arguments["resources"].cast<String>();
          if (_webview != null && _webview!.androidOnPermissionRequest != null)
            return (await _webview!.androidOnPermissionRequest!(
                    this, origin, resources))
                ?.toMap();
          else
            return (await _inAppBrowser!
                    .androidOnPermissionRequest(origin, resources))
                ?.toMap();
        }
        break;
      case "onUpdateVisitedHistory":
        if ((_webview != null && _webview!.onUpdateVisitedHistory != null) ||
            _inAppBrowser != null) {
          String? url = call.arguments["url"];
          bool? androidIsReload = call.arguments["androidIsReload"];
          Uri? uri = url != null ? Uri.parse(url) : null;
          if (_webview != null && _webview!.onUpdateVisitedHistory != null)
            _webview!.onUpdateVisitedHistory!(this, uri, androidIsReload);
          else
            _inAppBrowser!.onUpdateVisitedHistory(uri, androidIsReload);
        }
        break;
      case "onWebContentProcessDidTerminate":
        if (_webview != null &&
            _webview!.iosOnWebContentProcessDidTerminate != null)
          _webview!.iosOnWebContentProcessDidTerminate!(this);
        else if (_inAppBrowser != null)
          _inAppBrowser!.iosOnWebContentProcessDidTerminate();
        break;
      case "onPageCommitVisible":
        if ((_webview != null && _webview!.onPageCommitVisible != null) ||
            _inAppBrowser != null) {
          String? url = call.arguments["url"];
          Uri? uri = url != null ? Uri.parse(url) : null;
          if (_webview != null && _webview!.onPageCommitVisible != null)
            _webview!.onPageCommitVisible!(this, uri);
          else
            _inAppBrowser!.onPageCommitVisible(uri);
        }
        break;
      case "onDidReceiveServerRedirectForProvisionalNavigation":
        if (_webview != null &&
            _webview!.iosOnDidReceiveServerRedirectForProvisionalNavigation !=
                null)
          _webview!
              .iosOnDidReceiveServerRedirectForProvisionalNavigation!(this);
        else if (_inAppBrowser != null)
          _inAppBrowser!
              .iosOnDidReceiveServerRedirectForProvisionalNavigation();
        break;
      case "onNavigationResponse":
        if ((_webview != null && _webview!.iosOnNavigationResponse != null) ||
            _inAppBrowser != null) {
          Map<String, dynamic> arguments =
              call.arguments.cast<String, dynamic>();
          IOSWKNavigationResponse iosOnNavigationResponse =
              IOSWKNavigationResponse.fromMap(arguments)!;

          if (_webview != null && _webview!.iosOnNavigationResponse != null)
            return (await _webview!.iosOnNavigationResponse!(
                    this, iosOnNavigationResponse))
                ?.toMap();
          else
            return (await _inAppBrowser!
                    .iosOnNavigationResponse(iosOnNavigationResponse))
                ?.toMap();
        }
        break;
      case "shouldAllowDeprecatedTLS":
        if ((_webview != null &&
                _webview!.iosShouldAllowDeprecatedTLS != null) ||
            _inAppBrowser != null) {
          Map<String, dynamic> arguments =
              call.arguments.cast<String, dynamic>();
          URLAuthenticationChallenge challenge =
              URLAuthenticationChallenge.fromMap(arguments)!;

          if (_webview != null && _webview!.iosShouldAllowDeprecatedTLS != null)
            return (await _webview!.iosShouldAllowDeprecatedTLS!(
                    this, challenge))
                ?.toMap();
          else
            return (await _inAppBrowser!.iosShouldAllowDeprecatedTLS(challenge))
                ?.toMap();
        }
        break;
      case "onLongPressHitTestResult":
        if ((_webview != null && _webview!.onLongPressHitTestResult != null) ||
            _inAppBrowser != null) {
          Map<String, dynamic> arguments =
              call.arguments.cast<String, dynamic>();
          InAppWebViewHitTestResult hitTestResult =
              InAppWebViewHitTestResult.fromMap(arguments)!;

          if (_webview != null && _webview!.onLongPressHitTestResult != null)
            _webview!.onLongPressHitTestResult!(this, hitTestResult);
          else
            _inAppBrowser!.onLongPressHitTestResult(hitTestResult);
        }
        break;
      case "onCreateContextMenu":
        ContextMenu? contextMenu;
        if (_webview != null && _webview!.contextMenu != null) {
          contextMenu = _webview!.contextMenu;
        } else if (_inAppBrowser != null &&
            _inAppBrowser!.contextMenu != null) {
          contextMenu = _inAppBrowser!.contextMenu;
        }

        if (contextMenu != null && contextMenu.onCreateContextMenu != null) {
          Map<String, dynamic> arguments =
              call.arguments.cast<String, dynamic>();
          InAppWebViewHitTestResult hitTestResult =
              InAppWebViewHitTestResult.fromMap(arguments)!;

          contextMenu.onCreateContextMenu!(hitTestResult);
        }
        break;
      case "onHideContextMenu":
        ContextMenu? contextMenu;
        if (_webview != null && _webview!.contextMenu != null) {
          contextMenu = _webview!.contextMenu;
        } else if (_inAppBrowser != null &&
            _inAppBrowser!.contextMenu != null) {
          contextMenu = _inAppBrowser!.contextMenu;
        }

        if (contextMenu != null && contextMenu.onHideContextMenu != null) {
          contextMenu.onHideContextMenu!();
        }
        break;
      case "onContextMenuActionItemClicked":
        ContextMenu? contextMenu;
        if (_webview != null && _webview!.contextMenu != null) {
          contextMenu = _webview!.contextMenu;
        } else if (_inAppBrowser != null &&
            _inAppBrowser!.contextMenu != null) {
          contextMenu = _inAppBrowser!.contextMenu;
        }

        if (contextMenu != null) {
          int? androidId = call.arguments["androidId"];
          String? iosId = call.arguments["iosId"];
          String title = call.arguments["title"];

          ContextMenuItem menuItemClicked = ContextMenuItem(
              androidId: androidId, iosId: iosId, title: title, action: null);

          for (var menuItem in contextMenu.menuItems) {
            if ((defaultTargetPlatform == TargetPlatform.android &&
                    menuItem.androidId == androidId) ||
                (defaultTargetPlatform == TargetPlatform.iOS &&
                    menuItem.iosId == iosId)) {
              menuItemClicked = menuItem;
              if (menuItem.action != null) {
                menuItem.action!();
              }
              break;
            }
          }

          if (contextMenu.onContextMenuActionItemClicked != null) {
            contextMenu.onContextMenuActionItemClicked!(menuItemClicked);
          }
        }
        break;
      case "onEnterFullscreen":
        if (_webview != null && _webview!.onEnterFullscreen != null)
          _webview!.onEnterFullscreen!(this);
        else if (_inAppBrowser != null) _inAppBrowser!.onEnterFullscreen();
        break;
      case "onExitFullscreen":
        if (_webview != null && _webview!.onExitFullscreen != null)
          _webview!.onExitFullscreen!(this);
        else if (_inAppBrowser != null) _inAppBrowser!.onExitFullscreen();
        break;
      case "onCallJsHandler":
        String handlerName = call.arguments["handlerName"];
        // decode args to json
        List<dynamic> args = jsonDecode(call.arguments["args"]);

        switch (handlerName) {
          case "onLoadResource":
            if ((_webview != null && _webview!.onLoadResource != null) ||
                _inAppBrowser != null) {
              Map<String, dynamic> arguments = args[0].cast<String, dynamic>();
              arguments["startTime"] = arguments["startTime"] is int
                  ? arguments["startTime"].toDouble()
                  : arguments["startTime"];
              arguments["duration"] = arguments["duration"] is int
                  ? arguments["duration"].toDouble()
                  : arguments["duration"];

              var response = LoadedResource.fromMap(arguments)!;

              if (_webview != null && _webview!.onLoadResource != null)
                _webview!.onLoadResource!(this, response);
              else
                _inAppBrowser!.onLoadResource(response);
            }
            return null;
          case "shouldInterceptAjaxRequest":
            if ((_webview != null &&
                    _webview!.shouldInterceptAjaxRequest != null) ||
                _inAppBrowser != null) {
              Map<String, dynamic> arguments = args[0].cast<String, dynamic>();
              AjaxRequest request = AjaxRequest.fromMap(arguments)!;

              if (_webview != null &&
                  _webview!.shouldInterceptAjaxRequest != null)
                return jsonEncode(
                    await _webview!.shouldInterceptAjaxRequest!(this, request));
              else
                return jsonEncode(
                    await _inAppBrowser!.shouldInterceptAjaxRequest(request));
            }
            return null;
          case "onAjaxReadyStateChange":
            if ((_webview != null &&
                    _webview!.onAjaxReadyStateChange != null) ||
                _inAppBrowser != null) {
              Map<String, dynamic> arguments = args[0].cast<String, dynamic>();
              AjaxRequest request = AjaxRequest.fromMap(arguments)!;

              if (_webview != null && _webview!.onAjaxReadyStateChange != null)
                return jsonEncode(
                    await _webview!.onAjaxReadyStateChange!(this, request));
              else
                return jsonEncode(
                    await _inAppBrowser!.onAjaxReadyStateChange(request));
            }
            return null;
          case "onAjaxProgress":
            if ((_webview != null && _webview!.onAjaxProgress != null) ||
                _inAppBrowser != null) {
              Map<String, dynamic> arguments = args[0].cast<String, dynamic>();
              AjaxRequest request = AjaxRequest.fromMap(arguments)!;

              if (_webview != null && _webview!.onAjaxProgress != null)
                return jsonEncode(
                    await _webview!.onAjaxProgress!(this, request));
              else
                return jsonEncode(await _inAppBrowser!.onAjaxProgress(request));
            }
            return null;
          case "shouldInterceptFetchRequest":
            if ((_webview != null &&
                    _webview!.shouldInterceptFetchRequest != null) ||
                _inAppBrowser != null) {
              Map<String, dynamic> arguments = args[0].cast<String, dynamic>();
              FetchRequest request = FetchRequest.fromMap(arguments)!;

              if (_webview != null &&
                  _webview!.shouldInterceptFetchRequest != null)
                return jsonEncode(await _webview!.shouldInterceptFetchRequest!(
                    this, request));
              else
                return jsonEncode(
                    await _inAppBrowser!.shouldInterceptFetchRequest(request));
            }
            return null;
          case "onPrint":
            if ((_webview != null && _webview!.onPrint != null) ||
                _inAppBrowser != null) {
              String? url = args[0];
              Uri? uri = url != null ? Uri.parse(url) : null;
              if (_webview != null && _webview!.onPrint != null)
                _webview!.onPrint!(this, uri);
              else
                _inAppBrowser!.onPrint(uri);
            }
            return null;
          case "onWindowFocus":
            if (_webview != null && _webview!.onWindowFocus != null)
              _webview!.onWindowFocus!(this);
            else if (_inAppBrowser != null) _inAppBrowser!.onWindowFocus();
            return null;
          case "onWindowBlur":
            if (_webview != null && _webview!.onWindowBlur != null)
              _webview!.onWindowBlur!(this);
            else if (_inAppBrowser != null) _inAppBrowser!.onWindowBlur();
            return null;
        }

        if (javaScriptHandlersMap.containsKey(handlerName)) {
          // convert result to json
          try {
            return jsonEncode(await javaScriptHandlersMap[handlerName]!(args));
          } catch (error) {
            print(error);
            return null;
          }
        }
        break;
      default:
        throw UnimplementedError("Unimplemented ${call.method} method");
    }
    return null;
  }

  ///Gets the URL for the current page.
  ///This is not always the same as the URL passed to [WebView.onLoadStart] because although the load for that URL has begun, the current page may not have changed.
  ///
  ///**Official Android API**: https://developer.android.com/reference/android/webkit/WebView#getUrl()
  ///
  ///**Official iOS API**: https://developer.apple.com/documentation/webkit/wkwebview/1415005-url
  Future<Uri?> getUrl() async {
    Map<String, dynamic> args = <String, dynamic>{};
    String? url = await _channel.invokeMethod('getUrl', args);
    return url != null ? Uri.parse(url) : null;
  }

  ///Gets the title for the current page.
  ///
  ///**Official Android API**: https://developer.android.com/reference/android/webkit/WebView#getTitle()
  ///
  ///**Official iOS API**: https://developer.apple.com/documentation/webkit/wkwebview/1415015-title
  Future<String?> getTitle() async {
    Map<String, dynamic> args = <String, dynamic>{};
    return await _channel.invokeMethod('getTitle', args);
  }

  ///Gets the progress for the current page. The progress value is between 0 and 100.
  ///
  ///**Official Android API**: https://developer.android.com/reference/android/webkit/WebView#getProgress()
  ///
  ///**Official iOS API**: https://developer.apple.com/documentation/webkit/wkwebview/1415007-estimatedprogress
  Future<int?> getProgress() async {
    Map<String, dynamic> args = <String, dynamic>{};
    return await _channel.invokeMethod('getProgress', args);
  }

  ///Gets the content html of the page. It first tries to get the content through javascript.
  ///If this doesn't work, it tries to get the content reading the file:
  ///- checking if it is an asset (`file:///`) or
  ///- downloading it using an `HttpClient` through the WebView's current url.
  ///
  ///Returns `null` if it was unable to get it.
  Future<String?> getHtml() async {
    String? html;

    InAppWebViewGroupOptions? options = await getOptions();
    if (options != null && options.crossPlatform.javaScriptEnabled == true) {
      html = await evaluateJavascript(
          source: "window.document.getElementsByTagName('html')[0].outerHTML;");
      if (html != null && html.isNotEmpty) return html;
    }

    var webviewUrl = await getUrl();
    if (webviewUrl == null) {
      return html;
    }

    if (webviewUrl.isScheme("file")) {
      var assetPathSplitted = webviewUrl.toString().split("/flutter_assets/");
      var assetPath = assetPathSplitted[assetPathSplitted.length - 1];
      try {
        var bytes = await rootBundle.load(assetPath);
        html = utf8.decode(bytes.buffer.asUint8List());
      } catch (e) {}
    } else {
      HttpClient client = new HttpClient();
      try {
        var htmlRequest = await client.getUrl(webviewUrl);
        html =
            await (await htmlRequest.close()).transform(Utf8Decoder()).join();
      } catch (e) {
        print(e);
      }
    }

    return html;
  }

  ///Gets the list of all favicons for the current page.
  Future<List<Favicon>> getFavicons() async {
    List<Favicon> favicons = [];

    HttpClient client = new HttpClient();
    var webviewUrl = await getUrl();

    if (webviewUrl == null) {
      return favicons;
    }

    String? manifestUrl;

    var html = await getHtml();
    if (html == null || html.isEmpty) {
      return favicons;
    }
    var assetPathBase;

    if (webviewUrl.isScheme("file")) {
      var assetPathSplitted = webviewUrl.toString().split("/flutter_assets/");
      assetPathBase = assetPathSplitted[0] + "/flutter_assets/";
    }

    InAppWebViewGroupOptions? options = await getOptions();
    if (options != null && options.crossPlatform.javaScriptEnabled == true) {
      List<Map<dynamic, dynamic>> links = (await evaluateJavascript(source: """
(function() {
  var linkNodes = document.head.getElementsByTagName("link");
  var links = [];
  for (var i = 0; i < linkNodes.length; i++) {
    var linkNode = linkNodes[i];
    if (linkNode.rel === 'manifest') {
      links.push(
        {
          rel: linkNode.rel,
          href: linkNode.href,
          sizes: null
        }
      );
    } else if (linkNode.rel != null && linkNode.rel.indexOf('icon') >= 0) {
      links.push(
        {
          rel: linkNode.rel,
          href: linkNode.href,
          sizes: linkNode.sizes != null && linkNode.sizes.value != "" ? linkNode.sizes.value : null
        }
      );
    }
  }
  return links;
})();
"""))?.cast<Map<dynamic, dynamic>>() ?? [];
      for (var link in links) {
        if (link["rel"] == "manifest") {
          manifestUrl = link["href"];
          if (!_isUrlAbsolute(manifestUrl!)) {
            if (manifestUrl.startsWith("/")) {
              manifestUrl = manifestUrl.substring(1);
            }
            manifestUrl = ((assetPathBase == null)
                    ? webviewUrl.scheme + "://" + webviewUrl.host + "/"
                    : assetPathBase) +
                manifestUrl;
          }
          continue;
        }
        favicons.addAll(_createFavicons(webviewUrl, assetPathBase, link["href"],
            link["rel"], link["sizes"], false));
      }
    }

    // try to get /favicon.ico
    try {
      var faviconUrl =
          webviewUrl.scheme + "://" + webviewUrl.host + "/favicon.ico";
      var faviconUri = Uri.parse(faviconUrl);
      var headRequest = await client.headUrl(faviconUri);
      var headResponse = await headRequest.close();
      if (headResponse.statusCode == 200) {
        favicons.add(Favicon(url: faviconUri, rel: "shortcut icon"));
      }
    } catch (e) {
      print("/favicon.ico file not found: " + e.toString());
      // print(stacktrace);
    }

    // try to get the manifest file
    HttpClientRequest? manifestRequest;
    HttpClientResponse? manifestResponse;
    bool manifestFound = false;
    if (manifestUrl == null) {
      manifestUrl =
          webviewUrl.scheme + "://" + webviewUrl.host + "/manifest.json";
    }
    try {
      manifestRequest = await client.getUrl(Uri.parse(manifestUrl));
      manifestResponse = await manifestRequest.close();
      manifestFound = manifestResponse.statusCode == 200 &&
          manifestResponse.headers.contentType?.mimeType == "application/json";
    } catch (e) {
      print("Manifest file not found: " + e.toString());
      // print(stacktrace);
    }

    if (manifestFound) {
      Map<String, dynamic> manifest =
          json.decode(await manifestResponse!.transform(Utf8Decoder()).join());
      if (manifest.containsKey("icons")) {
        for (Map<String, dynamic> icon in manifest["icons"]) {
          favicons.addAll(_createFavicons(webviewUrl, assetPathBase,
              icon["src"], icon["rel"], icon["sizes"], true));
        }
      }
    }

    return favicons;
  }

  bool _isUrlAbsolute(String url) {
    return url.startsWith("http://") || url.startsWith("https://");
  }

  List<Favicon> _createFavicons(Uri url, String? assetPathBase, String urlIcon,
      String? rel, String? sizes, bool isManifest) {
    List<Favicon> favicons = [];

    List<String> urlSplitted = urlIcon.split("/");
    if (!_isUrlAbsolute(urlIcon)) {
      if (urlIcon.startsWith("/")) {
        urlIcon = urlIcon.substring(1);
      }
      urlIcon = ((assetPathBase == null)
              ? url.scheme + "://" + url.host + "/"
              : assetPathBase) +
          urlIcon;
    }
    if (isManifest) {
      rel = (sizes != null)
          ? urlSplitted[urlSplitted.length - 1]
              .replaceFirst("-" + sizes, "")
              .split(" ")[0]
              .split(".")[0]
          : null;
    }
    if (sizes != null && sizes.isNotEmpty && sizes != "any") {
      List<String> sizesSplitted = sizes.split(" ");
      for (String size in sizesSplitted) {
        int width = int.parse(size.split("x")[0]);
        int height = int.parse(size.split("x")[1]);
        favicons.add(Favicon(
            url: Uri.parse(urlIcon), rel: rel, width: width, height: height));
      }
    } else {
      favicons.add(Favicon(
          url: Uri.parse(urlIcon), rel: rel, width: null, height: null));
    }

    return favicons;
  }

  ///Loads the given [urlRequest].
  ///
  ///[iosAllowingReadAccessTo], used in combination with [urlRequest] (using the `file://` scheme),
  ///is an iOS-specific argument that represents the URL from which to read the web content.
  ///This URL must be a file-based URL (using the `file://` scheme).
  ///Specify the same value as the URL parameter to prevent WebView from reading any other content.
  ///Specify a directory to give WebView permission to read additional files in the specified directory.
  ///
  ///**NOTE for Android**: when loading an URL Request using "POST" method, headers are ignored.
  ///
  ///**Official Android API**: https://developer.android.com/reference/android/webkit/WebView#loadUrl(java.lang.String)
  ///
  ///**Official iOS API**:
  ///- https://developer.apple.com/documentation/webkit/wkwebview/1414954-load
  ///- if [iosAllowingReadAccessTo] is used, https://developer.apple.com/documentation/webkit/wkwebview/1414973-loadfileurl
  Future<void> loadUrl(
      {required URLRequest urlRequest, Uri? iosAllowingReadAccessTo}) async {
    assert(urlRequest.url != null && urlRequest.url.toString().isNotEmpty);
    assert(iosAllowingReadAccessTo == null ||
        iosAllowingReadAccessTo.isScheme("file"));

    Map<String, dynamic> args = <String, dynamic>{};
    args.putIfAbsent('urlRequest', () => urlRequest.toMap());
    args.putIfAbsent(
        'allowingReadAccessTo', () => iosAllowingReadAccessTo.toString());
    await _channel.invokeMethod('loadUrl', args);
  }

  ///Loads the given [url] with [postData] (x-www-form-urlencoded) using `POST` method into this WebView.
  ///
  ///**Official Android API**: https://developer.android.com/reference/android/webkit/WebView#postUrl(java.lang.String,%20byte[])
  ///
  ///Example
  ///```dart
  ///var postData = Uint8List.fromList(utf8.encode("firstname=Foo&surname=Bar"));
  ///controller.postUrl(url: Uri.parse("https://www.example.com/"), postData: postData);
  ///```
  Future<void> postUrl({required Uri url, required Uint8List postData}) async {
    assert(url.toString().isNotEmpty);
    Map<String, dynamic> args = <String, dynamic>{};
    args.putIfAbsent('url', () => url.toString());
    args.putIfAbsent('postData', () => postData);
    await _channel.invokeMethod('postUrl', args);
  }

  ///Loads the given [data] into this WebView, using [baseUrl] as the base URL for the content.
  ///
  ///The [mimeType] parameter specifies the format of the data. The default value is `"text/html"`.
  ///
  ///The [encoding] parameter specifies the encoding of the data. The default value is `"utf8"`.
  ///
  ///The [androidHistoryUrl] parameter is the URL to use as the history entry. The default value is `about:blank`. If non-null, this must be a valid URL. This parameter is used only on Android.
  ///
  ///**Official Android API**: https://developer.android.com/reference/android/webkit/WebView#loadDataWithBaseURL(java.lang.String,%20java.lang.String,%20java.lang.String,%20java.lang.String,%20java.lang.String)
  ///
  ///**Official iOS API**:
  ///- https://developer.apple.com/documentation/webkit/wkwebview/1415004-loadhtmlstring
  ///- https://developer.apple.com/documentation/webkit/wkwebview/1415011-load
  Future<void> loadData(
      {required String data,
      String mimeType = "text/html",
      String encoding = "utf8",
      Uri? baseUrl,
      Uri? androidHistoryUrl}) async {
    Map<String, dynamic> args = <String, dynamic>{};
    args.putIfAbsent('data', () => data);
    args.putIfAbsent('mimeType', () => mimeType);
    args.putIfAbsent('encoding', () => encoding);
    args.putIfAbsent('baseUrl', () => baseUrl?.toString() ?? "about:blank");
    args.putIfAbsent(
        'historyUrl', () => androidHistoryUrl?.toString() ?? "about:blank");
    await _channel.invokeMethod('loadData', args);
  }

  ///Loads the given [assetFilePath].
  ///
  ///To be able to load your local files (assets, js, css, etc.), you need to add them in the `assets` section of the `pubspec.yaml` file, otherwise they cannot be found!
  ///
  ///Example of a `pubspec.yaml` file:
  ///```yaml
  ///...
  ///
  ///# The following section is specific to Flutter.
  ///flutter:
  ///
  ///  # The following line ensures that the Material Icons font is
  ///  # included with your application, so that you can use the icons in
  ///  # the material Icons class.
  ///  uses-material-design: true
  ///
  ///  assets:
  ///    - assets/index.html
  ///    - assets/css/
  ///    - assets/images/
  ///
  ///...
  ///```
  ///Example:
  ///```dart
  ///...
  ///controller.loadFile(assetFilePath: "assets/index.html");
  ///...
  ///```
  Future<void> loadFile({required String assetFilePath}) async {
    assert(assetFilePath.isNotEmpty);
    Map<String, dynamic> args = <String, dynamic>{};
    args.putIfAbsent('assetFilePath', () => assetFilePath);
    await _channel.invokeMethod('loadFile', args);
  }

  ///Reloads the WebView.
  ///
  ///**Official Android API**: https://developer.android.com/reference/android/webkit/WebView#reload()
  ///
  ///**Official iOS API**: https://developer.apple.com/documentation/webkit/wkwebview/1414969-reload
  Future<void> reload() async {
    Map<String, dynamic> args = <String, dynamic>{};
    await _channel.invokeMethod('reload', args);
  }

  ///Goes back in the history of the WebView.
  ///
  ///**Official Android API**: https://developer.android.com/reference/android/webkit/WebView#goBack()
  ///
  ///**Official iOS API**: https://developer.apple.com/documentation/webkit/wkwebview/1414952-goback
  Future<void> goBack() async {
    Map<String, dynamic> args = <String, dynamic>{};
    await _channel.invokeMethod('goBack', args);
  }

  ///Returns a boolean value indicating whether the WebView can move backward.
  ///
  ///**Official Android API**: https://developer.android.com/reference/android/webkit/WebView#canGoBack()
  ///
  ///**Official iOS API**: https://developer.apple.com/documentation/webkit/wkwebview/1414966-cangoback
  Future<bool> canGoBack() async {
    Map<String, dynamic> args = <String, dynamic>{};
    return await _channel.invokeMethod('canGoBack', args);
  }

  ///Goes forward in the history of the WebView.
  ///
  ///**Official Android API**: https://developer.android.com/reference/android/webkit/WebView#goForward()
  ///
  ///**Official iOS API**: https://developer.apple.com/documentation/webkit/wkwebview/1414993-goforward
  Future<void> goForward() async {
    Map<String, dynamic> args = <String, dynamic>{};
    await _channel.invokeMethod('goForward', args);
  }

  ///Returns a boolean value indicating whether the WebView can move forward.
  ///
  ///**Official Android API**: https://developer.android.com/reference/android/webkit/WebView#canGoForward()
  ///
  ///**Official iOS API**: https://developer.apple.com/documentation/webkit/wkwebview/1414962-cangoforward
  Future<bool> canGoForward() async {
    Map<String, dynamic> args = <String, dynamic>{};
    return await _channel.invokeMethod('canGoForward', args);
  }

  ///Goes to the history item that is the number of steps away from the current item. Steps is negative if backward and positive if forward.
  ///
  ///**Official Android API**: https://developer.android.com/reference/android/webkit/WebView#goBackOrForward(int)
  ///
  ///**Official iOS API**: https://developer.apple.com/documentation/webkit/wkwebview/1414991-go
  Future<void> goBackOrForward({required int steps}) async {
    Map<String, dynamic> args = <String, dynamic>{};
    args.putIfAbsent('steps', () => steps);
    await _channel.invokeMethod('goBackOrForward', args);
  }

  ///Returns a boolean value indicating whether the WebView can go back or forward the given number of steps. Steps is negative if backward and positive if forward.
  ///
  ///**Official Android API**: https://developer.android.com/reference/android/webkit/WebView#canGoBackOrForward(int)
  Future<bool> canGoBackOrForward({required int steps}) async {
    Map<String, dynamic> args = <String, dynamic>{};
    args.putIfAbsent('steps', () => steps);
    return await _channel.invokeMethod('canGoBackOrForward', args);
  }

  ///Navigates to a [WebHistoryItem] from the back-forward [WebHistory.list] and sets it as the current item.
  Future<void> goTo({required WebHistoryItem historyItem}) async {
    if (historyItem.offset != null) {
      await goBackOrForward(steps: historyItem.offset!);
    }
  }

  ///Check if the WebView instance is in a loading state.
  Future<bool> isLoading() async {
    Map<String, dynamic> args = <String, dynamic>{};
    return await _channel.invokeMethod('isLoading', args);
  }

  ///Stops the WebView from loading.
  ///
  ///**Official Android API**: https://developer.android.com/reference/android/webkit/WebView#stopLoading()
  ///
  ///**Official iOS API**: https://developer.apple.com/documentation/webkit/wkwebview/1414981-stoploading
  Future<void> stopLoading() async {
    Map<String, dynamic> args = <String, dynamic>{};
    await _channel.invokeMethod('stopLoading', args);
  }

  ///Evaluates JavaScript [source] code into the WebView and returns the result of the evaluation.
  ///
  ///[contentWorld], on iOS, it represents the namespace in which to evaluate the JavaScript [source] code.
  ///Instead, on Android, it will run the [source] code into an iframe, using `eval(source);` to get and return the result.
  ///This parameter doesn’t apply to changes you make to the underlying web content, such as the document’s DOM structure.
  ///Those changes remain visible to all scripts, regardless of which content world you specify.
  ///For more information about content worlds, see [ContentWorld].
  ///Available on iOS 14.0+.
  ///
  ///**NOTE**: This method shouldn't be called in the [WebView.onWebViewCreated] or [WebView.onLoadStart] events,
  ///because, in these events, the [WebView] is not ready to handle it yet.
  ///Instead, you should call this method, for example, inside the [WebView.onLoadStop] event or in any other events
  ///where you know the page is ready "enough".
  ///
  ///**Official Android API**: https://developer.android.com/reference/android/webkit/WebView#evaluateJavascript(java.lang.String,%20android.webkit.ValueCallback%3Cjava.lang.String%3E)
  ///
  ///**Official iOS API**:
  ///- https://developer.apple.com/documentation/webkit/wkwebview/1415017-evaluatejavascript
  ///- https://developer.apple.com/documentation/webkit/wkwebview/3656442-evaluatejavascript
  Future<dynamic> evaluateJavascript(
      {required String source, ContentWorld? contentWorld}) async {
    Map<String, dynamic> args = <String, dynamic>{};
    args.putIfAbsent('source', () => source);
    args.putIfAbsent('contentWorld', () => contentWorld?.toMap());
    var data = await _channel.invokeMethod('evaluateJavascript', args);
    if (data != null && defaultTargetPlatform == TargetPlatform.android)
      data = json.decode(data);
    return data;
  }

  ///Injects an external JavaScript file into the WebView from a defined url.
  ///
  ///[scriptHtmlTagAttributes] represents the possible the `<script>` HTML attributes to be set.
  ///
  ///**NOTE**: This method shouldn't be called in the [WebView.onWebViewCreated] or [WebView.onLoadStart] events,
  ///because, in these events, the [WebView] is not ready to handle it yet.
  ///Instead, you should call this method, for example, inside the [WebView.onLoadStop] event or in any other events
  ///where you know the page is ready "enough".
  Future<void> injectJavascriptFileFromUrl(
      {required Uri urlFile,
      ScriptHtmlTagAttributes? scriptHtmlTagAttributes}) async {
    assert(urlFile.toString().isNotEmpty);
    Map<String, dynamic> args = <String, dynamic>{};
    args.putIfAbsent('urlFile', () => urlFile.toString());
    args.putIfAbsent(
        'scriptHtmlTagAttributes', () => scriptHtmlTagAttributes?.toMap());
    await _channel.invokeMethod('injectJavascriptFileFromUrl', args);
  }

  ///Evaluates the content of a JavaScript file into the WebView from the flutter assets directory.
  ///
  ///**NOTE**: This method shouldn't be called in the [WebView.onWebViewCreated] or [WebView.onLoadStart] events,
  ///because, in these events, the [WebView] is not ready to handle it yet.
  ///Instead, you should call this method, for example, inside the [WebView.onLoadStop] event or in any other events
  ///where you know the page is ready "enough".
  Future<void> injectJavascriptFileFromAsset(
      {required String assetFilePath}) async {
    String source = await rootBundle.loadString(assetFilePath);
    await evaluateJavascript(source: source);
  }

  ///Injects CSS into the WebView.
  ///
  ///**NOTE**: This method shouldn't be called in the [WebView.onWebViewCreated] or [WebView.onLoadStart] events,
  ///because, in these events, the [WebView] is not ready to handle it yet.
  ///Instead, you should call this method, for example, inside the [WebView.onLoadStop] event or in any other events
  ///where you know the page is ready "enough".
  Future<void> injectCSSCode({required String source}) async {
    Map<String, dynamic> args = <String, dynamic>{};
    args.putIfAbsent('source', () => source);
    await _channel.invokeMethod('injectCSSCode', args);
  }

  ///Injects an external CSS file into the WebView from a defined url.
  ///
  ///[cssLinkHtmlTagAttributes] represents the possible CSS stylesheet `<link>` HTML attributes to be set.
  ///
  ///**NOTE**: This method shouldn't be called in the [WebView.onWebViewCreated] or [WebView.onLoadStart] events,
  ///because, in these events, the [WebView] is not ready to handle it yet.
  ///Instead, you should call this method, for example, inside the [WebView.onLoadStop] event or in any other events
  ///where you know the page is ready "enough".
  Future<void> injectCSSFileFromUrl(
      {required Uri urlFile,
      CSSLinkHtmlTagAttributes? cssLinkHtmlTagAttributes}) async {
    assert(urlFile.toString().isNotEmpty);
    Map<String, dynamic> args = <String, dynamic>{};
    args.putIfAbsent('urlFile', () => urlFile.toString());
    args.putIfAbsent(
        'cssLinkHtmlTagAttributes', () => cssLinkHtmlTagAttributes?.toMap());
    await _channel.invokeMethod('injectCSSFileFromUrl', args);
  }

  ///Injects a CSS file into the WebView from the flutter assets directory.
  ///
  ///**NOTE**: This method shouldn't be called in the [WebView.onWebViewCreated] or [WebView.onLoadStart] events,
  ///because, in these events, the [WebView] is not ready to handle it yet.
  ///Instead, you should call this method, for example, inside the [WebView.onLoadStop] event or in any other events
  ///where you know the page is ready "enough".
  Future<void> injectCSSFileFromAsset({required String assetFilePath}) async {
    String source = await rootBundle.loadString(assetFilePath);
    await injectCSSCode(source: source);
  }

  ///Adds a JavaScript message handler [callback] ([JavaScriptHandlerCallback]) that listen to post messages sent from JavaScript by the handler with name [handlerName].
  ///
  ///The Android implementation uses [addJavascriptInterface](https://developer.android.com/reference/android/webkit/WebView#addJavascriptInterface(java.lang.Object,%20java.lang.String)).
  ///The iOS implementation uses [addScriptMessageHandler](https://developer.apple.com/documentation/webkit/wkusercontentcontroller/1537172-addscriptmessagehandler?language=objc)
  ///
  ///The JavaScript function that can be used to call the handler is `window.flutter_inappwebview.callHandler(handlerName <String>, ...args)`, where `args` are [rest parameters](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Functions/rest_parameters).
  ///The `args` will be stringified automatically using `JSON.stringify(args)` method and then they will be decoded on the Dart side.
  ///
  ///In order to call `window.flutter_inappwebview.callHandler(handlerName <String>, ...args)` properly, you need to wait and listen the JavaScript event `flutterInAppWebViewPlatformReady`.
  ///This event will be dispatched as soon as the platform (Android or iOS) is ready to handle the `callHandler` method.
  ///```javascript
  ///   window.addEventListener("flutterInAppWebViewPlatformReady", function(event) {
  ///     console.log("ready");
  ///   });
  ///```
  ///
  ///`window.flutter_inappwebview.callHandler` returns a JavaScript [Promise](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Promise)
  ///that can be used to get the json result returned by [JavaScriptHandlerCallback].
  ///In this case, simply return data that you want to send and it will be automatically json encoded using [jsonEncode] from the `dart:convert` library.
  ///
  ///So, on the JavaScript side, to get data coming from the Dart side, you will use:
  ///```html
  ///<script>
  ///   window.addEventListener("flutterInAppWebViewPlatformReady", function(event) {
  ///     window.flutter_inappwebview.callHandler('handlerFoo').then(function(result) {
  ///       console.log(result);
  ///     });
  ///
  ///     window.flutter_inappwebview.callHandler('handlerFooWithArgs', 1, true, ['bar', 5], {foo: 'baz'}).then(function(result) {
  ///       console.log(result);
  ///     });
  ///   });
  ///</script>
  ///```
  ///
  ///Instead, on the `onLoadStop` WebView event, you can use `callHandler` directly:
  ///```dart
  ///  // Inject JavaScript that will receive data back from Flutter
  ///  inAppWebViewController.evaluateJavascript(source: """
  ///    window.flutter_inappwebview.callHandler('test', 'Text from Javascript').then(function(result) {
  ///      console.log(result);
  ///    });
  ///  """);
  ///```
  ///
  ///Forbidden names for JavaScript handlers are defined in [_JAVASCRIPT_HANDLER_FORBIDDEN_NAMES].
  ///
  ///**NOTE**: This method should be called, for example, in the [WebView.onWebViewCreated] or [WebView.onLoadStart] events or, at least,
  ///before you know that your JavaScript code will call the `window.flutter_inappwebview.callHandler` method,
  ///otherwise you won't be able to intercept the JavaScript message.
  void addJavaScriptHandler(
      {required String handlerName,
      required JavaScriptHandlerCallback callback}) {
    assert(!_JAVASCRIPT_HANDLER_FORBIDDEN_NAMES.contains(handlerName));
    this.javaScriptHandlersMap[handlerName] = (callback);
  }

  ///Removes a JavaScript message handler previously added with the [addJavaScriptHandler()] associated to [handlerName] key.
  ///Returns the value associated with [handlerName] before it was removed.
  ///Returns `null` if [handlerName] was not found.
  JavaScriptHandlerCallback? removeJavaScriptHandler(
      {required String handlerName}) {
    return this.javaScriptHandlersMap.remove(handlerName);
  }

  ///Takes a screenshot (in PNG format) of the WebView's visible viewport and returns a [Uint8List]. Returns `null` if it wasn't be able to take it.
  ///
  ///[screenshotConfiguration] represents the configuration data to use when generating an image from a web view’s contents.
  ///
  ///**NOTE for iOS**: available on iOS 11.0+.
  ///
  ///**Official iOS API**: https://developer.apple.com/documentation/webkit/wkwebview/2873260-takesnapshot
  Future<Uint8List?> takeScreenshot(
      {ScreenshotConfiguration? screenshotConfiguration}) async {
    Map<String, dynamic> args = <String, dynamic>{};
    args.putIfAbsent(
        'screenshotConfiguration', () => screenshotConfiguration?.toMap());
    return await _channel.invokeMethod('takeScreenshot', args);
  }

  ///Sets the WebView options with the new [options] and evaluates them.
  Future<void> setOptions({required InAppWebViewGroupOptions options}) async {
    Map<String, dynamic> args = <String, dynamic>{};

    args.putIfAbsent('options', () => options.toMap());
    await _channel.invokeMethod('setOptions', args);
  }

  ///Gets the current WebView options. Returns `null` if it wasn't able to get them.
  Future<InAppWebViewGroupOptions?> getOptions() async {
    Map<String, dynamic> args = <String, dynamic>{};

    Map<dynamic, dynamic>? options =
        await _channel.invokeMethod('getOptions', args);
    if (options != null) {
      options = options.cast<String, dynamic>();
      return InAppWebViewGroupOptions.fromMap(options as Map<String, dynamic>);
    }

    return null;
  }

  ///Gets the WebHistory for this WebView. This contains the back/forward list for use in querying each item in the history stack.
  ///This contains only a snapshot of the current state.
  ///Multiple calls to this method may return different objects.
  ///The object returned from this method will not be updated to reflect any new state.
  ///
  ///**Official Android API**: https://developer.android.com/reference/android/webkit/WebView#copyBackForwardList()
  ///
  ///**Official iOS API**: https://developer.apple.com/documentation/webkit/wkwebview/1414977-backforwardlist
  Future<WebHistory?> getCopyBackForwardList() async {
    Map<String, dynamic> args = <String, dynamic>{};
    Map<String, dynamic>? result =
        (await _channel.invokeMethod('getCopyBackForwardList', args))
            ?.cast<String, dynamic>();
    return WebHistory.fromMap(result);
  }

  ///Clears all the webview's cache.
  Future<void> clearCache() async {
    Map<String, dynamic> args = <String, dynamic>{};
    await _channel.invokeMethod('clearCache', args);
  }

  ///Finds all instances of find on the page and highlights them. Notifies [WebView.onFindResultReceived] listener.
  ///
  ///[find] represents the string to find.
  ///
  ///**NOTE**: on Android, it finds all instances asynchronously. Successive calls to this will cancel any pending searches.
  ///
  ///**NOTE**: on iOS, this is implemented using CSS and Javascript.
  ///
  ///**Official Android API**: https://developer.android.com/reference/android/webkit/WebView#findAllAsync(java.lang.String)
  Future<void> findAllAsync({required String find}) async {
    Map<String, dynamic> args = <String, dynamic>{};
    args.putIfAbsent('find', () => find);
    await _channel.invokeMethod('findAllAsync', args);
  }

  ///Highlights and scrolls to the next match found by [findAllAsync()]. Notifies [WebView.onFindResultReceived] listener.
  ///
  ///[forward] represents the direction to search.
  ///
  ///**NOTE**: on iOS, this is implemented using CSS and Javascript.
  ///
  ///**Official Android API**: https://developer.android.com/reference/android/webkit/WebView#findNext(boolean)
  Future<void> findNext({required bool forward}) async {
    Map<String, dynamic> args = <String, dynamic>{};
    args.putIfAbsent('forward', () => forward);
    await _channel.invokeMethod('findNext', args);
  }

  ///Clears the highlighting surrounding text matches created by [findAllAsync()].
  ///
  ///**NOTE**: on iOS, this is implemented using CSS and Javascript.
  ///
  ///**Official Android API**: https://developer.android.com/reference/android/webkit/WebView#clearMatches()
  Future<void> clearMatches() async {
    Map<String, dynamic> args = <String, dynamic>{};
    await _channel.invokeMethod('clearMatches', args);
  }

  ///Gets the html (with javascript) of the Chromium's t-rex runner game. Used in combination with [getTRexRunnerCss()].
  Future<String> getTRexRunnerHtml() async {
    return await rootBundle
        .loadString("packages/flutter_inappwebview/t_rex_runner/t-rex.html");
  }

  ///Gets the css of the Chromium's t-rex runner game. Used in combination with [getTRexRunnerHtml()].
  Future<String> getTRexRunnerCss() async {
    return await rootBundle
        .loadString("packages/flutter_inappwebview/t_rex_runner/t-rex.css");
  }

  ///Scrolls the WebView to the position.
  ///
  ///[x] represents the x position to scroll to.
  ///
  ///[y] represents the y position to scroll to.
  ///
  ///[animated] `true` to animate the scroll transition, `false` to make the scoll transition immediate.
  ///
  ///**Official Android API**: https://developer.android.com/reference/android/view/View#scrollTo(int,%20int)
  ///
  ///**Official iOS API**: https://developer.apple.com/documentation/uikit/uiscrollview/1619400-setcontentoffset
  Future<void> scrollTo(
      {required int x, required int y, bool animated = false}) async {
    Map<String, dynamic> args = <String, dynamic>{};
    args.putIfAbsent('x', () => x);
    args.putIfAbsent('y', () => y);
    args.putIfAbsent('animated', () => animated);
    await _channel.invokeMethod('scrollTo', args);
  }

  ///Moves the scrolled position of the WebView.
  ///
  ///[x] represents the amount of pixels to scroll by horizontally.
  ///
  ///[y] represents the amount of pixels to scroll by vertically.
  ///
  ///[animated] `true` to animate the scroll transition, `false` to make the scoll transition immediate.
  ///
  ///**Official Android API**: https://developer.android.com/reference/android/view/View#scrollBy(int,%20int)
  ///
  ///**Official iOS API**: https://developer.apple.com/documentation/uikit/uiscrollview/1619400-setcontentoffset
  Future<void> scrollBy(
      {required int x, required int y, bool animated = false}) async {
    Map<String, dynamic> args = <String, dynamic>{};
    args.putIfAbsent('x', () => x);
    args.putIfAbsent('y', () => y);
    args.putIfAbsent('animated', () => animated);
    await _channel.invokeMethod('scrollBy', args);
  }

  ///On Android, it pauses all layout, parsing, and JavaScript timers for all WebViews.
  ///This is a global requests, not restricted to just this WebView. This can be useful if the application has been paused.
  ///
  ///On iOS, it is restricted to just this WebView.
  ///
  ///**Official Android API**: https://developer.android.com/reference/android/webkit/WebView#pauseTimers()
  Future<void> pauseTimers() async {
    Map<String, dynamic> args = <String, dynamic>{};
    await _channel.invokeMethod('pauseTimers', args);
  }

  ///On Android, it resumes all layout, parsing, and JavaScript timers for all WebViews. This will resume dispatching all timers.
  ///
  ///On iOS, it resumes all layout, parsing, and JavaScript timers to just this WebView.
  ///
  ///**Official Android API**: https://developer.android.com/reference/android/webkit/WebView#resumeTimers()
  Future<void> resumeTimers() async {
    Map<String, dynamic> args = <String, dynamic>{};
    await _channel.invokeMethod('resumeTimers', args);
  }

  ///Prints the current page.
  ///
  ///**NOTE**: available on Android 21+.
  ///
  ///**Official Android API**: https://developer.android.com/reference/android/print/PrintManager
  ///
  ///**Official iOS API**: https://developer.apple.com/documentation/uikit/uiprintinteractioncontroller
  Future<void> printCurrentPage() async {
    Map<String, dynamic> args = <String, dynamic>{};
    await _channel.invokeMethod('printCurrentPage', args);
  }

  ///Gets the height of the HTML content.
  ///
  ///**Official Android API**: https://developer.android.com/reference/android/webkit/WebView#getContentHeight()
  ///
  ///**Official iOS API**: https://developer.apple.com/documentation/uikit/uiscrollview/1619399-contentsize
  Future<int?> getContentHeight() async {
    Map<String, dynamic> args = <String, dynamic>{};
    return await _channel.invokeMethod('getContentHeight', args);
  }

  ///Performs a zoom operation in this WebView.
  ///
  ///[zoomFactor] represents the zoom factor to apply. On Android, the zoom factor will be clamped to the Webview's zoom limits and, also, this value must be in the range 0.01 (excluded) to 100.0 (included).
  ///
  ///[iosAnimated] `true` to animate the transition to the new scale, `false` to make the transition immediate.
  ///**NOTE**: available only on iOS.
  ///
  ///**NOTE**: available on Android 21+.
  ///
  ///**Official Android API**: https://developer.android.com/reference/android/webkit/WebView#zoomBy(float)
  ///
  ///**Official iOS API**: https://developer.apple.com/documentation/uikit/uiscrollview/1619412-setzoomscale
  Future<void> zoomBy(
      {required double zoomFactor, bool iosAnimated = false}) async {
    assert(defaultTargetPlatform != TargetPlatform.android ||
        (defaultTargetPlatform == TargetPlatform.android &&
            zoomFactor > 0.01 &&
            zoomFactor <= 100.0));

    Map<String, dynamic> args = <String, dynamic>{};
    args.putIfAbsent('zoomFactor', () => zoomFactor);
    args.putIfAbsent('iosAnimated', () => iosAnimated);
    return await _channel.invokeMethod('zoomBy', args);
  }

  ///Gets the current scale of this WebView.
  ///
  ///**Official Android API**:
  ///- https://developer.android.com/reference/android/util/DisplayMetrics#density
  ///- https://developer.android.com/reference/android/webkit/WebViewClient#onScaleChanged(android.webkit.WebView,%20float,%20float)
  ///
  ///**Official iOS API**: https://developer.apple.com/documentation/uikit/uiscrollview/1619419-zoomscale
  Future<double?> getScale() async {
    Map<String, dynamic> args = <String, dynamic>{};
    return await _channel.invokeMethod('getScale', args);
  }

  ///Gets the selected text.
  ///
  ///**NOTE**: This method is implemented with using JavaScript.
  ///
  ///**NOTE for Android**: available only on Android 19+.
  Future<String?> getSelectedText() async {
    Map<String, dynamic> args = <String, dynamic>{};
    return await _channel.invokeMethod('getSelectedText', args);
  }

  ///Gets the hit result for hitting an HTML elements.
  ///
  ///**NOTE**: On iOS it is implemented using JavaScript.
  ///
  ///**Official Android API**: https://developer.android.com/reference/android/webkit/WebView#getHitTestResult()
  Future<InAppWebViewHitTestResult?> getHitTestResult() async {
    Map<String, dynamic> args = <String, dynamic>{};
    Map<dynamic, dynamic>? hitTestResultMap =
        await _channel.invokeMethod('getHitTestResult', args);

    if (hitTestResultMap == null) {
      return null;
    }

    hitTestResultMap = hitTestResultMap.cast<String, dynamic>();

    InAppWebViewHitTestResultType? type =
        InAppWebViewHitTestResultType.fromValue(
            hitTestResultMap["type"].toInt());
    String extra = hitTestResultMap["extra"];
    return InAppWebViewHitTestResult(type: type, extra: extra);
  }

  ///Clears the current focus. It will clear also, for example, the current text selection.
  ///
  ///**Official Android API**: https://developer.android.com/reference/android/view/ViewGroup#clearFocus()
  ///
  ///**Official iOS API**: https://developer.apple.com/documentation/uikit/uiresponder/1621097-resignfirstresponder
  Future<void> clearFocus() async {
    Map<String, dynamic> args = <String, dynamic>{};
    return await _channel.invokeMethod('clearFocus', args);
  }

  ///Sets or updates the WebView context menu to be used next time it will appear.
  Future<void> setContextMenu(ContextMenu? contextMenu) async {
    Map<String, dynamic> args = <String, dynamic>{};
    args.putIfAbsent("contextMenu", () => contextMenu?.toMap());
    await _channel.invokeMethod('setContextMenu', args);
    _inAppBrowser?.contextMenu = contextMenu;
  }

  ///Requests the anchor or image element URL at the last tapped point.
  ///
  ///**NOTE**: On iOS it is implemented using JavaScript.
  ///
  ///**Official Android API**: https://developer.android.com/reference/android/webkit/WebView#requestFocusNodeHref(android.os.Message)
  Future<RequestFocusNodeHrefResult?> requestFocusNodeHref() async {
    Map<String, dynamic> args = <String, dynamic>{};
    Map<dynamic, dynamic>? result =
        await _channel.invokeMethod('requestFocusNodeHref', args);
    return result != null
        ? RequestFocusNodeHrefResult(
            url: result['url'] != null ? Uri.parse(result['url']) : null,
            title: result['title'],
            src: result['src'],
          )
        : null;
  }

  ///Requests the URL of the image last touched by the user.
  ///
  ///**NOTE**: On iOS it is implemented using JavaScript.
  ///
  ///**Official Android API**: https://developer.android.com/reference/android/webkit/WebView#requestImageRef(android.os.Message)
  Future<RequestImageRefResult?> requestImageRef() async {
    Map<String, dynamic> args = <String, dynamic>{};
    Map<dynamic, dynamic>? result =
        await _channel.invokeMethod('requestImageRef', args);
    return result != null
        ? RequestImageRefResult(
            url: result['url'] != null ? Uri.parse(result['url']) : null,
          )
        : null;
  }

  ///Returns the list of `<meta>` tags of the current WebView.
  ///
  ///**NOTE**: It is implemented using JavaScript.
  Future<List<MetaTag>> getMetaTags() async {
    List<MetaTag> metaTags = [];

    List<Map<dynamic, dynamic>>? metaTagList =
        (await evaluateJavascript(source: """
(function() {
  var metaTags = [];
  var metaTagNodes = document.head.getElementsByTagName('meta');
  for (var i = 0; i < metaTagNodes.length; i++) {
    var metaTagNode = metaTagNodes[i];
    
    var otherAttributes = metaTagNode.getAttributeNames();
    var nameIndex = otherAttributes.indexOf("name");
    if (nameIndex !== -1) otherAttributes.splice(nameIndex, 1);
    var contentIndex = otherAttributes.indexOf("content");
    if (contentIndex !== -1) otherAttributes.splice(contentIndex, 1);
    
    var attrs = [];
    for (var j = 0; j < otherAttributes.length; j++) {
      var otherAttribute = otherAttributes[j];
      attrs.push(
        {
          name: otherAttribute,
          value: metaTagNode.getAttribute(otherAttribute)
        }
      );
    }

    metaTags.push(
      {
        name: metaTagNode.name,
        content: metaTagNode.content,
        attrs: attrs
      }
    );
  }
  return metaTags;
})();
    """))?.cast<Map<dynamic, dynamic>>();

    if (metaTagList == null) {
      return metaTags;
    }

    for (var metaTag in metaTagList) {
      var attrs = <MetaTagAttribute>[];

      for (var metaTagAttr in metaTag["attrs"]) {
        attrs.add(MetaTagAttribute(
            name: metaTagAttr["name"], value: metaTagAttr["value"]));
      }

      metaTags.add(MetaTag(
          name: metaTag["name"], content: metaTag["content"], attrs: attrs));
    }

    return metaTags;
  }

  ///Returns an instance of [Color] representing the `content` value of the
  ///`<meta name="theme-color" content="">` tag of the current WebView, if available, otherwise `null`.
  ///
  ///**NOTE**: It is implemented using JavaScript.
  Future<Color?> getMetaThemeColor() async {
    var metaTags = await getMetaTags();
    MetaTag? metaTagThemeColor;

    for (var metaTag in metaTags) {
      if (metaTag.name == "theme-color") {
        metaTagThemeColor = metaTag;
        break;
      }
    }

    if (metaTagThemeColor == null) {
      return null;
    }

    var colorValue = metaTagThemeColor.content;

    return colorValue != null
        ? UtilColor.fromStringRepresentation(colorValue)
        : null;
  }

  ///Returns the scrolled left position of the current WebView.
  ///
  ///**Official Android API**: https://developer.android.com/reference/android/view/View#getScrollX()
  ///
  ///**Official iOS API**: https://developer.apple.com/documentation/uikit/uiscrollview/1619404-contentoffset
  Future<int?> getScrollX() async {
    Map<String, dynamic> args = <String, dynamic>{};
    return await _channel.invokeMethod('getScrollX', args);
  }

  ///Returns the scrolled top position of the current WebView.
  ///
  ///**Official Android API**: https://developer.android.com/reference/android/view/View#getScrollY()
  ///
  ///**Official iOS API**: https://developer.apple.com/documentation/uikit/uiscrollview/1619404-contentoffset
  Future<int?> getScrollY() async {
    Map<String, dynamic> args = <String, dynamic>{};
    return await _channel.invokeMethod('getScrollY', args);
  }

  ///Gets the SSL certificate for the main top-level page or null if there is no certificate (the site is not secure).
  ///
  ///**Official Android API**: https://developer.android.com/reference/android/webkit/WebView#getCertificate()
  Future<SslCertificate?> getCertificate() async {
    Map<String, dynamic> args = <String, dynamic>{};
    Map<String, dynamic>? sslCertificateMap =
        (await _channel.invokeMethod('getCertificate', args))
            ?.cast<String, dynamic>();
    return SslCertificate.fromMap(sslCertificateMap);
  }

  ///Injects the specified [userScript] into the webpage’s content.
  ///
  ///**NOTE for iOS**: this method will throw an error if the [WebView.windowId] has been set.
  ///There isn't any way to add/remove user scripts specific to iOS window WebViews.
  ///This is a limitation of the native iOS WebKit APIs.
  ///
  ///**Official iOS API**: https://developer.apple.com/documentation/webkit/wkusercontentcontroller/1537448-adduserscript
  Future<void> addUserScript({required UserScript userScript}) async {
    assert(_webview?.windowId == null ||
        defaultTargetPlatform != TargetPlatform.iOS);

    Map<String, dynamic> args = <String, dynamic>{};
    args.putIfAbsent('userScript', () => userScript.toMap());
    if (!_userScripts.contains(userScript)) {
      _userScripts.add(userScript);
      await _channel.invokeMethod('addUserScript', args);
    }
  }

  ///Injects the [userScripts] into the webpage’s content.
  ///
  ///**NOTE for iOS**: this method will throw an error if the [WebView.windowId] has been set.
  ///There isn't any way to add/remove user scripts specific to iOS window WebViews.
  ///This is a limitation of the native iOS WebKit APIs.
  Future<void> addUserScripts({required List<UserScript> userScripts}) async {
    assert(_webview?.windowId == null ||
        defaultTargetPlatform != TargetPlatform.iOS);

    for (var i = 0; i < userScripts.length; i++) {
      await addUserScript(userScript: userScripts[i]);
    }
  }

  ///Removes the specified [userScript] from the webpage’s content.
  ///User scripts already loaded into the webpage's content cannot be removed. This will have effect only on the next page load.
  ///Returns `true` if [userScript] was in the list, `false` otherwise.
  ///
  ///**NOTE for iOS**: this method will throw an error if the [WebView.windowId] has been set.
  ///There isn't any way to add/remove user scripts specific to iOS window WebViews.
  ///This is a limitation of the native iOS WebKit APIs.
  Future<bool> removeUserScript({required UserScript userScript}) async {
    assert(_webview?.windowId == null ||
        defaultTargetPlatform != TargetPlatform.iOS);

    var index = _userScripts.indexOf(userScript);
    if (index == -1) {
      return false;
    }

    _userScripts.remove(userScript);
    Map<String, dynamic> args = <String, dynamic>{};
    args.putIfAbsent('userScript', () => userScript.toMap());
    args.putIfAbsent('index', () => index);
    await _channel.invokeMethod('removeUserScript', args);

    return true;
  }

  ///Removes all the [UserScript]s with [groupName] as group name from the webpage’s content.
  ///User scripts already loaded into the webpage's content cannot be removed. This will have effect only on the next page load.
  ///
  ///**NOTE for iOS**: this method will throw an error if the [WebView.windowId] has been set.
  ///There isn't any way to add/remove user scripts specific to iOS window WebViews.
  ///This is a limitation of the native iOS WebKit APIs.
  Future<void> removeUserScriptsByGroupName({required String groupName}) async {
    assert(_webview?.windowId == null ||
        defaultTargetPlatform != TargetPlatform.iOS);

    Map<String, dynamic> args = <String, dynamic>{};
    args.putIfAbsent('groupName', () => groupName);
    await _channel.invokeMethod('removeUserScriptsByGroupName', args);
  }

  ///Removes the [userScripts] from the webpage’s content.
  ///User scripts already loaded into the webpage's content cannot be removed. This will have effect only on the next page load.
  ///
  ///**NOTE for iOS**: this method will throw an error if the [WebView.windowId] has been set.
  ///There isn't any way to add/remove user scripts specific to iOS window WebViews.
  ///This is a limitation of the native iOS WebKit APIs.
  Future<void> removeUserScripts(
      {required List<UserScript> userScripts}) async {
    assert(_webview?.windowId == null ||
        defaultTargetPlatform != TargetPlatform.iOS);

    for (var i = 0; i < userScripts.length; i++) {
      await removeUserScript(userScript: userScripts[i]);
    }
  }

  ///Removes all the user scripts from the webpage’s content.
  ///
  ///**NOTE for iOS**: this method will throw an error if the [WebView.windowId] has been set.
  ///There isn't any way to add/remove user scripts specific to iOS window WebViews.
  ///This is a limitation of the native iOS WebKit APIs.
  ///
  ///**Official iOS API**: https://developer.apple.com/documentation/webkit/wkusercontentcontroller/1536540-removealluserscripts
  Future<void> removeAllUserScripts() async {
    assert(_webview?.windowId == null ||
        defaultTargetPlatform != TargetPlatform.iOS);

    _userScripts.clear();
    Map<String, dynamic> args = <String, dynamic>{};
    await _channel.invokeMethod('removeAllUserScripts', args);
  }

  ///Executes the specified string as an asynchronous JavaScript function.
  ///
  ///[functionBody] is the JavaScript string to use as the function body.
  ///This method treats the string as an anonymous JavaScript function body and calls it with the named arguments in the arguments parameter.
  ///
  ///[arguments] is a dictionary of the arguments to pass to the function call.
  ///Each key in the dictionary corresponds to the name of an argument in the [functionBody] string,
  ///and the value of that key is the value to use during the evaluation of the code.
  ///Supported value types can be found in the official Flutter docs:
  ///[Platform channel data types support and codecs](https://flutter.dev/docs/development/platform-integration/platform-channels#codec),
  ///except for [Uint8List], [Int32List], [Int64List], and [Float64List] that should be converted into a [List].
  ///All items in an array or dictionary must also be one of the supported types.
  ///
  ///[contentWorld], on iOS, it represents the namespace in which to evaluate the JavaScript [source] code.
  ///Instead, on Android, it will run the [source] code into an iframe.
  ///This parameter doesn’t apply to changes you make to the underlying web content, such as the document’s DOM structure.
  ///Those changes remain visible to all scripts, regardless of which content world you specify.
  ///For more information about content worlds, see [ContentWorld].
  ///Available on iOS 14.0+.
  ///
  ///**NOTE for iOS**: available only on iOS 10.3+.
  ///
  ///**NOTE for Android**: available only on Android 21+.
  ///
  ///**Official iOS API**: https://developer.apple.com/documentation/webkit/wkwebview/3656441-callasyncjavascript
  Future<CallAsyncJavaScriptResult?> callAsyncJavaScript(
      {required String functionBody,
      Map<String, dynamic> arguments = const <String, dynamic>{},
      ContentWorld? contentWorld}) async {
    Map<String, dynamic> args = <String, dynamic>{};
    args.putIfAbsent('functionBody', () => functionBody);
    args.putIfAbsent('arguments', () => arguments);
    args.putIfAbsent('contentWorld', () => contentWorld?.toMap());
    var data = await _channel.invokeMethod('callAsyncJavaScript', args);
    if (data == null) {
      return null;
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      data = json.decode(data);
    }
    return CallAsyncJavaScriptResult(
        value: data["value"], error: data["error"]);
  }

  ///Saves the current WebView as a web archive.
  ///Returns the file path under which the web archive file was saved, or `null` if saving the file failed.
  ///
  ///[filePath] represents the file path where the archive should be placed. This value cannot be `null`.
  ///
  ///[autoname] if `false`, takes [filePath] to be a file.
  ///If `true`, [filePath] is assumed to be a directory in which a filename will be chosen according to the URL of the current page.
  ///
  ///**NOTE for iOS**: Available on iOS 14.0+. If [autoname] is `false`, the [filePath] must ends with the [WebArchiveFormat.WEBARCHIVE] file extension.
  ///
  ///**NOTE for Android**: if [autoname] is `false`, the [filePath] must ends with the [WebArchiveFormat.MHT] file extension.
  ///
  ///**Official Android API**: https://developer.android.com/reference/android/webkit/WebView#saveWebArchive(java.lang.String,%20boolean,%20android.webkit.ValueCallback%3Cjava.lang.String%3E)
  Future<String?> saveWebArchive(
      {required String filePath, bool autoname = false}) async {
    if (!autoname) {
      if (defaultTargetPlatform == TargetPlatform.android) {
        assert(filePath.endsWith("." + WebArchiveFormat.MHT.toValue()));
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        assert(filePath.endsWith("." + WebArchiveFormat.WEBARCHIVE.toValue()));
      }
    }

    Map<String, dynamic> args = <String, dynamic>{};
    args.putIfAbsent("filePath", () => filePath);
    args.putIfAbsent("autoname", () => autoname);
    return await _channel.invokeMethod('saveWebArchive', args);
  }

  ///Indicates whether the webpage context is capable of using features that require [secure contexts](https://developer.mozilla.org/en-US/docs/Web/Security/Secure_Contexts).
  ///This is implemented using Javascript (see [window.isSecureContext](https://developer.mozilla.org/en-US/docs/Web/API/Window/isSecureContext)).
  ///
  ///**NOTE for Android**: available Android 21.0+.
  Future<bool> isSecureContext() async {
    Map<String, dynamic> args = <String, dynamic>{};
    return await _channel.invokeMethod('isSecureContext', args);
  }

  ///Gets the default user agent.
  ///
  ///**Official Android API**: https://developer.android.com/reference/android/webkit/WebSettings#getDefaultUserAgent(android.content.Context)
  static Future<String> getDefaultUserAgent() async {
    Map<String, dynamic> args = <String, dynamic>{};
    return await _staticChannel.invokeMethod('getDefaultUserAgent', args);
  }
}
