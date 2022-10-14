import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_test/flutter_test.dart';

import '../constants.dart';

void onConsoleMessage() {
  final shouldSkip = kIsWeb
      ? false
      : ![
          TargetPlatform.android,
          TargetPlatform.iOS,
          TargetPlatform.macOS,
        ].contains(defaultTargetPlatform);

  testWidgets('onConsoleMessage', (WidgetTester tester) async {
    final Completer<InAppWebViewController> controllerCompleter =
        Completer<InAppWebViewController>();
    final Completer<ConsoleMessage> onConsoleMessageCompleter =
        Completer<ConsoleMessage>();
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: InAppWebView(
          key: GlobalKey(),
          initialFile: !kIsWeb
              ? "test_assets/in_app_webview_on_console_message_test.html"
              : null,
          initialUrlRequest:
              kIsWeb ? URLRequest(url: TEST_WEB_PLATFORM_URL_1) : null,
          onWebViewCreated: (controller) {
            controllerCompleter.complete(controller);
          },
          onConsoleMessage: (controller, consoleMessage) {
            onConsoleMessageCompleter.complete(consoleMessage);
          },
        ),
      ),
    );

    final ConsoleMessage consoleMessage =
        await onConsoleMessageCompleter.future;
    expect(consoleMessage.message, 'message');
    expect(consoleMessage.messageLevel, ConsoleMessageLevel.LOG);
  }, skip: shouldSkip);
}
