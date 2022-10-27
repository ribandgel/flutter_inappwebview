import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider/path_provider.dart';

void loadFileUrl() {
  final shouldSkip = kIsWeb
      ? true
      : ![
          TargetPlatform.iOS,
          TargetPlatform.macOS,
        ].contains(defaultTargetPlatform);

  group('load file URL', () {
    late Directory appSupportDir;
    late File fileHtml;
    late File fileJs;

    setUpAll(() async {
      appSupportDir = (await getApplicationSupportDirectory());

      final Directory htmlFolder = Directory('${appSupportDir.path}/html/');
      if (!await htmlFolder.exists()) {
        await htmlFolder.create(recursive: true);
      }

      final Directory jsFolder = Directory('${appSupportDir.path}/js/');
      if (!await jsFolder.exists()) {
        await jsFolder.create(recursive: true);
      }

      var html = """
      <!DOCTYPE html><html>
      <head>
        <title>file scheme</title>
      </head>
      <body>
        <script src="../js/main.js"></script>
      </body>
      </html>
    """;
      fileHtml = File(htmlFolder.path + "index.html");
      fileHtml.writeAsStringSync(html);

      var js = """
      console.log('message');
      """;
      fileJs = File(jsFolder.path + "main.js");
      fileJs.writeAsStringSync(js);
    });

    testWidgets('initialUrl with file:// scheme and allowingReadAccessTo',
        (WidgetTester tester) async {
      final Completer<ConsoleMessage?> consoleMessageShouldNotComplete =
          Completer<ConsoleMessage?>();
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: InAppWebView(
            key: GlobalKey(),
            initialUrlRequest:
                URLRequest(url: WebUri('file://${fileHtml.path}')),
            onConsoleMessage: (controller, consoleMessage) {
              consoleMessageShouldNotComplete.complete(consoleMessage);
            },
          ),
        ),
      );
      var result = await consoleMessageShouldNotComplete.future
          .timeout(const Duration(seconds: 2), onTimeout: () => null);
      expect(result, null);

      final Completer<ConsoleMessage> consoleMessageCompleter =
          Completer<ConsoleMessage>();
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: InAppWebView(
            key: GlobalKey(),
            initialUrlRequest:
                URLRequest(url: WebUri('file://${fileHtml.path}')),
            initialSettings: InAppWebViewSettings(
                allowingReadAccessTo: WebUri('file://${appSupportDir.path}/')),
            onConsoleMessage: (controller, consoleMessage) {
              consoleMessageCompleter.complete(consoleMessage);
            },
          ),
        ),
      );
      final ConsoleMessage consoleMessage =
          await consoleMessageCompleter.future;
      expect(consoleMessage.messageLevel, ConsoleMessageLevel.LOG);
      expect(consoleMessage.message, 'message');
    });

    testWidgets('loadUrl with file:// scheme and allowingReadAccessTo argument',
        (WidgetTester tester) async {
      final Completer<ConsoleMessage?> consoleMessageShouldNotComplete =
          Completer<ConsoleMessage?>();
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: InAppWebView(
            key: GlobalKey(),
            onWebViewCreated: (controller) {
              controller.loadUrl(
                  urlRequest:
                      URLRequest(url: WebUri('file://${fileHtml.path}')));
            },
            onConsoleMessage: (controller, consoleMessage) {
              consoleMessageShouldNotComplete.complete(consoleMessage);
            },
          ),
        ),
      );
      var result = await consoleMessageShouldNotComplete.future
          .timeout(const Duration(seconds: 2), onTimeout: () => null);
      expect(result, null);

      final Completer<ConsoleMessage> consoleMessageCompleter =
          Completer<ConsoleMessage>();
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: InAppWebView(
            key: GlobalKey(),
            onWebViewCreated: (controller) {
              controller.loadUrl(
                  urlRequest:
                      URLRequest(url: WebUri('file://${fileHtml.path}')),
                  allowingReadAccessTo:
                      WebUri('file://${appSupportDir.path}/'));
            },
            onConsoleMessage: (controller, consoleMessage) {
              consoleMessageCompleter.complete(consoleMessage);
            },
          ),
        ),
      );
      final ConsoleMessage consoleMessage =
          await consoleMessageCompleter.future;
      expect(consoleMessage.messageLevel, ConsoleMessageLevel.LOG);
      expect(consoleMessage.message, 'message');
    });
  }, skip: shouldSkip);
}
