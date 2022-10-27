import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_test/flutter_test.dart';

void loadAssetFile(InAppLocalhostServer localhostServer) {
  final shouldSkip = kIsWeb
      ? true
      : ![
          TargetPlatform.android,
          TargetPlatform.iOS,
          TargetPlatform.macOS,
        ].contains(defaultTargetPlatform);

  testWidgets('load asset file', (WidgetTester tester) async {
    expect(localhostServer.isRunning(), true);

    final Completer<InAppWebViewController> controllerCompleter =
        Completer<InAppWebViewController>();

    var headlessWebView = new HeadlessInAppWebView(
      initialUrlRequest: URLRequest(
          url: WebUri('http://localhost:8080/test_assets/index.html')),
      onWebViewCreated: (controller) {
        controllerCompleter.complete(controller);
      },
    );

    if (defaultTargetPlatform == TargetPlatform.macOS) {
      await headlessWebView.run();
    } else {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: InAppWebView(
            key: GlobalKey(),
            initialUrlRequest: URLRequest(
                url: WebUri('http://localhost:8080/test_assets/index.html')),
            onWebViewCreated: (controller) {
              controllerCompleter.complete(controller);
            },
          ),
        ),
      );
    }
    final InAppWebViewController controller = await controllerCompleter.future;
    final String? currentUrl = (await controller.getUrl())?.toString();
    expect(currentUrl, 'http://localhost:8080/test_assets/index.html');

    if (defaultTargetPlatform == TargetPlatform.macOS) {
      await headlessWebView.dispose();
    }
  }, skip: shouldSkip);
}
