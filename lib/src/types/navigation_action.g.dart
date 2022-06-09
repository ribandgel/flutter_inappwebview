// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'navigation_action.dart';

// **************************************************************************
// ExchangeableObjectGenerator
// **************************************************************************

///An object that contains information about an action that causes navigation to occur.
class NavigationAction {
  ///The URL request object associated with the navigation action.
  ///
  ///**NOTE for Android**: If the request is associated to the [WebView.onCreateWindow] event
  ///and the window has been created using JavaScript, [request.url] will be `null`,
  ///the [request.method] is always `GET`, and [request.headers] value is always `null`.
  ///Also, on Android < 21, the [request.method]  is always `GET` and [request.headers] value is always `null`.
  URLRequest request;

  ///Indicates whether the request was made for the main frame.
  ///
  ///**NOTE for Android**: If the request is associated to the [WebView.onCreateWindow] event, this is always `true`.
  ///Also, on Android < 21, this is always `true`.
  bool isForMainFrame;

  ///Use [hasGesture] instead.
  @Deprecated('Use hasGesture instead')
  bool? androidHasGesture;

  ///Gets whether a gesture (such as a click) was associated with the request.
  ///For security reasons in certain situations this method may return `false` even though
  ///the sequence of events which caused the request to be created was initiated by a user
  ///gesture.
  ///
  ///**NOTE for Android native WebView**: On Android < 21, this is always `false`
  ///
  ///**Supported Platforms/Implementations**:
  ///- Android native WebView 21+ ([Official API - WebResourceRequest.hasGesture](https://developer.android.com/reference/android/webkit/WebResourceRequest#hasGesture()))
  bool? hasGesture;

  ///Use [isRedirect] instead.
  @Deprecated('Use isRedirect instead')
  bool? androidIsRedirect;

  ///Gets whether the request was a result of a server-side redirect.
  ///
  ///**NOTE**: If the request is associated to the [WebView.onCreateWindow] event, this is always `false`.
  ///Also, on Android < 21, this is always `false`.
  ///
  ///**Supported Platforms/Implementations**:
  ///- Android native WebView 21+ ([Official API - WebResourceRequest.isRedirect](https://developer.android.com/reference/android/webkit/WebResourceRequest#isRedirect()))
  bool? isRedirect;

  ///Use [navigationType] instead.
  @Deprecated('Use navigationType instead')
  IOSWKNavigationType? iosWKNavigationType;

  ///The type of action triggering the navigation.ì
  ///
  ///**Supported Platforms/Implementations**:
  ///- iOS ([Official API - WKNavigationAction.navigationType](https://developer.apple.com/documentation/webkit/wknavigationaction/1401914-navigationtype))
  NavigationType? navigationType;

  ///Use [sourceFrame] instead.
  @Deprecated('Use sourceFrame instead')
  IOSWKFrameInfo? iosSourceFrame;

  ///The frame that requested the navigation.
  ///
  ///**Supported Platforms/Implementations**:
  ///- iOS ([Official API - WKNavigationAction.sourceFrame](https://developer.apple.com/documentation/webkit/wknavigationaction/1401926-sourceframe))
  FrameInfo? sourceFrame;

  ///Use [targetFrame] instead.
  @Deprecated('Use targetFrame instead')
  IOSWKFrameInfo? iosTargetFrame;

  ///The frame in which to display the new content.
  ///
  ///**Supported Platforms/Implementations**:
  ///- iOS ([Official API - WKNavigationAction.targetFrame](https://developer.apple.com/documentation/webkit/wknavigationaction/1401918-targetframe))
  FrameInfo? targetFrame;

  ///A value indicating whether the web content used a download attribute to indicate that this should be downloaded.
  ///
  ///**Supported Platforms/Implementations**:
  ///- iOS 14.5+ ([Official API - WKNavigationAction.shouldPerformDownload](https://developer.apple.com/documentation/webkit/wknavigationaction/3727357-shouldperformdownload))
  bool? shouldPerformDownload;
  NavigationAction(
      {required this.request,
      required this.isForMainFrame,
      @Deprecated('Use hasGesture instead') this.androidHasGesture,
      this.hasGesture,
      @Deprecated('Use isRedirect instead') this.androidIsRedirect,
      this.isRedirect,
      @Deprecated('Use navigationType instead') this.iosWKNavigationType,
      this.navigationType,
      @Deprecated('Use sourceFrame instead') this.iosSourceFrame,
      this.sourceFrame,
      @Deprecated('Use targetFrame instead') this.iosTargetFrame,
      this.targetFrame,
      this.shouldPerformDownload}) {
    hasGesture = hasGesture ?? androidHasGesture;
    isRedirect = isRedirect ?? androidIsRedirect;
    navigationType = navigationType ??
        NavigationType.fromNativeValue(iosWKNavigationType?.toNativeValue());
    sourceFrame = sourceFrame ?? FrameInfo.fromMap(iosSourceFrame?.toMap());
    targetFrame = targetFrame ?? FrameInfo.fromMap(iosTargetFrame?.toMap());
  }

  ///Gets a possible [NavigationAction] instance from a [Map] value.
  static NavigationAction? fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      return null;
    }
    final instance = NavigationAction(
      request: URLRequest.fromMap(map['request']?.cast<String, dynamic>())!,
      isForMainFrame: map['isForMainFrame'],
      androidHasGesture: map['hasGesture'],
      hasGesture: map['hasGesture'],
      androidIsRedirect: map['isRedirect'],
      isRedirect: map['isRedirect'],
      iosWKNavigationType:
          IOSWKNavigationType.fromNativeValue(map['navigationType']),
      navigationType: NavigationType.fromNativeValue(map['navigationType']),
      iosSourceFrame:
          IOSWKFrameInfo.fromMap(map['sourceFrame']?.cast<String, dynamic>()),
      sourceFrame:
          FrameInfo.fromMap(map['sourceFrame']?.cast<String, dynamic>()),
      iosTargetFrame:
          IOSWKFrameInfo.fromMap(map['targetFrame']?.cast<String, dynamic>()),
      targetFrame:
          FrameInfo.fromMap(map['targetFrame']?.cast<String, dynamic>()),
      shouldPerformDownload: map['shouldPerformDownload'],
    );
    return instance;
  }

  ///Converts instance to a map.
  Map<String, dynamic> toMap() {
    return {
      "request": request.toMap(),
      "isForMainFrame": isForMainFrame,
      "hasGesture": hasGesture,
      "isRedirect": isRedirect,
      "navigationType": navigationType?.toNativeValue(),
      "sourceFrame": sourceFrame?.toMap(),
      "targetFrame": targetFrame?.toMap(),
      "shouldPerformDownload": shouldPerformDownload,
    };
  }

  ///Converts instance to a map.
  Map<String, dynamic> toJson() {
    return toMap();
  }

  @override
  String toString() {
    return 'NavigationAction{request: $request, isForMainFrame: $isForMainFrame, hasGesture: $hasGesture, isRedirect: $isRedirect, navigationType: $navigationType, sourceFrame: $sourceFrame, targetFrame: $targetFrame, shouldPerformDownload: $shouldPerformDownload}';
  }
}
