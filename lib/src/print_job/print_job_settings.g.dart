// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'print_job_settings.dart';

// **************************************************************************
// ExchangeableObjectGenerator
// **************************************************************************

///Class that represents the settings of a [PrintJobController].
class PrintJobSettings {
  ///Set this to `true` to handle the [PrintJobController].
  ///Otherwise, it will be handled and disposed automatically by the system.
  ///The default value is `false`.
  ///
  ///**Supported Platforms/Implementations**:
  ///- Android native WebView
  ///- iOS
  ///- MacOS
  bool? handledByClient;

  ///The name of the print job.
  ///An application should set this property to a name appropriate to the content being printed.
  ///The default job name is the current webpage title concatenated with the "Document" word at the end.
  ///
  ///**Supported Platforms/Implementations**:
  ///- Android native WebView
  ///- iOS
  ///- MacOS
  String? jobName;

  ///`true` to animate the display of the sheet, `false` to display the sheet immediately.
  ///
  ///**Supported Platforms/Implementations**:
  ///- iOS
  bool? animated;

  ///The orientation of the printed content, portrait or landscape.
  ///
  ///**Supported Platforms/Implementations**:
  ///- Android native WebView
  ///- iOS
  ///- MacOS
  PrintJobOrientation? orientation;

  ///The number of pages to render.
  ///
  ///**Supported Platforms/Implementations**:
  ///- iOS
  ///- MacOS
  int? numberOfPages;

  ///Force rendering quality.
  ///
  ///**NOTE for iOS**: available only on iOS 14.5+.
  ///
  ///**Supported Platforms/Implementations**:
  ///- iOS
  PrintJobRenderingQuality? forceRenderingQuality;

  ///The margins for each printed page.
  ///Margins define the white space around the content where the left margin defines
  ///the amount of white space on the left of the content and so on.
  ///
  ///**Supported Platforms/Implementations**:
  ///- iOS
  ///- MacOS
  EdgeInsets? margins;

  ///The media size.
  ///
  ///**Supported Platforms/Implementations**:
  ///- Android native WebView
  PrintJobMediaSize? mediaSize;

  ///The color mode.
  ///
  ///**Supported Platforms/Implementations**:
  ///- Android native WebView
  ///- MacOS
  PrintJobColorMode? colorMode;

  ///The duplex mode to use for the print job.
  ///
  ///**NOTE for Android native WebView**: available only on Android 23+.
  ///
  ///**Supported Platforms/Implementations**:
  ///- Android native WebView
  ///- iOS
  PrintJobDuplexMode? duplexMode;

  ///The kind of printable content.
  ///
  ///**Supported Platforms/Implementations**:
  ///- iOS
  PrintJobOutputType? outputType;

  ///The supported resolution in DPI (dots per inch).
  ///
  ///**Supported Platforms/Implementations**:
  ///- Android native WebView
  PrintJobResolution? resolution;

  ///A Boolean value that determines whether the printing options include the number of copies.
  ///The default value is `true`.
  ///
  ///**Supported Platforms/Implementations**:
  ///- iOS
  ///- MacOS
  bool? showsNumberOfCopies;

  ///A Boolean value that determines whether the paper selection menu displays.
  ///The default value of this property is `false`.
  ///Setting the value to `true` enables a paper selection menu on printers that support different types of paper and have more than one paper type loaded.
  ///On printers where only one paper type is available, no paper selection menu is displayed, regardless of the value of this property.
  ///
  ///**Supported Platforms/Implementations**:
  ///- iOS
  bool? showsPaperSelectionForLoadedPapers;

  ///A Boolean value that determines whether the printing options include the paper orientation control when available.
  ///The default value is `true`.
  ///
  ///**NOTE for iOS**: available only on iOS 15.0+.
  ///
  ///**Supported Platforms/Implementations**:
  ///- iOS
  ///- MacOS
  bool? showsPaperOrientation;

  ///A Boolean value that determines whether the print panel includes a control for manipulating the paper size of the printer.
  ///The default value is `true`.
  ///
  ///**Supported Platforms/Implementations**:
  ///- MacOS
  bool? showsPaperSize;

  ///A Boolean value that determines whether the Print panel includes a control for scaling the printed output.
  ///The default value is `true`.
  ///
  ///**Supported Platforms/Implementations**:
  ///- MacOS
  bool? showsScaling;

  ///A Boolean value that determines whether the Print panel includes a set of fields for manipulating the range of pages being printed.
  ///The default value is `true`.
  ///
  ///**Supported Platforms/Implementations**:
  ///- MacOS
  bool? showsPageRange;

  ///A Boolean value that determines whether the Print panel includes a separate accessory view for manipulating the paper size, orientation, and scaling attributes.
  ///The default value is `true`.
  ///
  ///**Supported Platforms/Implementations**:
  ///- MacOS
  bool? showsPageSetupAccessory;

  ///A Boolean value that determines whether the Print panel displays a built-in preview of the document contents.
  ///The default value is `true`.
  ///
  ///**Supported Platforms/Implementations**:
  ///- MacOS
  bool? showsPreview;

  ///A Boolean value that determines whether the Print panel includes an additional selection option for paper range.
  ///The default value is `true`.
  ///
  ///**Supported Platforms/Implementations**:
  ///- MacOS
  bool? showsPrintSelection;

  ///A Boolean value that determines whether the print operation displays a print panel.
  ///The default value is `true`.
  ///
  ///This property does not affect the display of a progress panel;
  ///that operation is controlled by the [showsProgressPanel] property.
  ///Operations that generate EPS or PDF data do no display a progress panel, regardless of the value in the flag parameter.
  ///
  ///**Supported Platforms/Implementations**:
  ///- MacOS
  bool? showsPrintPanel;

  ///A Boolean value that determines whether the print operation displays a progress panel.
  ///The default value is `true`.
  ///
  ///This property does not affect the display of a print panel;
  ///that operation is controlled by the [showsPrintPanel] property.
  ///Operations that generate EPS or PDF data do no display a progress panel, regardless of the value in the flag parameter.
  ///
  ///**Supported Platforms/Implementations**:
  ///- MacOS
  bool? showsProgressPanel;

  ///The height of the page footer.
  ///
  ///The footer is measured in points from the bottom of [printableRect] and is below the content area.
  ///The default footer height is `0.0`.
  ///
  ///**Supported Platforms/Implementations**:
  ///- iOS
  double? footerHeight;

  ///The height of the page header.
  ///
  ///The header is measured in points from the top of [printableRect] and is above the content area.
  ///The default header height is `0.0`.
  ///
  ///**Supported Platforms/Implementations**:
  ///- iOS
  double? headerHeight;

  ///The maximum height of the content area.
  ///
  ///The Print Formatter uses this value to determine where the content rectangle begins on the first page.
  ///It compares the value of this property with the printing rectangle’s height minus the header and footer heights and
  ///the top inset value; it uses the lower of the two values.
  ///The default value of this property is the maximum float value.
  ///
  ///**Supported Platforms/Implementations**:
  ///- iOS
  double? maximumContentHeight;

  ///The maximum width of the content area.
  ///
  ///The Print Formatter uses this value to determine the maximum width of the content rectangle.
  ///It compares the value of this property with the printing rectangle’s width minus the left and right inset values and uses the lower of the two.
  ///The default value of this property is the maximum float value.
  ///
  ///**Supported Platforms/Implementations**:
  ///- iOS
  double? maximumContentWidth;

  ///The current scaling factor. From `0.0` to `1.0`.
  ///
  ///**Supported Platforms/Implementations**:
  ///- MacOS
  double? scalingFactor;

  ///The action specified for the job.
  ///
  ///**Supported Platforms/Implementations**:
  ///- MacOS
  PrintJobDisposition? jobDisposition;

  ///An URL containing the location to which the job file will be saved when the [jobDisposition] is [PrintJobDisposition.SAVE].
  ///
  ///**Supported Platforms/Implementations**:
  ///- MacOS
  WebUri? jobSavingURL;

  ///The name of the currently selected paper size.
  ///
  ///**Supported Platforms/Implementations**:
  ///- MacOS
  String? paperName;

  ///The horizontal pagination mode.
  ///
  ///**Supported Platforms/Implementations**:
  ///- MacOS
  PrintJobPaginationMode? horizontalPagination;

  ///The vertical pagination to the specified mode.
  ///
  ///**Supported Platforms/Implementations**:
  ///- MacOS
  PrintJobPaginationMode? verticalPagination;

  ///Indicates whether the image is centered horizontally.
  ///The default value is `true`.
  ///
  ///**Supported Platforms/Implementations**:
  ///- MacOS
  bool? isHorizontallyCentered;

  ///Indicates whether the image is centered vertically.
  ///The default value is `true`.
  ///
  ///**Supported Platforms/Implementations**:
  ///- MacOS
  bool? isVerticallyCentered;

  ///The print order for the pages of the operation.
  ///
  ///**Supported Platforms/Implementations**:
  ///- MacOS
  PrintJobPageOrder? pageOrder;

  ///Whether the print operation should spawn a separate thread in which to run itself.
  ///The default value is `true`.
  ///
  ///**Supported Platforms/Implementations**:
  ///- MacOS
  bool? canSpawnSeparateThread;

  ///How many copies to print.
  ///The default value is `1`.
  ///
  ///**Supported Platforms/Implementations**:
  ///- MacOS
  int? copies;

  ///An integer value that specifies the first page in the print job.
  ///
  ///**Supported Platforms/Implementations**:
  ///- MacOS
  int? firstPage;

  ///An integer value that specifies the last page in the print job.
  ///
  ///**Supported Platforms/Implementations**:
  ///- MacOS
  int? lastPage;

  ///If `true`, produce detailed reports when an error occurs.
  ///The default value is `false`.
  ///
  ///**Supported Platforms/Implementations**:
  ///- MacOS
  bool? detailedErrorReporting;

  ///A fax number.
  ///
  ///**Supported Platforms/Implementations**:
  ///- MacOS
  String? faxNumber;

  ///If `true`, a standard header and footer are added outside the margins of each page.
  ///The default value is `true`.
  ///
  ///**Supported Platforms/Implementations**:
  ///- MacOS
  bool? headerAndFooter;

  ///If `true`, collates output.
  ///
  ///**Supported Platforms/Implementations**:
  ///- MacOS
  bool? mustCollate;

  ///The number of logical pages to be tiled horizontally on a physical sheet of paper.
  ///
  ///**Supported Platforms/Implementations**:
  ///- MacOS
  int? pagesAcross;

  ///The number of logical pages to be tiled vertically on a physical sheet of paper.
  ///
  ///**Supported Platforms/Implementations**:
  ///- MacOS
  int? pagesDown;

  ///A timestamp that specifies the time at which printing should begin.
  ///
  ///**Supported Platforms/Implementations**:
  ///- MacOS
  int? time;
  PrintJobSettings(
      {this.handledByClient = false,
      this.jobName,
      this.animated = true,
      this.orientation,
      this.numberOfPages,
      this.forceRenderingQuality,
      this.margins,
      this.mediaSize,
      this.colorMode,
      this.duplexMode,
      this.outputType,
      this.resolution,
      this.showsNumberOfCopies = true,
      this.showsPaperSelectionForLoadedPapers = false,
      this.showsPaperOrientation = true,
      this.showsPaperSize = true,
      this.showsScaling = true,
      this.showsPageRange = true,
      this.showsPageSetupAccessory = true,
      this.showsPreview = true,
      this.showsPrintSelection = true,
      this.showsPrintPanel = true,
      this.showsProgressPanel = true,
      this.footerHeight,
      this.headerHeight,
      this.maximumContentHeight,
      this.maximumContentWidth,
      this.scalingFactor,
      this.jobDisposition,
      this.jobSavingURL,
      this.paperName,
      this.horizontalPagination,
      this.verticalPagination,
      this.isHorizontallyCentered = true,
      this.isVerticallyCentered = true,
      this.pageOrder,
      this.canSpawnSeparateThread = true,
      this.copies = 1,
      this.firstPage,
      this.lastPage,
      this.detailedErrorReporting = false,
      this.faxNumber,
      this.headerAndFooter = true,
      this.mustCollate,
      this.pagesAcross,
      this.pagesDown,
      this.time});

  ///Gets a possible [PrintJobSettings] instance from a [Map] value.
  static PrintJobSettings? fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      return null;
    }
    final instance = PrintJobSettings(
      jobName: map['jobName'],
      orientation: PrintJobOrientation.fromNativeValue(map['orientation']),
      numberOfPages: map['numberOfPages'],
      forceRenderingQuality: PrintJobRenderingQuality.fromNativeValue(
          map['forceRenderingQuality']),
      margins: MapEdgeInsets.fromMap(map['margins']?.cast<String, dynamic>()),
      mediaSize:
          PrintJobMediaSize.fromMap(map['mediaSize']?.cast<String, dynamic>()),
      colorMode: PrintJobColorMode.fromNativeValue(map['colorMode']),
      duplexMode: PrintJobDuplexMode.fromNativeValue(map['duplexMode']),
      outputType: PrintJobOutputType.fromNativeValue(map['outputType']),
      resolution: PrintJobResolution.fromMap(
          map['resolution']?.cast<String, dynamic>()),
      footerHeight: map['footerHeight'],
      headerHeight: map['headerHeight'],
      maximumContentHeight: map['maximumContentHeight'],
      maximumContentWidth: map['maximumContentWidth'],
      scalingFactor: map['scalingFactor'],
      jobDisposition:
          PrintJobDisposition.fromNativeValue(map['jobDisposition']),
      jobSavingURL:
          map['jobSavingURL'] != null ? WebUri(map['jobSavingURL']) : null,
      paperName: map['paperName'],
      horizontalPagination:
          PrintJobPaginationMode.fromNativeValue(map['horizontalPagination']),
      verticalPagination:
          PrintJobPaginationMode.fromNativeValue(map['verticalPagination']),
      pageOrder: PrintJobPageOrder.fromNativeValue(map['pageOrder']),
      firstPage: map['firstPage'],
      lastPage: map['lastPage'],
      faxNumber: map['faxNumber'],
      mustCollate: map['mustCollate'],
      pagesAcross: map['pagesAcross'],
      pagesDown: map['pagesDown'],
      time: map['time'],
    );
    instance.handledByClient = map['handledByClient'];
    instance.animated = map['animated'];
    instance.showsNumberOfCopies = map['showsNumberOfCopies'];
    instance.showsPaperSelectionForLoadedPapers =
        map['showsPaperSelectionForLoadedPapers'];
    instance.showsPaperOrientation = map['showsPaperOrientation'];
    instance.showsPaperSize = map['showsPaperSize'];
    instance.showsScaling = map['showsScaling'];
    instance.showsPageRange = map['showsPageRange'];
    instance.showsPageSetupAccessory = map['showsPageSetupAccessory'];
    instance.showsPreview = map['showsPreview'];
    instance.showsPrintSelection = map['showsPrintSelection'];
    instance.showsPrintPanel = map['showsPrintPanel'];
    instance.showsProgressPanel = map['showsProgressPanel'];
    instance.isHorizontallyCentered = map['isHorizontallyCentered'];
    instance.isVerticallyCentered = map['isVerticallyCentered'];
    instance.canSpawnSeparateThread = map['canSpawnSeparateThread'];
    instance.copies = map['copies'];
    instance.detailedErrorReporting = map['detailedErrorReporting'];
    instance.headerAndFooter = map['headerAndFooter'];
    return instance;
  }

  ///Converts instance to a map.
  Map<String, dynamic> toMap() {
    return {
      "handledByClient": handledByClient,
      "jobName": jobName,
      "animated": animated,
      "orientation": orientation?.toNativeValue(),
      "numberOfPages": numberOfPages,
      "forceRenderingQuality": forceRenderingQuality?.toNativeValue(),
      "margins": margins?.toMap(),
      "mediaSize": mediaSize?.toMap(),
      "colorMode": colorMode?.toNativeValue(),
      "duplexMode": duplexMode?.toNativeValue(),
      "outputType": outputType?.toNativeValue(),
      "resolution": resolution?.toMap(),
      "showsNumberOfCopies": showsNumberOfCopies,
      "showsPaperSelectionForLoadedPapers": showsPaperSelectionForLoadedPapers,
      "showsPaperOrientation": showsPaperOrientation,
      "showsPaperSize": showsPaperSize,
      "showsScaling": showsScaling,
      "showsPageRange": showsPageRange,
      "showsPageSetupAccessory": showsPageSetupAccessory,
      "showsPreview": showsPreview,
      "showsPrintSelection": showsPrintSelection,
      "showsPrintPanel": showsPrintPanel,
      "showsProgressPanel": showsProgressPanel,
      "footerHeight": footerHeight,
      "headerHeight": headerHeight,
      "maximumContentHeight": maximumContentHeight,
      "maximumContentWidth": maximumContentWidth,
      "scalingFactor": scalingFactor,
      "jobDisposition": jobDisposition?.toNativeValue(),
      "jobSavingURL": jobSavingURL?.toString(),
      "paperName": paperName,
      "horizontalPagination": horizontalPagination?.toNativeValue(),
      "verticalPagination": verticalPagination?.toNativeValue(),
      "isHorizontallyCentered": isHorizontallyCentered,
      "isVerticallyCentered": isVerticallyCentered,
      "pageOrder": pageOrder?.toNativeValue(),
      "canSpawnSeparateThread": canSpawnSeparateThread,
      "copies": copies,
      "firstPage": firstPage,
      "lastPage": lastPage,
      "detailedErrorReporting": detailedErrorReporting,
      "faxNumber": faxNumber,
      "headerAndFooter": headerAndFooter,
      "mustCollate": mustCollate,
      "pagesAcross": pagesAcross,
      "pagesDown": pagesDown,
      "time": time,
    };
  }

  ///Converts instance to a map.
  Map<String, dynamic> toJson() {
    return toMap();
  }

  ///Returns a copy of PrintJobSettings.
  PrintJobSettings copy() {
    return PrintJobSettings.fromMap(toMap()) ?? PrintJobSettings();
  }

  @override
  String toString() {
    return 'PrintJobSettings{handledByClient: $handledByClient, jobName: $jobName, animated: $animated, orientation: $orientation, numberOfPages: $numberOfPages, forceRenderingQuality: $forceRenderingQuality, margins: $margins, mediaSize: $mediaSize, colorMode: $colorMode, duplexMode: $duplexMode, outputType: $outputType, resolution: $resolution, showsNumberOfCopies: $showsNumberOfCopies, showsPaperSelectionForLoadedPapers: $showsPaperSelectionForLoadedPapers, showsPaperOrientation: $showsPaperOrientation, showsPaperSize: $showsPaperSize, showsScaling: $showsScaling, showsPageRange: $showsPageRange, showsPageSetupAccessory: $showsPageSetupAccessory, showsPreview: $showsPreview, showsPrintSelection: $showsPrintSelection, showsPrintPanel: $showsPrintPanel, showsProgressPanel: $showsProgressPanel, footerHeight: $footerHeight, headerHeight: $headerHeight, maximumContentHeight: $maximumContentHeight, maximumContentWidth: $maximumContentWidth, scalingFactor: $scalingFactor, jobDisposition: $jobDisposition, jobSavingURL: $jobSavingURL, paperName: $paperName, horizontalPagination: $horizontalPagination, verticalPagination: $verticalPagination, isHorizontallyCentered: $isHorizontallyCentered, isVerticallyCentered: $isVerticallyCentered, pageOrder: $pageOrder, canSpawnSeparateThread: $canSpawnSeparateThread, copies: $copies, firstPage: $firstPage, lastPage: $lastPage, detailedErrorReporting: $detailedErrorReporting, faxNumber: $faxNumber, headerAndFooter: $headerAndFooter, mustCollate: $mustCollate, pagesAcross: $pagesAcross, pagesDown: $pagesDown, time: $time}';
  }
}
