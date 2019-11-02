package com.pichillilorenzo.flutter_inappbrowser.InAppWebView;

import android.content.Intent;
import android.graphics.Bitmap;
import android.net.Uri;
import android.net.http.SslCertificate;
import android.net.http.SslError;
import android.os.Build;
import android.os.Bundle;
import android.util.Base64;
import android.util.Log;
import android.webkit.ClientCertRequest;
import android.webkit.CookieManager;
import android.webkit.CookieSyncManager;
import android.webkit.HttpAuthHandler;
import android.webkit.SafeBrowsingResponse;
import android.webkit.SslErrorHandler;
import android.webkit.ValueCallback;
import android.webkit.WebResourceRequest;
import android.webkit.WebResourceResponse;
import android.webkit.WebView;
import android.webkit.WebViewClient;

import androidx.annotation.RequiresApi;

import com.pichillilorenzo.flutter_inappbrowser.CredentialDatabase.Credential;
import com.pichillilorenzo.flutter_inappbrowser.CredentialDatabase.CredentialDatabase;
import com.pichillilorenzo.flutter_inappbrowser.FlutterWebView;
import com.pichillilorenzo.flutter_inappbrowser.InAppBrowserActivity;
import com.pichillilorenzo.flutter_inappbrowser.InAppBrowserFlutterPlugin;
import com.pichillilorenzo.flutter_inappbrowser.JavaScriptBridgeInterface;
import com.pichillilorenzo.flutter_inappbrowser.Util;

import java.io.ByteArrayInputStream;
import java.net.MalformedURLException;
import java.net.URL;
import java.security.cert.Certificate;
import java.security.cert.CertificateEncodingException;
import java.security.cert.CertificateException;
import java.security.cert.CertificateFactory;
import java.security.cert.X509Certificate;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import io.flutter.plugin.common.MethodChannel;

public class InAppWebViewClient extends WebViewClient {

  protected static final String LOG_TAG = "IABWebViewClient";
  private FlutterWebView flutterWebView;
  private InAppBrowserActivity inAppBrowserActivity;
  Map<Integer, String> statusCodeMapping = new HashMap<Integer, String>();
  long startPageTime = 0;
  private static int previousAuthRequestFailureCount = 0;
  private static List<Credential> credentialsProposed = null;

  public InAppWebViewClient(Object obj) {
    super();
    if (obj instanceof InAppBrowserActivity)
      this.inAppBrowserActivity = (InAppBrowserActivity) obj;
    else if (obj instanceof FlutterWebView)
      this.flutterWebView = (FlutterWebView) obj;
    prepareStatusCodeMapping();
  }

  private void prepareStatusCodeMapping() {
    statusCodeMapping.put(100, "Continue");
    statusCodeMapping.put(101, "Switching Protocols");
    statusCodeMapping.put(200, "OK");
    statusCodeMapping.put(201, "Created");
    statusCodeMapping.put(202, "Accepted");
    statusCodeMapping.put(203, "Non-Authoritative Information");
    statusCodeMapping.put(204, "No Content");
    statusCodeMapping.put(205, "Reset Content");
    statusCodeMapping.put(206, "Partial Content");
    statusCodeMapping.put(300, "Multiple Choices");
    statusCodeMapping.put(301, "Moved Permanently");
    statusCodeMapping.put(302, "Found");
    statusCodeMapping.put(303, "See Other");
    statusCodeMapping.put(304, "Not Modified");
    statusCodeMapping.put(307, "Temporary Redirect");
    statusCodeMapping.put(308, "Permanent Redirect");
    statusCodeMapping.put(400, "Bad Request");
    statusCodeMapping.put(401, "Unauthorized");
    statusCodeMapping.put(403, "Forbidden");
    statusCodeMapping.put(404, "Not Found");
    statusCodeMapping.put(405, "Method Not Allowed");
    statusCodeMapping.put(406, "Not Acceptable");
    statusCodeMapping.put(407, "Proxy Authentication Required");
    statusCodeMapping.put(408, "Request Timeout");
    statusCodeMapping.put(409, "Conflict");
    statusCodeMapping.put(410, "Gone");
    statusCodeMapping.put(411, "Length Required");
    statusCodeMapping.put(412, "Precondition Failed");
    statusCodeMapping.put(413, "Payload Too Large");
    statusCodeMapping.put(414, "URI Too Long");
    statusCodeMapping.put(415, "Unsupported Media Type");
    statusCodeMapping.put(416, "Range Not Satisfiable");
    statusCodeMapping.put(417, "Expectation Failed");
    statusCodeMapping.put(418, "I'm a teapot");
    statusCodeMapping.put(422, "Unprocessable Entity");
    statusCodeMapping.put(425, "Too Early");
    statusCodeMapping.put(426, "Upgrade Required");
    statusCodeMapping.put(428, "Precondition Required");
    statusCodeMapping.put(429, "Too Many Requests");
    statusCodeMapping.put(431, "Request Header Fields Too Large");
    statusCodeMapping.put(451, "Unavailable For Legal Reasons");
    statusCodeMapping.put(500, "Internal Server Error");
    statusCodeMapping.put(501, "Not Implemented");
    statusCodeMapping.put(502, "Bad Gateway");
    statusCodeMapping.put(503, "Service Unavailable");
    statusCodeMapping.put(504, "Gateway Timeout");
    statusCodeMapping.put(505, "HTTP Version Not Supported");
    statusCodeMapping.put(511, "Network Authentication Required");
  }

  @Override
  public boolean shouldOverrideUrlLoading(WebView webView, String url) {

    if (((inAppBrowserActivity != null) ? inAppBrowserActivity.webView : flutterWebView.webView).options.useShouldOverrideUrlLoading) {
      Map<String, Object> obj = new HashMap<>();
      if (inAppBrowserActivity != null)
        obj.put("uuid", inAppBrowserActivity.uuid);
      obj.put("url", url);
      getChannel().invokeMethod("shouldOverrideUrlLoading", obj);
      return true;
    }

    if (url != null) {
      if (url.startsWith(WebView.SCHEME_TEL)) {
        try {
          Intent intent = new Intent(Intent.ACTION_DIAL);
          intent.setData(Uri.parse(url));
          ((inAppBrowserActivity != null) ? inAppBrowserActivity : flutterWebView.activity).startActivity(intent);
          return true;
        } catch (android.content.ActivityNotFoundException e) {
          Log.e(LOG_TAG, "Error dialing " + url + ": " + e.toString());
        }
      } else if (url.startsWith("geo:") || url.startsWith(WebView.SCHEME_MAILTO) || url.startsWith("market:") || url.startsWith("intent:")) {
        try {
          Intent intent = new Intent(Intent.ACTION_VIEW);
          intent.setData(Uri.parse(url));
          ((inAppBrowserActivity != null) ? inAppBrowserActivity : flutterWebView.activity).startActivity(intent);
          return true;
        } catch (android.content.ActivityNotFoundException e) {
          Log.e(LOG_TAG, "Error with " + url + ": " + e.toString());
        }
      }
      // If sms:5551212?body=This is the message
      else if (url.startsWith("sms:")) {
        try {
          Intent intent = new Intent(Intent.ACTION_VIEW);

          // Get address
          String address;
          int parmIndex = url.indexOf('?');
          if (parmIndex == -1) {
            address = url.substring(4);
          } else {
            address = url.substring(4, parmIndex);

            // If body, then set sms body
            Uri uri = Uri.parse(url);
            String query = uri.getQuery();
            if (query != null) {
              if (query.startsWith("body=")) {
                intent.putExtra("sms_body", query.substring(5));
              }
            }
          }
          intent.setData(Uri.parse("sms:" + address));
          intent.putExtra("address", address);
          intent.setType("vnd.android-dir/mms-sms");
          ((inAppBrowserActivity != null) ? inAppBrowserActivity : flutterWebView.activity).startActivity(intent);
          return true;
        } catch (android.content.ActivityNotFoundException e) {
          Log.e(LOG_TAG, "Error sending sms " + url + ":" + e.toString());
        }
      }
    }

    return super.shouldOverrideUrlLoading(webView, url);
  }


  /*
   * onPageStarted fires the LOAD_START_EVENT
   *
   * @param view
   * @param url
   * @param favicon
   */
  @Override
  public void onPageStarted(WebView view, String url, Bitmap favicon) {

    InAppWebView webView = (InAppWebView) view;

    if (webView.options.useOnLoadResource)
      webView.loadUrl("javascript:" + webView.resourceObserverJS.replaceAll("[\r\n]+", ""));

    super.onPageStarted(view, url, favicon);

    startPageTime = System.currentTimeMillis();
    webView.isLoading = true;
    if (inAppBrowserActivity != null && inAppBrowserActivity.searchView != null && !url.equals(inAppBrowserActivity.searchView.getQuery().toString())) {
      inAppBrowserActivity.searchView.setQuery(url, false);
    }

    Map<String, Object> obj = new HashMap<>();
    if (inAppBrowserActivity != null)
      obj.put("uuid", inAppBrowserActivity.uuid);
    obj.put("url", url);
    getChannel().invokeMethod("onLoadStart", obj);
  }


  public void onPageFinished(final WebView view, String url) {
    InAppWebView webView = (InAppWebView) view;

    super.onPageFinished(view, url);

    webView.isLoading = false;
    previousAuthRequestFailureCount = 0;
    credentialsProposed = null;

    // CB-10395 InAppBrowser's WebView not storing cookies reliable to local device storage
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
      CookieManager.getInstance().flush();
    } else {
      CookieSyncManager.getInstance().sync();
    }

    // https://issues.apache.org/jira/browse/CB-11248
    view.clearFocus();
    view.requestFocus();

    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT) {
      view.evaluateJavascript(InAppWebView.consoleLogJS, null);
      view.evaluateJavascript(JavaScriptBridgeInterface.flutterInAppBroserJSClass, new ValueCallback<String>() {
        @Override
        public void onReceiveValue(String value) {
          view.evaluateJavascript(InAppWebView.platformReadyJS, null);
        }
      });

    } else {
      view.loadUrl("javascript:" + InAppWebView.consoleLogJS);
      view.loadUrl("javascript:" + JavaScriptBridgeInterface.flutterInAppBroserJSClass);
      view.loadUrl("javascript:" + InAppWebView.platformReadyJS);
    }

    Map<String, Object> obj = new HashMap<>();
    if (inAppBrowserActivity != null)
      obj.put("uuid", inAppBrowserActivity.uuid);
    obj.put("url", url);
    getChannel().invokeMethod("onLoadStop", obj);
  }

  public void onReceivedError(WebView view, int errorCode, String description, String failingUrl) {
    super.onReceivedError(view, errorCode, description, failingUrl);

    ((inAppBrowserActivity != null) ? inAppBrowserActivity.webView : flutterWebView.webView).isLoading = false;
    previousAuthRequestFailureCount = 0;
    credentialsProposed = null;

    Map<String, Object> obj = new HashMap<>();
    if (inAppBrowserActivity != null)
      obj.put("uuid", inAppBrowserActivity.uuid);
    obj.put("url", failingUrl);
    obj.put("code", errorCode);
    obj.put("message", description);
    getChannel().invokeMethod("onLoadError", obj);
  }

  /**
   * On received http auth request.
   */
  @Override
  public void onReceivedHttpAuthRequest(final WebView view, final HttpAuthHandler handler, final String host, final String realm) {

    URL url;
    try {
      url = new URL(view.getUrl());
    } catch (MalformedURLException e) {
      e.printStackTrace();
      Log.e(LOG_TAG, e.getMessage());

      credentialsProposed = null;
      previousAuthRequestFailureCount = 0;

      handler.cancel();
      return;
    }

    final String protocol = url.getProtocol();
    final int port = url.getPort();

    previousAuthRequestFailureCount++;

    Map<String, Object> obj = new HashMap<>();
    if (inAppBrowserActivity != null)
      obj.put("uuid", inAppBrowserActivity.uuid);
    obj.put("host", host);
    obj.put("protocol", protocol);
    obj.put("realm", realm);
    obj.put("port", port);
    obj.put("previousFailureCount", previousAuthRequestFailureCount);

    getChannel().invokeMethod("onReceivedHttpAuthRequest", obj, new MethodChannel.Result() {
      @Override
      public void success(Object response) {
        if (response != null) {
          Map<String, Object> responseMap = (Map<String, Object>) response;
          Integer action = (Integer) responseMap.get("action");
          if (action != null) {
            switch (action) {
              case 1:
                String username = (String) responseMap.get("username");
                String password = (String) responseMap.get("password");
                Boolean permanentPersistence = (Boolean) responseMap.get("permanentPersistence");
                if (permanentPersistence != null && permanentPersistence && Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                  CredentialDatabase.getInstance(view.getContext()).setHttpAuthCredential(host, protocol, realm, port, username, password);
                }
                handler.proceed(username, password);
                return;
              case 2:
                if (credentialsProposed == null)
                  credentialsProposed = CredentialDatabase.getInstance(view.getContext()).getHttpAuthCredentials(host, protocol, realm, port);
                if (credentialsProposed.size() > 0) {
                  Credential credential = credentialsProposed.remove(0);
                  handler.proceed(credential.username, credential.password);
                } else {
                  handler.cancel();
                }
                //handler.useHttpAuthUsernamePassword();
                return;
              case 0:
              default:
                credentialsProposed = null;
                previousAuthRequestFailureCount = 0;
                handler.cancel();
                return;
            }
          }
        }

        handler.cancel();
      }

      @Override
      public void error(String s, String s1, Object o) {
        Log.e(LOG_TAG, s + ", " + s1);
      }

      @Override
      public void notImplemented() {
        handler.cancel();
      }
    });
  }

  /**
   * SslCertificate class does not has a public getter for the underlying
   * X509Certificate, we can only do this by hack. This only works for andorid 4.0+
   * https://groups.google.com/forum/#!topic/android-developers/eAPJ6b7mrmg
   */
  public static X509Certificate getX509CertFromSslCertHack(SslCertificate sslCert) {
    X509Certificate x509Certificate = null;

    Bundle bundle = SslCertificate.saveState(sslCert);
    byte[] bytes = bundle.getByteArray("x509-certificate");

    if (bytes == null) {
      x509Certificate = null;
    } else {
      try {
        CertificateFactory certFactory = CertificateFactory.getInstance("X.509");
        Certificate cert = certFactory.generateCertificate(new ByteArrayInputStream(bytes));
        x509Certificate = (X509Certificate) cert;
      } catch (CertificateException e) {
        x509Certificate = null;
      }
    }

    return x509Certificate;
  }

  @Override
  public void onReceivedSslError(final WebView view, final SslErrorHandler handler, final SslError error) {
    URL url;
    try {
      url = new URL(error.getUrl());
    } catch (MalformedURLException e) {
      e.printStackTrace();
      Log.e(LOG_TAG, e.getMessage());
      handler.cancel();
      return;
    }

    final String host = url.getHost();
    final String protocol = url.getProtocol();
    final String realm = null;
    final int port = url.getPort();

    Map<String, Object> obj = new HashMap<>();
    if (inAppBrowserActivity != null)
      obj.put("uuid", inAppBrowserActivity.uuid);
    obj.put("host", host);
    obj.put("protocol", protocol);
    obj.put("realm", realm);
    obj.put("port", port);
    obj.put("error", error.getPrimaryError());
    obj.put("serverCertificate", null);
    try {
      X509Certificate certificate;
      if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
        certificate = error.getCertificate().getX509Certificate();
      } else {
        certificate = getX509CertFromSslCertHack(error.getCertificate());
      }
      obj.put("serverCertificate", certificate.getEncoded());
    } catch (CertificateEncodingException e) {
      e.printStackTrace();
      Log.e(LOG_TAG,e.getLocalizedMessage());
    }

    String message;
    switch (error.getPrimaryError()) {
      case SslError.SSL_DATE_INVALID:
        message = "The date of the certificate is invalid";
        break;
      case SslError.SSL_EXPIRED:
        message = "The certificate has expired";
        break;
      case SslError.SSL_IDMISMATCH:
        message = "Hostname mismatch";
        break;
      default:
      case SslError.SSL_INVALID:
        message = "A generic error occurred";
        break;
      case SslError.SSL_NOTYETVALID:
        message = "The certificate is not yet valid";
        break;
      case SslError.SSL_UNTRUSTED:
        message = "The certificate authority is not trusted";
        break;
    }
    obj.put("message", message);

    Log.d(LOG_TAG, obj.toString());

    getChannel().invokeMethod("onReceivedServerTrustAuthRequest", obj, new MethodChannel.Result() {
      @Override
      public void success(Object response) {
        if (response != null) {
          Map<String, Object> responseMap = (Map<String, Object>) response;
          Integer action = (Integer) responseMap.get("action");
          if (action != null) {
            switch (action) {
              case 1:
                handler.proceed();
                return;
              case 0:
              default:
                handler.cancel();
                return;
            }
          }
        }

        handler.cancel();
      }

      @Override
      public void error(String s, String s1, Object o) {
        Log.e(LOG_TAG, s + ", " + s1);
      }

      @Override
      public void notImplemented() {
        handler.cancel();
      }
    });
  }

  @RequiresApi(api = Build.VERSION_CODES.LOLLIPOP)
  @Override
  public void onReceivedClientCertRequest(final WebView view, final ClientCertRequest request) {

    URL url;
    try {
      url = new URL(view.getUrl());
    } catch (MalformedURLException e) {
      e.printStackTrace();
      Log.e(LOG_TAG, e.getMessage());
      request.cancel();
      return;
    }

    final String protocol = url.getProtocol();
    final String realm = null;

    Map<String, Object> obj = new HashMap<>();
    if (inAppBrowserActivity != null)
      obj.put("uuid", inAppBrowserActivity.uuid);
    obj.put("host", request.getHost());
    obj.put("protocol", protocol);
    obj.put("realm", realm);
    obj.put("port", request.getPort());

    getChannel().invokeMethod("onReceivedClientCertRequest", obj, new MethodChannel.Result() {
      @Override
      public void success(Object response) {
        if (response != null) {
          Map<String, Object> responseMap = (Map<String, Object>) response;
          Integer action = (Integer) responseMap.get("action");
          if (action != null) {
            switch (action) {
              case 1:
                {
                  InAppWebView webView = (InAppWebView) view;
                  String certificatePath = (String) responseMap.get("certificatePath");
                  String certificatePassword = (String) responseMap.get("certificatePassword");
                  String androidKeyStoreType = (String) responseMap.get("androidKeyStoreType");
                  Util.PrivateKeyAndCertificates privateKeyAndCertificates = Util.loadPrivateKeyAndCertificate(webView.registrar, certificatePath, certificatePassword, androidKeyStoreType);
                  request.proceed(privateKeyAndCertificates.privateKey, privateKeyAndCertificates.certificates);
                }
                return;
              case 2:
                request.ignore();
                return;
              case 0:
              default:
                request.cancel();
                return;
            }
          }
        }

        request.cancel();
      }

      @Override
      public void error(String s, String s1, Object o) {
        Log.e(LOG_TAG, s + ", " + s1);
      }

      @Override
      public void notImplemented() {
        request.cancel();
      }
    });
  }

  @Override
  public void onScaleChanged(WebView view, float oldScale, float newScale) {
    final InAppWebView webView = (InAppWebView) view;
    webView.scale = newScale;
  }

  @RequiresApi(api = Build.VERSION_CODES.O_MR1)
  @Override
  public void onSafeBrowsingHit(final WebView view, WebResourceRequest request, int threatType, final SafeBrowsingResponse callback) {
    Map<String, Object> obj = new HashMap<>();
    if (inAppBrowserActivity != null)
      obj.put("uuid", inAppBrowserActivity.uuid);
    obj.put("url", request.getUrl().toString());
    obj.put("threatType", threatType);

    getChannel().invokeMethod("onSafeBrowsingHit", obj, new MethodChannel.Result() {
      @Override
      public void success(Object response) {
        if (response != null) {
          Map<String, Object> responseMap = (Map<String, Object>) response;
          Boolean report = (Boolean) responseMap.get("report");
          Integer action = (Integer) responseMap.get("action");

          report = report != null ? report : true;

          if (action != null) {
            switch (action) {
              case 0:
                callback.backToSafety(report);
                return;
              case 1:
                callback.proceed(report);
                return;
              case 2:
              default:
                callback.showInterstitial(report);
                return;
            }
          }
        }

        callback.showInterstitial(true);
      }

      @Override
      public void error(String s, String s1, Object o) {
        Log.e(LOG_TAG, s + ", " + s1);
      }

      @Override
      public void notImplemented() {
        callback.showInterstitial(true);
      }
    });
  }

  @RequiresApi(api = Build.VERSION_CODES.LOLLIPOP)
  @Override
  public WebResourceResponse shouldInterceptRequest(WebView view, WebResourceRequest request) {

    final InAppWebView webView = (InAppWebView) view;

    final String url = request.getUrl().toString();
    String scheme = request.getUrl().getScheme();

    if (webView.options.resourceCustomSchemes != null && webView.options.resourceCustomSchemes.contains(scheme)) {
      final Map<String, Object> obj = new HashMap<>();
      if (inAppBrowserActivity != null)
        obj.put("uuid", inAppBrowserActivity.uuid);
      obj.put("url", url);
      obj.put("scheme", scheme);

      Util.WaitFlutterResult flutterResult;
      try {
        flutterResult = Util.invokeMethodAndWait(getChannel(), "onLoadResourceCustomScheme", obj);
      } catch (InterruptedException e) {
        e.printStackTrace();
        Log.e(LOG_TAG, e.getMessage());
        return null;
      }

      if (flutterResult.error != null) {
        Log.e(LOG_TAG, flutterResult.error);
      }
      else if (flutterResult.result != null) {
        Map<String, String> res = (Map<String, String>) flutterResult.result;
        WebResourceResponse response = null;
        try {
          response = webView.contentBlockerHandler.checkUrl(webView, url, res.get("content-type"));
        } catch (Exception e) {
          e.printStackTrace();
          Log.e(LOG_TAG, e.getMessage());
        }
        if (response != null)
          return response;
        byte[] data = Base64.decode(res.get("base64data"), Base64.DEFAULT);
        return new WebResourceResponse(res.get("content-type"), res.get("content-encoding"), new ByteArrayInputStream(data));
      }
    }

    WebResourceResponse response = null;
    if (webView.contentBlockerHandler.getRuleList().size() > 0) {
      try {
        response = webView.contentBlockerHandler.checkUrl(webView, url);
      } catch (Exception e) {
        e.printStackTrace();
        Log.e(LOG_TAG, e.getMessage());
      }
    }
    return response;
  }

  private MethodChannel getChannel() {
    return (inAppBrowserActivity != null) ? InAppBrowserFlutterPlugin.inAppBrowser.channel : flutterWebView.channel;
  }

}
