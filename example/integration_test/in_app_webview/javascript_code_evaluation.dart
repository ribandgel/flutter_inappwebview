import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_test/flutter_test.dart';

import '../constants.dart';

void javascriptCodeEvaluation() {
  final shouldSkip = kIsWeb
      ? false
      : ![
          TargetPlatform.android,
          TargetPlatform.iOS,
          TargetPlatform.macOS,
        ].contains(defaultTargetPlatform);

  group('javascript code evaluation', () {
    final shouldSkipTest1 = kIsWeb
        ? false
        : ![
            TargetPlatform.android,
            TargetPlatform.iOS,
            TargetPlatform.macOS,
          ].contains(defaultTargetPlatform);

    testWidgets('evaluateJavascript', (WidgetTester tester) async {
      final Completer<InAppWebViewController> controllerCompleter =
          Completer<InAppWebViewController>();
      final Completer<void> pageLoaded = Completer<void>();

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: InAppWebView(
            key: GlobalKey(),
            initialUrlRequest: URLRequest(url: TEST_URL_ABOUT_BLANK),
            onWebViewCreated: (controller) {
              controllerCompleter.complete(controller);
            },
            onLoadStop: (controller, url) {
              pageLoaded.complete();
            },
          ),
        ),
      );
      final InAppWebViewController controller =
          await controllerCompleter.future;
      await pageLoaded.future;

      var result = await controller.evaluateJavascript(source: """
        [1, true, ["bar", 5], {"foo": "baz"}];
      """);
      expect(result, isNotNull);
      expect(result[0], 1);
      expect(result[1], true);
      expect(listEquals(result[2] as List<dynamic>?, ["bar", 5]), true);
      expect(
          mapEquals(result[3]?.cast<String, String>(), {"foo": "baz"}), true);
    }, skip: shouldSkipTest1);

    final shouldSkipTest2 = kIsWeb
        ? true
        : ![
            TargetPlatform.android,
            TargetPlatform.iOS,
            TargetPlatform.macOS,
          ].contains(defaultTargetPlatform);

    testWidgets('evaluateJavascript with content world',
        (WidgetTester tester) async {
      final Completer<InAppWebViewController> controllerCompleter =
          Completer<InAppWebViewController>();
      final Completer<void> pageLoaded = Completer<void>();

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: InAppWebView(
            key: GlobalKey(),
            initialUrlRequest: URLRequest(url: TEST_URL_ABOUT_BLANK),
            onWebViewCreated: (controller) {
              controllerCompleter.complete(controller);
            },
            onLoadStop: (controller, url) {
              pageLoaded.complete();
            },
          ),
        ),
      );
      final InAppWebViewController controller =
          await controllerCompleter.future;
      await pageLoaded.future;

      await controller.evaluateJavascript(
          source: "var foo = 49;",
          contentWorld: ContentWorld.world(name: "custom-world"));
      var result = await controller.evaluateJavascript(source: "foo");
      expect(result, isNull);

      result = await controller.evaluateJavascript(
          source: "foo",
          contentWorld: ContentWorld.world(name: "custom-world"));
      expect(result, 49);
    }, skip: shouldSkipTest2);

    final shouldSkipTest3 = kIsWeb
        ? true
        : ![
            TargetPlatform.android,
            TargetPlatform.iOS,
            TargetPlatform.macOS,
          ].contains(defaultTargetPlatform);

    testWidgets('callAsyncJavaScript', (WidgetTester tester) async {
      final Completer<InAppWebViewController> controllerCompleter =
          Completer<InAppWebViewController>();
      final Completer<void> pageLoaded = Completer<void>();

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: InAppWebView(
            key: GlobalKey(),
            initialUrlRequest: URLRequest(url: TEST_URL_ABOUT_BLANK),
            onWebViewCreated: (controller) {
              controllerCompleter.complete(controller);
            },
            onLoadStop: (controller, url) {
              pageLoaded.complete();
            },
          ),
        ),
      );
      final InAppWebViewController controller =
          await controllerCompleter.future;
      await pageLoaded.future;

      final String functionBody = """
        var p = new Promise(function (resolve, reject) {
           window.setTimeout(function() {
             if (x >= 0) {
               resolve(x);
             } else {
               reject(y);
             }
           }, 1000);
        });
        await p;
        return p;
      """;

      var result = await controller.callAsyncJavaScript(
          functionBody: functionBody,
          arguments: {'x': 49, 'y': 'error message'});
      expect(result, isNotNull);
      expect(result!.error, isNull);
      expect(result.value, 49);

      result = await controller.callAsyncJavaScript(
          functionBody: functionBody,
          arguments: {'x': -49, 'y': 'error message'});
      expect(result, isNotNull);
      expect(result!.value, isNull);
      expect(result.error, 'error message');
    }, skip: shouldSkipTest3);

    final shouldSkipTest4 = kIsWeb
        ? true
        : ![
            TargetPlatform.android,
            TargetPlatform.iOS,
            TargetPlatform.macOS,
          ].contains(defaultTargetPlatform);

    testWidgets('callAsyncJavaScript with content world',
        (WidgetTester tester) async {
      final Completer<InAppWebViewController> controllerCompleter =
          Completer<InAppWebViewController>();
      final Completer<void> pageLoaded = Completer<void>();

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: InAppWebView(
            key: GlobalKey(),
            initialUrlRequest: URLRequest(url: TEST_URL_ABOUT_BLANK),
            onWebViewCreated: (controller) {
              controllerCompleter.complete(controller);
            },
            onLoadStop: (controller, url) {
              pageLoaded.complete();
            },
          ),
        ),
      );
      final InAppWebViewController controller =
          await controllerCompleter.future;
      await pageLoaded.future;

      await controller.callAsyncJavaScript(
          functionBody: "window.foo = 49;",
          contentWorld: ContentWorld.world(name: "custom-world"));
      var result = await controller.callAsyncJavaScript(
          functionBody: "return window.foo;");
      expect(result, isNotNull);
      expect(result!.error, isNull);
      expect(result.value, isNull);

      result = await controller.callAsyncJavaScript(
          functionBody: "return window.foo;",
          contentWorld: ContentWorld.world(name: "custom-world"));
      expect(result, isNotNull);
      expect(result!.error, isNull);
      expect(result.value, 49);
    }, skip: shouldSkipTest4);
  }, skip: shouldSkip);
}
