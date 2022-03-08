-- UIViewContentMode
UIViewContentModeScaleToFill = 0
UIViewContentModeScaleAspectFit = 1
UIViewContentModeScaleAspectFill = 2
UIViewContentModeRedraw = 3
UIViewContentModeCenter = 4
UIViewContentModeTop = 5
UIViewContentModeBottom = 6
UIViewContentModeLeft = 7
UIViewContentModeRight = 8
UIViewContentModeTopLeft = 9
UIViewContentModeTopRight = 10
UIViewContentModeBottomLeft = 11
UIViewContentModeBottomRight = 12

-- UIBarButtonItemStyle
UIBarButtonItemStylePlain = 0
UIBarButtonItemStyleBordered = 1
UIBarButtonItemStyleDone = 2

-- UIButtonType
UIButtonTypeCustom = 0
UIButtonTypeRoundedRect = 1
UIButtonTypeDetailDisclosure = 2
UIButtonTypeInfoLight = 3
UIButtonTypeInfoDark = 4
UIButtonTypeContactAdd = 5

UILineBreakModeWordWrap = 0
UILineBreakModeCharacterWrap = 1
UILineBreakModeClip = 2
UILineBreakModeHeadTruncation = 3
UILineBreakModeTailTruncation = 4
UILineBreakModeMiddleTruncation = 5

-- UITableViewCellSelectionStyle
UITableViewCellSelectionStyleNone = 0
UITableViewCellSelectionStyleBlue = 1
UITableViewCellSelectionStyleGray = 2
UITableViewCellSelectionStyleDefault = 3

-- UITableViewCellFocusStyle
UITableViewCellFocusStyleDefault = 0
UITableViewCellFocusStyleCustom = 1

-- UITableViewCellStyle
UITableViewCellStyleDefault = 0
UITableViewCellStyleValue1 = 1
UITableViewCellStyleValue2 = 2
UITableViewCellStyleSubtitle = 3

-- UITableViewCellAccessoryType
UITableViewCellAccessoryNone = 0
UITableViewCellAccessoryDisclosureIndicator = 1
UITableViewCellAccessoryDetailDisclosureButton = 2
UITableViewCellAccessoryCheckmark = 3
UITableViewCellAccessoryDetailButton = 3

-- UIActivityIndicatorViewStyle
UIActivityIndicatorViewStyleWhiteLarge = 0
UIActivityIndicatorViewStyleWhite = 1
UIActivityIndicatorViewStyleGray = 2
UIActivityIndicatorViewStyleMedium = 100 -- API_AVAILABLE(ios(13.0))
UIActivityIndicatorViewStyleLarge = 101 -- API_AVAILABLE(ios(13.0))

-- UITableViewStyle
UITableViewStylePlain = 0
UITableViewStyleGrouped = 1
UITableViewStyleInsetGrouped = 2 -- API_AVAILABLE(ios(13.0))

-- UIControlStateNormal
UIControlStateNormal = 0
UIControlStateHighlighted = 1
UIControlStateDisabled = 2
UIControlStateSelected = 4
UIControlStateApplication = 0x00FF0000
UIControlStateReserved = 0xFF000000

-- String Encoding
NSASCIIStringEncoding = 1
NSNEXTSTEPStringEncoding = 2
NSJapaneseEUCStringEncoding = 3
NSUTF8StringEncoding = 4
NSISOLatin1StringEncoding = 5
NSSymbolStringEncoding = 6
NSNonLossyASCIIStringEncoding = 7
NSShiftJISStringEncoding = 8
NSISOLatin2StringEncoding = 9
NSUnicodeStringEncoding = 10
NSWindowsCP1251StringEncoding = 11
NSWindowsCP1252StringEncoding = 12
NSWindowsCP1253StringEncoding = 13
NSWindowsCP1254StringEncoding = 14
NSWindowsCP1250StringEncoding = 15
NSISO2022JPStringEncoding = 21
NSMacOSRomanStringEncoding = 30
NSUTF16BigEndianStringEncoding = 0x90000100
NSUTF16LittleEndianStringEncoding = 0x94000100
NSUTF32StringEncoding = 0x8c000100
NSUTF32BigEndianStringEncoding = 0x98000100
NSUTF32LittleEndianStringEncoding = 0x9c000100
NSProprietaryStringEncoding = 65536

-- UITextAlignment
UITextAlignmentLeft = 0
UITextAlignmentCenter = 1
UITextAlignmentRight = 2

-- UILineBreakMode
UILineBreakModeWordWrap = 0
UILineBreakModeCharacterWrap = 1
UILineBreakModeClip = 2
UILineBreakModeHeadTruncation = 3
UILineBreakModeTailTruncation = 4
UILineBreakModeMiddleTruncation = 5

-- UIModalTransitionStyle
UIModalTransitionStyleCoverVertical = 0
UIModalTransitionStyleFlipHorizontal = 1
UIModalTransitionStyleCrossDissolve = 2
UIModalTransitionStylePartialCurl = 3

-- UIKeyboardType
UIKeyboardTypeDefault = 0
UIKeyboardTypeASCIICapable = 1
UIKeyboardTypeNumbersAndPunctuation = 2
UIKeyboardTypeURL = 3
UIKeyboardTypeNumberPad = 4
UIKeyboardTypePhonePad = 5
UIKeyboardTypeNamePhonePad = 6
UIKeyboardTypeEmailAddress = 7
UIKeyboardTypeDecimalPad = 8
UIKeyboardTypeTwitter = 9
UIKeyboardTypeWebSearch = 10
UIKeyboardTypeASCIICapableNumberPad = 11 -- API_AVAILABLE(ios(10.0))
UIKeyboardTypeAlphabet = UIKeyboardTypeASCIICapable

-- UIReturnKeyType
UIReturnKeyDefault = 0
UIReturnKeyGo = 1
UIReturnKeyGoogle = 2
UIReturnKeyJoin = 3
UIReturnKeyNext = 4
UIReturnKeyRoute = 5
UIReturnKeySearch = 6
UIReturnKeySend = 7
UIReturnKeyYahoo = 8
UIReturnKeyDone = 9
UIReturnKeyEmergencyCall = 10
UIReturnKeyContinue = 11

-- UIControlEvents
UIControlEventTouchDown           = 2^0
UIControlEventTouchDownRepeat     = 2^1
UIControlEventTouchDragInside     = 2^2
UIControlEventTouchDragOutside    = 2^3
UIControlEventTouchDragEnter      = 2^4
UIControlEventTouchDragExit       = 2^5
UIControlEventTouchUpInside       = 2^6
UIControlEventTouchUpOutside      = 2^7
UIControlEventTouchCancel         = 2^8
UIControlEventValueChanged        = 2^12
UIControlEventPrimaryActionTriggered = 2^13
UIControlEventMenuActionTriggered = 2^14 -- API_AVAILABLE(ios(14.0))
UIControlEventEditingDidBegin     = 2^16
UIControlEventEditingChanged      = 2^17
UIControlEventEditingDidEnd       = 2^18
UIControlEventEditingDidEndOnExit = 2^19
UIControlEventAllTouchEvents      = 0x00000FFF
UIControlEventAllEditingEvents    = 0x000F0000
UIControlEventApplicationReserved = 0x0F000000
UIControlEventSystemReserved      = 0xF0000000
UIControlEventAllEvents           = 0xFFFFFFFF

-- UITableViewCellEditingStyle;
UITableViewCellEditingStyleNone = 0
UITableViewCellEditingStyleDelete = 1
UITableViewCellEditingStyleInsert = 2

-- UIBarButtonSystemItem
UIBarButtonSystemItemDone = 0
UIBarButtonSystemItemCancel = 1
UIBarButtonSystemItemEdit = 2
UIBarButtonSystemItemSave = 3
UIBarButtonSystemItemAdd = 4
UIBarButtonSystemItemFlexibleSpace = 5
UIBarButtonSystemItemFixedSpace = 6
UIBarButtonSystemItemCompose = 7
UIBarButtonSystemItemReply = 8
UIBarButtonSystemItemAction = 9
UIBarButtonSystemItemOrganize = 10
UIBarButtonSystemItemBookmarks = 11
UIBarButtonSystemItemSearch = 12
UIBarButtonSystemItemRefresh = 13
UIBarButtonSystemItemStop = 14
UIBarButtonSystemItemCamera = 15
UIBarButtonSystemItemTrash = 16
UIBarButtonSystemItemPlay = 17
UIBarButtonSystemItemPause = 18
UIBarButtonSystemItemRewind = 19
UIBarButtonSystemItemFastForward = 20
UIBarButtonSystemItemUndo = 21
UIBarButtonSystemItemRedo = 22
UIBarButtonSystemItemPageCurl = 23 -- API_DEPRECATED
UIBarButtonSystemItemClose = 24 -- API_AVAILABLE(ios(13.0))

-- UITextBorderStyle
UITextBorderStyleNone = 0
UITextBorderStyleLine = 1
UITextBorderStyleBezel = 2
UITextBorderStyleRoundedRect = 3

-- UITableViewScrollPosition
UITableViewScrollPositionNone = 0
UITableViewScrollPositionTop = 1
UITableViewScrollPositionMiddle = 2
UITableViewScrollPositionBottom = 3

-- UIKeyboardAppearance
UIKeyboardAppearanceDefault = 0
UIKeyboardAppearanceDark = 1
UIKeyboardAppearanceLight = 2
UIKeyboardAppearanceAlert = UIKeyboardAppearanceDark

-- UITextFieldViewMode
UITextFieldViewModeNever = 0
UITextFieldViewModeWhileEditing = 1
UITextFieldViewModeUnlessEditing = 2
UITextFieldViewModeAlways = 3

-- UITextAutocorrectionType
UITextAutocorrectionTypeDefault = 0
UITextAutocorrectionTypeNo = 1
UITextAutocorrectionTypeYes = 2

-- UIBarStyle
UIBarStyleDefault          = 0
UIBarStyleBlack            = 1
UIBarStyleBlackOpaque      = 1 -- API_DEPRECATED. Use UIBarStyleBlack
UIBarStyleBlackTranslucent = 2 -- API_DEPRECATED. Use UIBarStyleBlack and set the translucent property to YES


-- NSURLRequestCachePolicy
NSURLRequestUseProtocolCachePolicy = 0
NSURLRequestReloadIgnoringLocalCacheData = 1
NSURLRequestReloadIgnoringLocalAndRemoteCacheData = 4 -- Unimplemented
NSURLRequestReloadIgnoringCacheData = NSURLRequestReloadIgnoringLocalCacheData
NSURLRequestReturnCacheDataElseLoad = 2
NSURLRequestReturnCacheDataDontLoad = 3
NSURLRequestReloadRevalidatingCacheData = 5 -- Unimplemented

-- UISegmentedControlSegment
UISegmentedControlSegmentAny = 0
UISegmentedControlSegmentLeft = 1
UISegmentedControlSegmentCenter = 2
UISegmentedControlSegmentRight = 3
UISegmentedControlSegmentAlone = 4

-- UIRemoteNotificationType
UIRemoteNotificationTypeNone = 0
UIRemoteNotificationTypeBadge = 2^0
UIRemoteNotificationTypeSound = 2^1
UIRemoteNotificationTypeAlert = 2^1
UIRemoteNotificationTypeNewsstandContentAvailability = 2^3

-- NSURLCredentialPersistence;
NSURLCredentialPersistenceNone = 0
NSURLCredentialPersistenceForSession = 1
NSURLCredentialPersistencePermanent = 2
NSURLCredentialPersistenceSynchronizable = 3

-- UIDeviceOrientation
UIDeviceOrientationUnknown = 0
UIDeviceOrientationPortrait = 1
UIDeviceOrientationPortraitUpsideDown = 2
UIDeviceOrientationLandscapeLeft = 3
UIDeviceOrientationLandscapeRight = 4
UIDeviceOrientationFaceUp = 5
UIDeviceOrientationFaceDown = 6

-- UIInterfaceOrientation
UIInterfaceOrientationUnknown = UIDeviceOrientationUnknown
UIInterfaceOrientationPortrait = UIDeviceOrientationPortrait
UIInterfaceOrientationPortraitUpsideDown = UIDeviceOrientationPortraitUpsideDown
UIInterfaceOrientationLandscapeLeft = UIDeviceOrientationLandscapeRight
UIInterfaceOrientationLandscapeRight = UIDeviceOrientationLandscapeLeft

-- UIViewAnimationCurve
UIViewAnimationCurveEaseInOut = 0
UIViewAnimationCurveEaseIn = 1
UIViewAnimationCurveEaseOut = 2
UIViewAnimationCurveLinear = 3

-- UITableViewRowAnimation
UITableViewRowAnimationFade = 0
UITableViewRowAnimationRight = 1 -- slide in from right (or out to right)
UITableViewRowAnimationLeft = 2
UITableViewRowAnimationTop = 3
UITableViewRowAnimationBottom = 4
UITableViewRowAnimationNone = 5
UITableViewRowAnimationMiddle = 6
UITableViewRowAnimationAutomatic = 100

-- UIViewAnimationTransition
UIViewAnimationTransitionNone = 0
UIViewAnimationTransitionFlipFromLeft = 1
UIViewAnimationTransitionFlipFromRight = 2
UIViewAnimationTransitionCurlUp = 3
UIViewAnimationTransitionCurlDown = 4

-- UIViewAutoresizing
UIViewAutoresizingNone                 = 0
UIViewAutoresizingFlexibleLeftMargin   = 2^0
UIViewAutoresizingFlexibleWidth        = 2^1
UIViewAutoresizingFlexibleRightMargin  = 2^2
UIViewAutoresizingFlexibleTopMargin    = 2^3
UIViewAutoresizingFlexibleHeight       = 2^4
UIViewAutoresizingFlexibleBottomMargin = 2^5

-- UIWebViewNavigationType
UIWebViewNavigationTypeLinkClicked = 0
UIWebViewNavigationTypeFormSubmitted = 1
UIWebViewNavigationTypeBackForward = 2
UIWebViewNavigationTypeReload = 3
UIWebViewNavigationTypeFormResubmitted = 4
UIWebViewNavigationTypeOther = 5

-- NSHTTPCookieAcceptPolicy
NSHTTPCookieAcceptPolicyAlways = 0
NSHTTPCookieAcceptPolicyNever = 1
NSHTTPCookieAcceptPolicyOnlyFromMainDocumentDomain = 2

-- MFMailComposeResult
MFMailComposeResultCancelled = 0
MFMailComposeResultSaved = 1
MFMailComposeResultSent = 2
MFMailComposeResultFailed = 3

-- SKPaymentTransactionState
SKPaymentTransactionStatePurchasing = 0
SKPaymentTransactionStatePurchased = 1
SKPaymentTransactionStateFailed = 2
SKPaymentTransactionStateRestored = 3
SKPaymentTransactionStateDeferred = 4

-- SKError
SKErrorUnknown = 0
SKErrorClientInvalid = 1
SKErrorPaymentCancelled = 2
SKErrorPaymentInvalid = 3
SKErrorPaymentNotAllowed = 4
SKErrorStoreProductNotAvailable = 5 -- API_AVAILABLE(ios(3.0), macos(10.15), watchos(6.2))
SKErrorCloudServicePermissionDenied = 6 -- API_AVAILABLE(ios(9.3), tvos(9.3), watchos(6.2), macos(11.0))
SKErrorCloudServiceNetworkConnectionFailed = 7 -- API_AVAILABLE(ios(9.3), tvos(9.3), watchos(6.2), macos(11.0))
SKErrorCloudServiceRevoked = 8 -- API_AVAILABLE(ios(10.3), tvos(10.3), watchos(6.2), macos(11.0))
SKErrorPrivacyAcknowledgementRequired = 9 -- API_AVAILABLE(ios(12.2), tvos(12.2), macos(10.14.4), watchos(6.2))
SKErrorUnauthorizedRequestData = 10 -- API_AVAILABLE(ios(12.2), macos(10.14.4), watchos(6.2))
SKErrorInvalidOfferIdentifier = 11 -- API_AVAILABLE(ios(12.2), macos(10.14.4), watchos(6.2))
SKErrorInvalidSignature = 12 -- API_AVAILABLE(ios(12.2), macos(10.14.4), watchos(6.2))
SKErrorMissingOfferParams = 13 -- API_AVAILABLE(ios(12.2), macos(10.14.4), watchos(6.2))
SKErrorInvalidOfferPrice = 14 -- API_AVAILABLE(ios(12.2), macos(10.14.4), watchos(6.2))
SKErrorOverlayCancelled = 15 -- API_AVAILABLE(ios(12.2), macos(10.14.4), watchos(6.2))
SKErrorOverlayInvalidConfiguration = 16 -- API_AVAILABLE(ios(14.0)) API_UNAVAILABLE(macos, watchos)
SKErrorOverlayTimeout = 17 -- API_AVAILABLE(ios(14.0)) API_UNAVAILABLE(macos, watchos)
SKErrorIneligibleForOffer = 18 -- API_AVAILABLE(ios(14.0), macos(11.0), watchos(7.0))
SKErrorUnsupportedPlatform = 19 -- API_AVAILABLE(ios(14.0), macos(11.0), watchos(7.0))
SKErrorOverlayPresentedInBackgroundScene = 20 -- API_AVAILABLE(ios(14.5)) API_UNAVAILABLE(macos, watchos)

-- UIStatusBarStyle
UIStatusBarStyleDefault = 0
UIStatusBarStyleLightContent = 1
UIStatusBarStyleDarkContent = 3 -- API_AVAILABLE(ios(13.0))
UIStatusBarStyleBlackTranslucent = 1 -- API_DEPRECATED_WITH_REPLACEMENT("UIStatusBarStyleLightContent", ios(2.0, 7.0))
UIStatusBarStyleBlackOpaque = 2 -- API_DEPRECATED_WITH_REPLACEMENT("UIStatusBarStyleLightContent", ios(2.0, 7.0))

-- UIControlContentHorizontalAlignment
UIControlContentHorizontalAlignmentCenter = 0
UIControlContentHorizontalAlignmentLeft = 1
UIControlContentHorizontalAlignmentRight = 2
UIControlContentHorizontalAlignmentFill = 3
UIControlContentHorizontalAlignmentLeading = 4 -- API_AVAILABLE(ios(11.0), tvos(11.0))
UIControlContentHorizontalAlignmentTrailing = 5 -- API_AVAILABLE(ios(11.0), tvos(11.0))

-- UIImagePickerControllerSourceType
UIImagePickerControllerSourceTypePhotoLibrary = 0
UIImagePickerControllerSourceTypeCamera = 1
UIImagePickerControllerSourceTypeSavedPhotosAlbum = 2

-- UIImagePickerControllerQualityType
UIImagePickerControllerQualityTypeHigh = 0
UIImagePickerControllerQualityTypeMedium = 1
UIImagePickerControllerQualityTypeLow = 2
UIImagePickerControllerQualityType640x480 = 3
UIImagePickerControllerQualityTypeIFrame1280x720 = 4
UIImagePickerControllerQualityTypeIFrame960x540 = 5

-- UIImagePickerControllerCameraCaptureMode
UIImagePickerControllerCameraCaptureModePhoto = 0
UIImagePickerControllerCameraCaptureModeVideo = 1

-- UIImagePickerControllerCameraDevice
UIImagePickerControllerCameraDeviceRear = 0
UIImagePickerControllerCameraDeviceFront = 1

-- UIImagePickerControllerCameraFlashMode
UIImagePickerControllerCameraFlashModeOff  = -1
UIImagePickerControllerCameraFlashModeAuto = 0
UIImagePickerControllerCameraFlashModeOn   = 1

-- PHPickerConfigurationAssetRepresentationMode API_AVAILABLE(ios(14))
PHPickerConfigurationAssetRepresentationModeAutomatic = 0
PHPickerConfigurationAssetRepresentationModeCurrent = 1
PHPickerConfigurationAssetRepresentationModeCompatible = 2

-- PHPickerConfigurationSelection API_AVAILABLE(ios(15))
PHPickerConfigurationSelectionDefault = 0
PHPickerConfigurationSelectionOrdered = 1

-- NSComparisonResult
NSOrderedAscending = -1
NSOrderedSame = 0
NSOrderedDescending = 1

-- UITableViewCellSeparatorStyle
UITableViewCellSeparatorStyleNone = 0
UITableViewCellSeparatorStyleSingleLine = 1
UITableViewCellSeparatorStyleSingleLineEtched = 2

-- CLAuthorizationStatus
kCLAuthorizationStatusNotDetermined = 0
kCLAuthorizationStatusRestricted = 1
kCLAuthorizationStatusDenied = 2
kCLAuthorizationStatusAuthorized = 3
kCLAuthorizationStatusAuthorizedAlways = 4
kCLAuthorizationStatusAuthorizedWhenInUse = 5

-- UISwipeGestureRecognizerDirection;
UISwipeGestureRecognizerDirectionRight = 2^0
UISwipeGestureRecognizerDirectionLeft = 2^1
UISwipeGestureRecognizerDirectionUp = 2^2
UISwipeGestureRecognizerDirectionDown = 2^3

-- UIControlContentHorizontalAlignment
UIControlContentHorizontalAlignmentCenter = 0
UIControlContentHorizontalAlignmentLeft = 1
UIControlContentHorizontalAlignmentRight = 2
UIControlContentHorizontalAlignmentFill = 3
UIControlContentHorizontalAlignmentLeading = 4 -- API_AVAILABLE(ios(11.0), tvos(11.0))
UIControlContentHorizontalAlignmentTrailing = 5 -- API_AVAILABLE(ios(11.0), tvos(11.0))

-- UIControlContentVerticalAlignment
UIControlContentVerticalAlignmentCenter = 0
UIControlContentVerticalAlignmentTop = 1
UIControlContentVerticalAlignmentBottom = 2
UIControlContentVerticalAlignmentFill = 3

-- UIEventType
UIEventTypeTouches = 0
UIEventTypeMotion = 1
UIEventTypeRemoteControl = 2
UIEventTypePresses = 3
UIEventTypeScroll = 10 -- API_AVAILABLE(ios(13.4), tvos(13.4))
UIEventTypeHover = 11 -- API_AVAILABLE(ios(13.4), tvos(13.4))
UIEventTypeTransform = 12 -- API_AVAILABLE(ios(13.4), tvos(13.4))
