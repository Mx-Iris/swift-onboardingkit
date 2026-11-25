//
//  OnBoardingKitPrivateAPI.h
//
//  Objective-C declarations for the classes and constants that the private macOS framework OnBoardingKit
//  (/System/Library/PrivateFrameworks/OnBoardingKit.framework) exports. Apple's AppKit apps build their welcome,
//  "What's New" and privacy pages with it: App Store, Freeform and Shortcuts use the template view, its bullet list and
//  the container view controller; Mail, Music, TV, Photos and Books show privacy pages through OBPrivacyPresenter.
//
//  What is declared:
//  - Every class in the SDK's text stub (OnBoardingKit.tbd, macOS 27.2 SDK: 29 classes) and the 72 privacy identifier
//    constants it exports.
//  - Members that exist on macOS 27.2. Instance variables, underscore-prefixed methods, overrides of AppKit methods
//    and the properties and methods that only serve the framework's own layout and caching are left out.
//    Documentations/Internal/DeclarationSources.md lists the rules and where every type comes from.
//  - Members are read from the framework's runtime metadata for every macOS release from 11.0 to 27.2. A member with
//    no API_AVAILABLE exists on macOS 14.0, the package's deployment target; API_AVAILABLE names the first release
//    that has it. Members a release removed are not declared, including the three macOS 27.2 removed:
//    -[OBBundleManager orderedPrivacyBundlesWithPrivacyPaneBundle:] and OBTemplatePartBulletListItem's
//    -initWithTitle:description:image:imageTintColor: and -initWithTitle:description:symbol:symbolTintColor:.
//  - Tests/COnBoardingKitTests reads this header and checks every class, method and property accessor against the
//    running system, so a member a later release removes fails a test instead of an unrecognized-selector crash.
//
//  Types: the runtime metadata types every object parameter as `id` and every block as an untyped block. The types
//  here come from the matching properties and instance variables and from the framework's code (macOS 27.2,
//  arm64e). Entries tagged [unverified] follow the selector's wording and were not checked in the binary.
//
//  Enumerations: the framework passes plain integers. The binary carries no names for their values, so the enums
//  below are this package's, each value named and documented for what macOS 27.2 does with it.
//
//  Linking: OnBoardingKit.framework has no headers in the SDK, only the text stub, under
//  $(SDKROOT)/System/Library/PrivateFrameworks. Link with -F/System/Library/PrivateFrameworks -framework OnBoardingKit.
//  The stub has no allowable-clients list, so any binary may link it.
//
//  All of this is SPI: no ABI promise, and any of it can change in an OS update.
//

#ifndef ONBOARDINGKIT_PRIVATE_API_H
#define ONBOARDINGKIT_PRIVATE_API_H

#import <AppKit/AppKit.h>
#import <QuartzCore/QuartzCore.h>

NS_HEADER_AUDIT_BEGIN(nullability, sendability)

@class OBAnimationController;
@class OBAnimationState;
@class OBAnimationView;
@class OBBundle;
@class OBPrivacyCombinedController;
@class OBPrivacyCombinedFooterComponents;
@class OBPrivacyFlow;
@class OBPrivacyFlowGroup;
@class OBPrivacyLinkController;
@class OBPrivacySplashController;
@class OBSplashBullet;
@class OBSplashContent;
@class OBTemplatePartBulletList;
@class OBTemplatePartBulletListItem;
@class OBTemplatePartLinkButton;
@class OBTemplateView;

#pragma mark - QuartzCore classes the animation classes use

/// A Core Animation package (`.caar`) loaded from disk. Private QuartzCore class, exported by QuartzCore.tbd.
@interface CAPackage : NSObject
@end

/// Drives a layer tree between the states a `CAPackage` defines. Private QuartzCore class, exported by QuartzCore.tbd.
@interface CAStateController : NSObject
@end

#pragma mark - Privacy identifiers

/// Names one of the privacy pages ("Data & Privacy" splashes) the system ships under
/// /System/Library/OnBoardingBundles. Pass it to `OBPrivacyPresenter` or `OBPrivacyLinkController`.
typedef NSString *OBPrivacyIdentifier NS_TYPED_EXTENSIBLE_ENUM;

extern OBPrivacyIdentifier const OBPrivacyActivationIdentifier NS_SWIFT_NAME(activation);
extern OBPrivacyIdentifier const OBPrivacyActivityIdentifier NS_SWIFT_NAME(activity);
extern OBPrivacyIdentifier const OBPrivacyAdvertisingIdentifier NS_SWIFT_NAME(advertising);
extern OBPrivacyIdentifier const OBPrivacyAnalyticsAppIdentifier NS_SWIFT_NAME(analyticsApp);
extern OBPrivacyIdentifier const OBPrivacyAnalyticsDeviceIdentifier NS_SWIFT_NAME(analyticsDevice);
extern OBPrivacyIdentifier const OBPrivacyAnalyticsiCloudIdentifier NS_SWIFT_NAME(analyticsICloud);
extern OBPrivacyIdentifier const OBPrivacyAppStoreIdentifier NS_SWIFT_NAME(appStore);
extern OBPrivacyIdentifier const OBPrivacyAppleArcadeIdentifier NS_SWIFT_NAME(appleArcade);
extern OBPrivacyIdentifier const OBPrivacyAppleCardIdentifier NS_SWIFT_NAME(appleCard);
extern OBPrivacyIdentifier const OBPrivacyAppleIDIdentifier NS_SWIFT_NAME(appleID);
extern OBPrivacyIdentifier const OBPrivacyAppleMusicFriendsIdentifier NS_SWIFT_NAME(appleMusicFriends);
extern OBPrivacyIdentifier const OBPrivacyAppleMusicIdentifier NS_SWIFT_NAME(appleMusic);
extern OBPrivacyIdentifier const OBPrivacyApplePayCashFamilyIdentifier NS_SWIFT_NAME(applePayCashFamily);
extern OBPrivacyIdentifier const OBPrivacyApplePayCashIdentifier NS_SWIFT_NAME(applePayCash);
extern OBPrivacyIdentifier const OBPrivacyApplePayIdentifier NS_SWIFT_NAME(applePay);
extern OBPrivacyIdentifier const OBPrivacyAskSiriIdentifier NS_SWIFT_NAME(askSiri);
extern OBPrivacyIdentifier const OBPrivacyBusinessChatIdentifier NS_SWIFT_NAME(businessChat);
extern OBPrivacyIdentifier const OBPrivacyCameraIdentifier NS_SWIFT_NAME(camera);
extern OBPrivacyIdentifier const OBPrivacyCellularActivationIdentifier NS_SWIFT_NAME(cellularActivation);
extern OBPrivacyIdentifier const OBPrivacyClassKitIdentifier NS_SWIFT_NAME(classKit);
extern OBPrivacyIdentifier const OBPrivacyCloudCallingIdentifier NS_SWIFT_NAME(cloudCalling);
extern OBPrivacyIdentifier const OBPrivacyContactTracingIdentifier NS_SWIFT_NAME(contactTracing);
extern OBPrivacyIdentifier const OBPrivacyDictationIdentifier NS_SWIFT_NAME(dictation);
extern OBPrivacyIdentifier const OBPrivacyEmergencySOSIdentifier NS_SWIFT_NAME(emergencySOS);
extern OBPrivacyIdentifier const OBPrivacyFaceIDIdentifier NS_SWIFT_NAME(faceID);
extern OBPrivacyIdentifier const OBPrivacyFamilySetupIdentifier NS_SWIFT_NAME(familySetup);
extern OBPrivacyIdentifier const OBPrivacyFindMyIdentifier NS_SWIFT_NAME(findMy);
extern OBPrivacyIdentifier const OBPrivacyFitnessPlusIdentifier NS_SWIFT_NAME(fitnessPlus);
extern OBPrivacyIdentifier const OBPrivacyGameCenterIdentifier NS_SWIFT_NAME(gameCenter);
extern OBPrivacyIdentifier const OBPrivacyGymKitIdentifier NS_SWIFT_NAME(gymKit);
extern OBPrivacyIdentifier const OBPrivacyHealthRecordsIdentifier NS_SWIFT_NAME(healthRecords);
extern OBPrivacyIdentifier const OBPrivacyImproveFitnessPlusIdentifier NS_SWIFT_NAME(improveFitnessPlus);
extern OBPrivacyIdentifier const OBPrivacyImproveHandwashingIdentifier NS_SWIFT_NAME(improveHandwashing);
extern OBPrivacyIdentifier const OBPrivacyImproveHealthIdentifier NS_SWIFT_NAME(improveHealth);
extern OBPrivacyIdentifier const OBPrivacyImproveHealthRecordsIdentifier NS_SWIFT_NAME(improveHealthRecords);
extern OBPrivacyIdentifier const OBPrivacyImproveMapsIdentifier NS_SWIFT_NAME(improveMaps);
extern OBPrivacyIdentifier const OBPrivacyImproveSiriIdentifier NS_SWIFT_NAME(improveSiri);
extern OBPrivacyIdentifier const OBPrivacyLIDARCameraIdentifier NS_SWIFT_NAME(lidarCamera);
extern OBPrivacyIdentifier const OBPrivacyLocationServicesIdentifier NS_SWIFT_NAME(locationServices);
extern OBPrivacyIdentifier const OBPrivacyMapsIdentifier NS_SWIFT_NAME(maps);
extern OBPrivacyIdentifier const OBPrivacyMapsRAPIdentifier NS_SWIFT_NAME(mapsReportAProblem);
extern OBPrivacyIdentifier const OBPrivacyMapsRatingsPhotosIdentifier NS_SWIFT_NAME(mapsRatingsPhotos);
extern OBPrivacyIdentifier const OBPrivacyMapsRoutingIdentifier NS_SWIFT_NAME(mapsRouting);
extern OBPrivacyIdentifier const OBPrivacyNewsIdentifier NS_SWIFT_NAME(news);
extern OBPrivacyIdentifier const OBPrivacyNewsletterIdentifier NS_SWIFT_NAME(newsletter);
extern OBPrivacyIdentifier const OBPrivacyNicknameBluetoothDevicesIdentifier NS_SWIFT_NAME(nicknameBluetoothDevices);
extern OBPrivacyIdentifier const OBPrivacyPasswordsIdentifier NS_SWIFT_NAME(passwords);
extern OBPrivacyIdentifier const OBPrivacyPodcastsIdentifier NS_SWIFT_NAME(podcasts);
extern OBPrivacyIdentifier const OBPrivacyPrivacyPaneIdentifier NS_SWIFT_NAME(privacyPane);
extern OBPrivacyIdentifier const OBPrivacyPrivacyPaneMiniIdentifier NS_SWIFT_NAME(privacyPaneMini);
extern OBPrivacyIdentifier const OBPrivacyResearchAppIdentifier NS_SWIFT_NAME(researchApp);
extern OBPrivacyIdentifier const OBPrivacySMSFilteringIdentifier NS_SWIFT_NAME(smsFiltering);
extern OBPrivacyIdentifier const OBPrivacySafariIdentifier NS_SWIFT_NAME(safari);
extern OBPrivacyIdentifier const OBPrivacySafariSearchIdentifier NS_SWIFT_NAME(safariSearch);
extern OBPrivacyIdentifier const OBPrivacySearchIdentifier NS_SWIFT_NAME(search);
extern OBPrivacyIdentifier const OBPrivacySensorUsageIdentifier NS_SWIFT_NAME(sensorUsage);
extern OBPrivacyIdentifier const OBPrivacySignInWithAppleIdentifier NS_SWIFT_NAME(signInWithApple);
extern OBPrivacyIdentifier const OBPrivacySiriIdentifier NS_SWIFT_NAME(siri);
extern OBPrivacyIdentifier const OBPrivacySiriSuggestionsIdentifier NS_SWIFT_NAME(siriSuggestions);
extern OBPrivacyIdentifier const OBPrivacySpotlightSearchIdentifier NS_SWIFT_NAME(spotlightSearch);
extern OBPrivacyIdentifier const OBPrivacySpotlightSuggestionsIdentifier NS_SWIFT_NAME(spotlightSuggestions);
extern OBPrivacyIdentifier const OBPrivacyStocksIdentifier NS_SWIFT_NAME(stocks);
extern OBPrivacyIdentifier const OBPrivacyTVAppIdentifier NS_SWIFT_NAME(tvApp);
extern OBPrivacyIdentifier const OBPrivacyTVProviderIdentifier NS_SWIFT_NAME(tvProvider);
extern OBPrivacyIdentifier const OBPrivacyTranslateIdentifier NS_SWIFT_NAME(translate);
extern OBPrivacyIdentifier const OBPrivacyWalletIdentifier NS_SWIFT_NAME(wallet);
extern OBPrivacyIdentifier const OBPrivacyWheelchairIdentifier NS_SWIFT_NAME(wheelchair);
extern OBPrivacyIdentifier const OBPrivacyiBooksIdentifier NS_SWIFT_NAME(iBooks);
extern OBPrivacyIdentifier const OBPrivacyiCloudKeychainIdentifier NS_SWIFT_NAME(iCloudKeychain);
extern OBPrivacyIdentifier const OBPrivacyiMessageFaceTimeIdentifier NS_SWIFT_NAME(iMessageFaceTime);
extern OBPrivacyIdentifier const OBPrivacyiTunesStoreIdentifier NS_SWIFT_NAME(iTunesStore);
extern OBPrivacyIdentifier const OBPrivacyiTunesUIdentifier NS_SWIFT_NAME(iTunesU);

#pragma mark - Enumerations

/// What `OBTemplateView` builds around its title, chosen when it is created: the `contentLayoutStyle` argument of its
/// initializers and its `layoutStyle` property, which is read only while the view is created.
typedef NS_ENUM(NSInteger, OBTemplateLayoutStyle) {
    /// An icon above the title, nothing else. Values 0, 1 and 4 build the same views.
    OBTemplateLayoutStyleDefault = 0,
    /// The value the large-content initializer and the privacy pages pass.
    OBTemplateLayoutStyleLargeContent = 1,
    /// Adds a headline label above the title (`headline`).
    OBTemplateLayoutStyleHeadline = 2,
    /// Adds a top content container (`topContent`) filled white in the light appearance and black in the dark one.
    OBTemplateLayoutStyleTopContentWithBackground = 3,
    /// The value `-initWithTitle:bodyText:animationView:` passes.
    OBTemplateLayoutStyleAnimation = 4,
    /// Adds a top content container (`topContent`) with no fill.
    OBTemplateLayoutStyleTopContent = 5,
};

/// The overall shape of a template and its bullet list.
typedef NS_ENUM(NSUInteger, OBTemplateType) {
    /// Margins as `OBTemplateTypeStandard`.
    OBTemplateTypeUnspecified = 0,
    /// The privacy pages' shape: content in an inner scroll view, smaller symbol, 68-point side margins.
    OBTemplateTypePrivacy = 1,
    /// What the template initializers set: 175-point side margins, 85 with `needsExtraWideContent`.
    OBTemplateTypeStandard = 2,
    /// A centered icon and 68-point side margins. A bullet list of this type keeps its rows 344 points wide.
    OBTemplateTypeCentered = 3,
};

/// The row metrics of a bullet list, for the list (`bulletListSpacing`) and for a single row (`spacing:`). A new list is
/// `OBBulletListSpacingLarge`.
typedef NS_ENUM(NSInteger, OBBulletListSpacing) {
    /// No metrics. A row made with it, or added to a list set to it, has a zero-size icon, and its symbol overflows onto
    /// the text. On a list it leaves the row width as it was, except that a centered list keeps its rows 344 points wide.
    OBBulletListSpacingDefault = 0,
    /// 40-point icons with 24-point symbols, 12 points between icon and text, rows centered vertically; the list is 382
    /// points wide, 562 with `needsExtraWideContent`.
    OBBulletListSpacingLarge = 1,
    /// 24-point icons with 15-point symbols, 16 points between icon and text, rows aligned to the top; the list is 420
    /// points wide, 600 with `needsExtraWideContent`.
    OBBulletListSpacingCompact = 2,
};

/// The device a privacy page's text is written for. Pages have per-device wording ("this Mac", "this iPhone").
typedef NS_ENUM(NSUInteger, OBDeviceType) {
    /// The device the code runs on.
    OBDeviceTypeCurrent = 0,
    OBDeviceTypeIPhone = 1,
    OBDeviceTypeIPad = 2,
    OBDeviceTypeIPod = 3,
    OBDeviceTypeMac = 4,
    OBDeviceTypeAppleTV = 5,
    OBDeviceTypeHomePod = 6,
    OBDeviceTypeWatch = 7,
    OBDeviceTypeVision = 8,
    OBDeviceTypeHomeAccessory = 9,
};

/// Which privacy bundles `-[OBBundleManager orderedPrivacyBundlesWithInclusionOptions:]` returns.
typedef NS_OPTIONS(NSUInteger, OBBundleInclusionOptions) {
    /// The ordinary privacy bundles.
    OBBundleInclusionOptionsPrivacyBundles = 1 << 0,
    /// The Privacy pane's own bundle, added if missing.
    OBBundleInclusionOptionsPrivacyPaneBundle = 1 << 1,
    /// Every replacement bundle.
    OBBundleInclusionOptionsAllReplacementBundles = 1 << 2,
    /// The replacement bundles whose preconditions hold, in place of the bundles they replace.
    OBBundleInclusionOptionsApplicableReplacementBundles = 1 << 3,
    /// The link bundles.
    OBBundleInclusionOptionsLinkBundles = 1 << 4,
};

#pragma mark - Protocols

/// Adopted by objects an `OBAnimationView` tells when the effective appearance changes.
@protocol OBAnimationAppearanceChangeDelegate <NSObject>
- (void)updateAnimationForAppearanceChange;
@end

/// Locates a privacy bundle (`.bundle` with the page's text and images) on disk.
API_AVAILABLE(macos(13.0))
@protocol OBPrivacyBundleProvider <NSObject>
@property (readonly, copy) NSString *path;
@end

/// Adopted by the window controllers `OBPrivacyPresenter` shows.
NS_SWIFT_UI_ACTOR
@protocol OBPrivacyPresenting <NSObject>
- (void)prepareToPresent;
@end

#pragma mark - Bundles and capabilities

/// One privacy bundle: the localized text, images and metadata of a privacy page.
@interface OBBundle : NSObject

+ (nullable instancetype)bundleWithIdentifier:(OBPrivacyIdentifier)identifier;
+ (nullable instancetype)bundleAtPath:(NSString *)path;
+ (nullable instancetype)bundleAtPath:(NSString *)path placeholderIdentifier:(NSString *)placeholderIdentifier;
+ (nullable instancetype)bundleAtPath:(NSString *)path isLinkBundle:(BOOL)isLinkBundle isReplacementBundle:(BOOL)isReplacementBundle API_AVAILABLE(macos(15.0));
/// [unverified] Builds a bundle identifier from a bundle name.
+ (NSString *)identifierWithName:(NSString *)name;
/// [unverified] The bundle name inside an identifier.
+ (nullable NSString *)nameFromIdentifier:(NSString *)identifier API_AVAILABLE(macos(15.2));

- (nullable instancetype)initWithBundle:(NSBundle *)bundle;
- (nullable instancetype)initWithBundle:(NSBundle *)bundle placeholderIdentifier:(NSString *)placeholderIdentifier;
- (nullable instancetype)initWithBundle:(NSBundle *)bundle isLinkBundle:(BOOL)isLinkBundle isReplacementBundle:(BOOL)isReplacementBundle API_AVAILABLE(macos(15.0));

@property (nonatomic, readonly, copy) OBPrivacyIdentifier identifier;
@property (nonatomic, readonly, copy) NSString *name;
@property (nonatomic, readonly, copy, nullable) NSString *bundleVersion;
@property (nonatomic, readonly, strong) NSBundle *bundle;
@property (nonatomic, readonly, strong) NSBundle *underlyingBundle;
@property (nonatomic) BOOL isPlaceholder;
@property (nonatomic) BOOL isLinkBundle;
@property (nonatomic) BOOL isReplacementBundle API_AVAILABLE(macos(15.0));

@end

/// Finds and caches the privacy bundles installed on the system.
@interface OBBundleManager : NSObject

@property (class, nonatomic, readonly, strong) OBBundleManager *sharedManager;

/// A directory searched instead of the system's privacy bundle directory.
@property (nonatomic, copy, nullable) NSString *overrideBundleSearchPath;

- (nullable OBBundle *)bundleWithIdentifier:(OBPrivacyIdentifier)identifier;
- (NSArray<OBBundle *> *)bundlesWithIdentifiers:(NSArray<OBPrivacyIdentifier> *)identifiers;
- (NSArray<OBBundle *> *)orderedPrivacyBundlesWithInclusionOptions:(OBBundleInclusionOptions)inclusionOptions API_AVAILABLE(macos(15.0));
- (nullable OBBundle *)privacyLinkBundleForBundles:(NSArray<OBBundle *> *)bundles;
- (nullable OBBundle *)privacyLinkBundleForIdentifiers:(NSArray<OBPrivacyIdentifier> *)identifiers API_AVAILABLE(macos(15.2));

@end

/// Device and policy facts the privacy pages read, with overrides for testing.
@interface OBCapabilities : NSObject

@property (class, nonatomic, readonly, strong) OBCapabilities *sharedCapabilities;

@property (nonatomic) BOOL preventURLDataDetection;
@property (nonatomic) BOOL preventOpeningSafari;
@property (nonatomic, strong, nullable) NSNumber *overrideEligibleForChlorine API_AVAILABLE(macos(15.0));
@property (nonatomic, copy, nullable) NSString *overrideAdditionalDisplayLanguage API_AVAILABLE(macos(15.2));
@property (nonatomic, strong, nullable) NSNumber *overrideEligibilityForGreymatterHasCountryPolicyChina API_AVAILABLE(macos(15.4));
@property (nonatomic, strong, nullable) NSNumber *overrideDeviceSupportsGenerativeModels API_AVAILABLE(macos(15.5));

- (nullable NSString *)additionalDisplayLanguageForDisplayLanguage:(NSString *)displayLanguage API_AVAILABLE(macos(15.2));

@end

/// Records which privacy pages and links were shown and tapped.
@interface OBAnalyticsManager : NSObject

@property (class, nonatomic, readonly, strong) OBAnalyticsManager *sharedManager;

- (void)addEvent:(NSString *)event;
- (void)addEvent:(NSString *)event withPayload:(nullable NSDictionary<NSString *, id> *)payload;
- (void)commit;
- (void)logPresentationOfPrivacyLinkWithIdentifier:(OBPrivacyIdentifier)identifier;
- (void)logPresentationOfPrivacySplashWithIdentifier:(OBPrivacyIdentifier)identifier;
- (void)logPresentationOfPrivacyUnifiedAbout;
- (void)logTapOnPrivacyLinkWithIdentifier:(OBPrivacyIdentifier)identifier;

@end

#pragma mark - Utilities

@interface OBUtilities : NSObject

/// Looks a key up in a strings table of a bundle, in the given localization (a language code).
+ (nullable NSString *)localizedString:(NSString *)key forTable:(nullable NSString *)table inBundle:(NSBundle *)bundle forLanguage:(nullable NSString *)language;

@end

@interface OBTemplateUIUtilities : NSObject

/// Prefixes text with an image attachment, scaled to the custom bounds.
+ (NSMutableAttributedString *)addLeadingImage:(NSImage *)image toText:(NSString *)text customBounds:(CGRect)customBounds attributes:(nullable NSDictionary<NSAttributedStringKey, id> *)attributes;

@end

@interface NSImage (OnBoardingKit)

/// The chevron the expandable bullet list items show: pointing right when collapsed, down when expanded.
+ (nullable NSImage *)disclosureChevronImageWithExpandedState:(BOOL)expandedState API_AVAILABLE(macos(26.0));

@end

#pragma mark - Privacy flows

/// The content of a privacy page you build yourself instead of loading from a privacy bundle.
@interface OBSplashContent : NSObject
@property (copy, nullable) NSString *text;
@property (copy, nullable) NSArray<OBSplashBullet *> *bullets;
@end

/// One bullet of an `OBSplashContent`.
@interface OBSplashBullet : NSObject
@property (copy, nullable) NSString *text;
@property (strong, nullable) NSImage *icon;
@end

/// The abstract superclass of the flows the framework presents.
@interface OBFlow : NSObject
@end

/// The localized content of one privacy page, read from a privacy bundle or built from an `OBSplashContent`.
@interface OBPrivacyFlow : OBFlow

+ (nullable instancetype)flowWithBundle:(OBBundle *)bundle;
- (nullable instancetype)initWithBundle:(OBBundle *)bundle;
- (instancetype)initWithSplashContent:(OBSplashContent *)splashContent;

@property (nonatomic, readonly, copy) OBPrivacyIdentifier identifier;
@property (nonatomic, readonly) NSInteger contentVersion;
@property (nonatomic, readonly) BOOL platformSupported;
@property (nonatomic, readonly) BOOL showInCombinedList;
@property (nonatomic, readonly) BOOL enablesGroupingInCombinedList;
@property (nonatomic, readonly, getter=isPersonallyIdentifiable) BOOL personallyIdentifiable;
@property (nonatomic, readonly, strong, nullable) NSImage *buttonIcon;
@property (nonatomic, readonly, copy, nullable) NSString *localizedButtonTitle;
@property (nonatomic, readonly, copy, nullable) NSString *localizedButtonCaption;
@property (nonatomic, readonly, copy, nullable) NSString *localizedTitle;
@property (nonatomic, readonly, copy, nullable) NSString *localizedShortTitle;
@property (nonatomic, readonly, copy, nullable) NSString *localizedCombinedHeader;
@property (nonatomic, readonly, copy, nullable) NSAttributedString *localizedCombinedFooter;
@property (nonatomic, readonly, copy, nullable) NSArray<NSString *> *localizedContentList;

- (nullable NSString *)localizedButtonTitleForLanguage:(nullable NSString *)language preferredDeviceType:(OBDeviceType)preferredDeviceType;
- (nullable NSString *)localizedButtonCaptionForLanguage:(nullable NSString *)language preferredDeviceType:(OBDeviceType)preferredDeviceType;
- (nullable NSString *)localizedButtonCaptionSymbolNameForLanguage:(nullable NSString *)language preferredDeviceType:(OBDeviceType)preferredDeviceType API_AVAILABLE(macos(15.6));
- (nullable NSString *)localizedButtonSecondaryCaptionForLanguage:(nullable NSString *)language preferredDeviceType:(OBDeviceType)preferredDeviceType API_AVAILABLE(macos(27.0));
- (nullable NSString *)localizedTitleForLanguage:(nullable NSString *)language preferredDeviceType:(OBDeviceType)preferredDeviceType;
- (nullable NSString *)localizedShortTitleForLanguage:(nullable NSString *)language preferredDeviceType:(OBDeviceType)preferredDeviceType;
- (nullable NSString *)localizedCombinedHeaderForLanguage:(nullable NSString *)language preferredDeviceType:(OBDeviceType)preferredDeviceType;
- (nullable NSAttributedString *)localizedCombinedFooterForLanguage:(nullable NSString *)language preferredDeviceType:(OBDeviceType)preferredDeviceType;
- (nullable OBPrivacyCombinedFooterComponents *)localizedCombinedFooterComponentsForLanguage:(nullable NSString *)language preferredDeviceType:(OBDeviceType)preferredDeviceType API_AVAILABLE(macos(15.2));
- (nullable NSArray<NSString *> *)localizedContentListForLanguage:(nullable NSString *)language preferredDeviceType:(OBDeviceType)preferredDeviceType;
- (BOOL)showInCombinedListForPreferredDeviceType:(OBDeviceType)preferredDeviceType API_AVAILABLE(macos(26.0));
- (BOOL)supportsPlatformForPreferredDeviceType:(OBDeviceType)preferredDeviceType API_AVAILABLE(macos(26.0));

@end

/// Privacy flows that share a combined-list header.
@interface OBPrivacyFlowGroup : NSObject

+ (NSArray<OBPrivacyFlowGroup *> *)groupFlowsByCombinedHeader:(NSArray<OBPrivacyFlow *> *)flows language:(nullable NSString *)language preferredDeviceType:(OBDeviceType)preferredDeviceType;
- (instancetype)initWithIdentifier:(NSString *)identifier privacyFlows:(NSArray<OBPrivacyFlow *> *)privacyFlows;

@property (nonatomic, copy) NSString *identifier;
@property (nonatomic, copy) NSArray<OBPrivacyFlow *> *privacyFlows;

@end

/// Points at a privacy bundle inside another bundle by name.
@interface OBPrivacyBundleProvider : NSObject <OBPrivacyBundleProvider>

- (instancetype)initWithEnclosingBundleIdentifier:(NSString *)enclosingBundleIdentifier privacyBundleName:(NSString *)privacyBundleName;

@property (copy) NSString *enclosingBundleIdentifier;
@property (copy) NSString *privacyBundleName;

@end

/// The parts of a combined privacy page's footer: text, and a link that replaces `linkPlaceholder` in it.
API_AVAILABLE(macos(15.2))
@interface OBPrivacyCombinedFooterComponents : NSObject

@property (class, nonatomic, readonly, copy) NSString *linkPlaceholder;
@property (nonatomic, copy, nullable) NSString *text;
@property (nonatomic, copy, nullable) NSString *linkText;
@property (nonatomic, copy, nullable) NSString *linkURLString;

@end

#pragma mark - Animation

/// A state of an animation package: its layer state name, the dark appearance's, and how to get there.
@interface OBAnimationState : NSObject

- (instancetype)initWithStateName:(NSString *)stateName transitionDuration:(NSTimeInterval)transitionDuration transitionSpeed:(CGFloat)transitionSpeed;
- (instancetype)initWithStateName:(NSString *)stateName darkStateName:(nullable NSString *)darkStateName transitionDuration:(NSTimeInterval)transitionDuration transitionSpeed:(CGFloat)transitionSpeed;

@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy, nullable) NSString *darkName;
@property (nonatomic) NSTimeInterval transitionDuration;
@property (nonatomic) CGFloat transitionSpeed;

@end

/// Shows a Core Animation package, tinted with the accent color when asked to.
@interface OBAnimationView : NSView <CALayerDelegate>

@property (nonatomic, strong, nullable) CAPackage *package;
@property (nonatomic, strong, nullable) CALayer *packageLayer;
@property (nonatomic) CGRect preferredFrame;
@property (nonatomic) CGFloat scale;
@property (nonatomic, readonly) CGFloat defaultScale;
@property (nonatomic) BOOL flipForRTL;
@property (nonatomic) BOOL centerAlignAnimation API_AVAILABLE(macos(26.1));
@property (nonatomic) BOOL useAccentColor;
@property (nonatomic) BOOL useHueRotation;
@property (nonatomic) BOOL accentUsesHSV;
@property (nonatomic) CGFloat accentRadianDelta;
@property (nonatomic) CGFloat accentBrightnessValue;
@property (nonatomic) BOOL needsBrightnessAdjustment;
@property (nonatomic, weak, nullable) id<OBAnimationAppearanceChangeDelegate> appearanceChangeDelegate;

- (void)setPackage:(CAPackage *)package sizingTransformScale:(CGFloat)sizingTransformScale;

@end

/// Steps an `OBAnimationView` through a list of package states.
NS_SWIFT_UI_ACTOR
@interface OBAnimationController : NSObject <OBAnimationAppearanceChangeDelegate>

+ (nullable CAPackage *)packageForURL:(NSURL *)url;

- (instancetype)initWithUrlToPackage:(NSURL *)packageURL animatedStates:(NSArray<OBAnimationState *> *)animatedStates startAtFirstState:(nullable OBAnimationState *)firstState;
- (instancetype)initWithUrlToPackage:(NSURL *)packageURL sizingTransformScale:(CGFloat)sizingTransformScale animatedStates:(NSArray<OBAnimationState *> *)animatedStates startAtFirstState:(nullable OBAnimationState *)firstState;
- (instancetype)initWithUrlToPackage:(NSURL *)packageURL animationView:(OBAnimationView *)animationView animatedStates:(NSArray<OBAnimationState *> *)animatedStates startAtFirstState:(nullable OBAnimationState *)firstState;
- (instancetype)initWithUrlToPackage:(NSURL *)packageURL animationView:(OBAnimationView *)animationView sizingTransformScale:(CGFloat)sizingTransformScale animatedStates:(NSArray<OBAnimationState *> *)animatedStates startAtFirstState:(nullable OBAnimationState *)firstState;

@property (nonatomic, strong, nullable) CAPackage *package;
@property (nonatomic, strong, nullable) CAStateController *stateController;
@property (nonatomic, strong, nullable) OBAnimationView *animationView;
@property (nonatomic, copy) NSArray<OBAnimationState *> *animatedStates;
@property (nonatomic, strong, nullable) OBAnimationState *firstState;
@property (nonatomic) NSInteger stateIndex;
@property (nonatomic) BOOL canceled;

- (void)startAnimation;
- (void)stopAnimation;

@end

#pragma mark - Template parts

/// The link-styled button of a template ("Learn More…"): accent-colored title, pointing-hand cursor.
@interface OBTemplatePartLinkButton : NSButton

@property (nonatomic, strong, nullable) NSColor *titleColor API_AVAILABLE(macos(26.0));
/// Shows an info symbol after the title.
@property BOOL displayInfoIcon API_AVAILABLE(macos(26.0));

@end

/// One row of an `OBTemplatePartBulletList`: an icon, a title, a description and an optional status line.
@interface OBTemplatePartBulletListItem : NSView

- (instancetype)initWithTitle:(nullable NSString *)title description:(nullable NSString *)description image:(nullable NSImage *)image imageTintColor:(nullable NSColor *)imageTintColor spacing:(OBBulletListSpacing)spacing showsBackground:(BOOL)showsBackground;
- (instancetype)initWithTitle:(nullable NSString *)title description:(nullable NSString *)description image:(nullable NSImage *)image imageTintColor:(nullable NSColor *)imageTintColor spacing:(OBBulletListSpacing)spacing status:(nullable NSString *)status showsBackground:(BOOL)showsBackground;
- (instancetype)initWithTitle:(nullable NSString *)title description:(nullable NSString *)description symbol:(nullable NSString *)symbol symbolTintColor:(nullable NSColor *)symbolTintColor spacing:(OBBulletListSpacing)spacing showsBackground:(BOOL)showsBackground;
- (instancetype)initWithTitle:(nullable NSString *)title description:(nullable NSString *)description symbol:(nullable NSString *)symbol symbolTintColor:(nullable NSColor *)symbolTintColor spacing:(OBBulletListSpacing)spacing status:(nullable NSString *)status showsBackground:(BOOL)showsBackground;

@property (nonatomic, strong, nullable) NSImageView *imageView;
@property (nonatomic, strong, nullable) NSView *imageContainer;
@property (nonatomic, strong, nullable) NSTextField *titleLabel;
@property (nonatomic, strong, nullable) NSTextField *descriptionLabel;
@property (nonatomic, strong, nullable) NSTextField *statusLabel;
@property (nonatomic, strong, nullable) NSStackView *stackView;
@property (nonatomic, strong, nullable) NSStackView *textStack API_AVAILABLE(macos(13.0));
@property BOOL showsBackground;
@property CGFloat iconWidth;
@property CGFloat iconHeight;
/// The point size of the symbol in the icon.
@property NSInteger iconFontSize;
@property CGFloat iconTextSpacing;
@property NSLayoutAttribute stackAlignment;
@property (nonatomic, strong, nullable) NSColor *layerBackgroundColor;

- (void)updateImage:(NSImage *)image withColor:(nullable NSColor *)color;
- (void)updateSymbol:(NSString *)symbolName withColor:(nullable NSColor *)color;

@end

/// A bullet list item that expands to show sub-items when clicked. The sub-items join `expandableStack` when the row
/// is expanded, by a click or by setting `expanded`; until then the row keeps them aside.
@interface OBTemplatePartBulletExpandableListItem : NSView

- (instancetype)initWithListItem:(OBTemplatePartBulletListItem *)listItem showsBackground:(BOOL)showsBackground;

@property (nonatomic, strong, nullable) OBTemplatePartBulletListItem *listItem;
@property (nonatomic) BOOL expanded;
@property (nonatomic) BOOL showsBackground;
@property (nonatomic, strong, nullable) NSStackView *stackView;
@property (nonatomic, strong, nullable) NSStackView *expandableStack;
@property (nonatomic, strong, nullable) NSImageView *chevronImageView;
@property (nonatomic, strong, nullable) NSView *separatorView;

- (void)addSublistItem:(OBTemplatePartBulletListItem *)sublistItem;
- (void)addSublistItems:(NSArray<OBTemplatePartBulletListItem *> *)sublistItems;

@end

/// A vertical list of icon-and-text rows, the feature list of a "What's New" page. Create it with `-initWithFrame:`,
/// add rows with the `-addItem…` methods, and set it as an `OBTemplateView`'s `contentArea`.
///
/// `symbol:` takes an SF Symbol name (the framework falls back to its private symbols when the public set has none of
/// that name); `image:` takes an image of your own. Every text argument is plain text.
@interface OBTemplatePartBulletList : NSScrollView

@property (strong, nullable) NSStackView *stack;
@property (nonatomic) OBTemplateType templateType;
@property (nonatomic) BOOL needsExtraWideContent;
@property (nonatomic) OBBulletListSpacing bulletListSpacing;
@property (nonatomic) BOOL bulletsHaveBackgrounds;
@property CGFloat itemWidth;
@property CGFloat itemInset;

- (void)addItemWithTitle:(nullable NSString *)title description:(nullable NSString *)description symbol:(nullable NSString *)symbol symbolTintColor:(nullable NSColor *)symbolTintColor;
- (void)addItemWithTitle:(nullable NSString *)title description:(nullable NSString *)description symbol:(nullable NSString *)symbol symbolTintColor:(nullable NSColor *)symbolTintColor status:(nullable NSString *)status;
- (void)addItemWithTitle:(nullable NSString *)title description:(nullable NSString *)description image:(nullable NSImage *)image imageTintColor:(nullable NSColor *)imageTintColor;
- (void)addItemWithTitle:(nullable NSString *)title description:(nullable NSString *)description image:(nullable NSImage *)image imageTintColor:(nullable NSColor *)imageTintColor status:(nullable NSString *)status;
- (void)addItemWithDescription:(nullable NSString *)description symbol:(nullable NSString *)symbol symbolTintColor:(nullable NSColor *)symbolTintColor;
- (void)addItemWithDescription:(nullable NSString *)description symbol:(nullable NSString *)symbol symbolTintColor:(nullable NSColor *)symbolTintColor status:(nullable NSString *)status;
- (void)addItemWithDescription:(nullable NSString *)description image:(nullable NSImage *)image imageTintColor:(nullable NSColor *)imageTintColor;
- (void)addItemWithDescription:(nullable NSString *)description image:(nullable NSImage *)image imageTintColor:(nullable NSColor *)imageTintColor status:(nullable NSString *)status;
/// Adds a row that shows `sublistItems` below it when clicked. With an empty `sublistItems` the framework logs an
/// error and adds nothing.
- (void)addExpandableItemWithTitle:(nullable NSString *)title description:(nullable NSString *)description symbol:(nullable NSString *)symbol imageTintColor:(nullable NSColor *)imageTintColor status:(nullable NSString *)status sublistItems:(NSArray<OBTemplatePartBulletListItem *> *)sublistItems;
- (void)addExpandableItemWithTitle:(nullable NSString *)title description:(nullable NSString *)description image:(nullable NSImage *)image imageTintColor:(nullable NSColor *)imageTintColor status:(nullable NSString *)status sublistItems:(NSArray<OBTemplatePartBulletListItem *> *)sublistItems;

@end

/// A row with an icon, a title and a description that discloses an `OBTemplatePartBulletList` below it.
@interface OBTemplatePartDisclosingListView : NSView

- (instancetype)initWithTitle:(nullable NSString *)title description:(nullable NSString *)description symbol:(nullable NSString *)symbol bulletList:(OBTemplatePartBulletList *)bulletList symbolTintColor:(nullable NSColor *)symbolTintColor;
- (instancetype)initWithTitle:(nullable NSString *)title description:(nullable NSString *)description image:(nullable NSImage *)image bulletList:(OBTemplatePartBulletList *)bulletList imageTintColor:(nullable NSColor *)imageTintColor;

@property (nonatomic, copy, nullable) NSString *title;
@property (nonatomic, copy, nullable) NSString *bodyText;
@property (nonatomic, strong, nullable) NSImage *iconImage;
@property (nonatomic, copy, nullable) NSString *iconSymbol;
@property (nonatomic, strong, nullable) OBTemplatePartBulletList *bulletList;
/// Stored and never read: setting it has no effect on macOS 27.2.
@property (nonatomic) OBTemplateType templateType;
@property BOOL needsExtraWideContent;
@property (nonatomic, strong, nullable) NSImageView *imageView;
@property (nonatomic, strong, nullable) NSTextField *titleLabel;
@property (nonatomic, strong, nullable) NSTextField *descriptionLabel;
@property (nonatomic, strong, nullable) NSImageView *disclosureIndicator;

@end

#pragma mark - Template view

/// The content of a welcome, "What's New" or privacy page: an icon or animation at the top, a title, body text, an
/// optional content area (usually an `OBTemplatePartBulletList`), a link button and a privacy link.
///
/// The layout style is read once, while the view is created: pass it to the initializer, since setting `layoutStyle`
/// afterwards only stores the value. The initializers set `templateType` to `OBTemplateTypeStandard`.
///
/// The view builds its subviews the first time it is about to draw (`-viewWillDraw`), not when it is created or moved
/// into a window: until then `subviews` is empty and `contentArea` is not in the hierarchy. Set its properties at any
/// time before that.
@interface OBTemplateView : NSView

/// A template with an SF Symbol (or none) above the title.
- (instancetype)initWithTitle:(NSString *)title bodyText:(nullable NSString *)bodyText symbol:(nullable NSString *)symbol contentLayoutStyle:(OBTemplateLayoutStyle)contentLayoutStyle;
- (instancetype)initWithTitle:(NSString *)title bodyText:(nullable NSString *)bodyText symbol:(nullable NSString *)symbol animated:(BOOL)animated contentLayoutStyle:(OBTemplateLayoutStyle)contentLayoutStyle API_AVAILABLE(macos(26.0));
- (instancetype)initWithTitle:(NSString *)title bodyText:(nullable NSString *)bodyText icon:(nullable NSImage *)icon contentLayoutStyle:(OBTemplateLayoutStyle)contentLayoutStyle;
- (instancetype)initWithTitle:(NSString *)title bodyText:(nullable NSString *)bodyText animationView:(nullable OBAnimationView *)animationView;
- (instancetype)initLargeContentTemplateWithTitle:(NSString *)title contentArea:(nullable NSView *)contentArea needsBodyText:(BOOL)needsBodyText;

@property (class, nonatomic, readonly) NSTextAlignment templateTextAlignment API_AVAILABLE(macos(26.0));

@property (nonatomic, copy, nullable) NSString *title;
@property (nonatomic, copy, nullable) NSString *headline;
@property (nonatomic, copy, nullable) NSString *bodyText;
/// Body text with attributes. The framework keeps only the attributes it allows and drops the rest.
@property (nonatomic, copy, nullable) NSAttributedString *attributedBodyText API_AVAILABLE(macos(15.1));
@property NSTextAlignment bodyTextAlignment;
@property (nonatomic, copy, nullable) NSDictionary<NSAttributedStringKey, id> *attributesForTitle;
@property (nonatomic, copy, nullable) NSDictionary<NSAttributedStringKey, id> *attributesForHeadline;

@property (nonatomic, strong, nullable) NSImage *topImage;
@property (nonatomic, copy, nullable) NSString *topImageSymbolName;
@property (nonatomic, strong, nullable) NSColor *topImageTintColor;
/// A view filling the top content container. Only the `OBTemplateLayoutStyleTopContent…` layout styles create that
/// container; with any other style the view is not shown.
@property (nonatomic, strong, nullable) NSView *topContent;
@property CGFloat topContentOverrideHeight API_AVAILABLE(macos(26.0));
@property (nonatomic, strong, nullable) OBAnimationView *animationView;
/// The effects `-startSymbolAnimation` adds to the top symbol, paired by index with `symbolEffectOptions`. The two
/// arrays must have the same length: an options array shorter than the effects array raises an out-of-bounds exception.
@property (nonatomic, copy, nullable) NSArray<NSSymbolEffect *> *symbolEffects API_AVAILABLE(macos(26.0));
@property (nonatomic, copy, nullable) NSArray<NSSymbolEffectOptions *> *symbolEffectOptions API_AVAILABLE(macos(26.0));

/// The view under the body text, usually an `OBTemplatePartBulletList`.
@property (nonatomic, strong, nullable) NSView *contentArea;
@property BOOL usesLargeContentArea;
@property BOOL needsExtraWideContent;
@property BOOL needsExtraWideContentAreaOnly API_AVAILABLE(macos(26.0));
@property (nonatomic) OBTemplateLayoutStyle layoutStyle;
@property (nonatomic) OBTemplateType templateType;

@property (nonatomic, strong, nullable) OBTemplatePartLinkButton *linkButton;
@property BOOL linkButtonGoesAboveContent;

@property (nonatomic, strong, nullable) OBPrivacyLinkController *privacyLinkController;
@property (nonatomic, copy, nullable) NSArray<OBPrivacyIdentifier> *privacyBundleIdentifiers;
@property (nonatomic, copy, nullable) void (^privacyLinkCallback)(void) API_AVAILABLE(macos(26.0));

@property (nonatomic, strong, nullable) NSTextField *titleView;
@property (nonatomic, strong, nullable) NSTextField *headlineView;
@property (nonatomic, strong, nullable) NSTextField *bodyTextView;
@property (nonatomic, strong, nullable) NSImageView *iconImageView;
@property (nonatomic, strong, nullable) NSView *topContentView;
@property (nonatomic, strong, nullable) NSView *contentView;
@property (nonatomic, strong, nullable) NSView *privacyLinkView;
@property (nonatomic, strong, nullable) NSButton *privacyLinkButton;

- (void)setPrivacyLinkForBundles:(NSArray<OBPrivacyIdentifier> *)bundleIdentifiers;
- (void)setPrivacyLinkForBundles:(NSArray<OBPrivacyIdentifier> *)bundleIdentifiers withLanguage:(nullable NSString *)language;
- (void)setPrivacyLinkHidden:(BOOL)hidden;
- (void)setTopImageHidden:(BOOL)hidden;
- (void)setTopImageSymbolName:(NSString *)symbolName animated:(BOOL)animated API_AVAILABLE(macos(26.0));
- (void)setTopImageSymbolName:(NSString *)symbolName withAccesibilityDescription:(nullable NSString *)accessibilityDescription animated:(BOOL)animated API_AVAILABLE(macos(26.0));
- (void)setTopImageSymbolName:(NSString *)symbolName withAccesibilityDescription:(nullable NSString *)accessibilityDescription additionalConfiguration:(nullable NSImageSymbolConfiguration *)additionalConfiguration animated:(BOOL)animated API_AVAILABLE(macos(26.4));
- (void)setTopImageSymbolAnimationEffects:(nullable NSArray<NSSymbolEffect *> *)effects options:(nullable NSArray<NSSymbolEffectOptions *> *)options API_AVAILABLE(macos(26.0));
- (void)setTopAnimationAccessibilityDescription:(nullable NSString *)accessibilityDescription API_AVAILABLE(macos(15.0));
- (void)startSymbolAnimation API_AVAILABLE(macos(26.0));
- (void)addLeadingImageToTemplateTitle:(NSImage *)image customBounds:(CGRect)customBounds;
- (BOOL)hasBodyText API_AVAILABLE(macos(26.0));
/// Animates the title's opacity. The completion handler is required: the framework calls it without checking for nil.
- (void)fadeTitleToAlpha:(CGFloat)alpha duration:(NSTimeInterval)duration completionHandler:(void (^)(void))completionHandler API_AVAILABLE(macos(26.0));
/// Animates the body text's opacity. The completion handler is required: the framework calls it without checking for nil.
- (void)fadeBodyToAlpha:(CGFloat)alpha duration:(NSTimeInterval)duration completionHandler:(void (^)(void))completionHandler API_AVAILABLE(macos(26.0));

@end

#pragma mark - Container view controller

/// Hosts an `OBTemplateView` above a button tray, the way the system's welcome and "What's New" sheets look.
///
/// Before macOS 26 the tray holds a first (default) button, a second button and a link-styled button. From macOS 26
/// on it holds a primary, a secondary and a cancel button: first is primary, second is cancel and link is secondary,
/// and the first/second/link initializers keep working. A button whose title is nil or empty is hidden.
///
/// The controller creates the buttons without a target, an action or a key equivalent: the caller wires them, as the
/// framework's own privacy pages do.
@interface OBTemplateContainerViewController : NSViewController

- (instancetype)initWithTemplateView:(OBTemplateView *)templateView firstButtonTitle:(NSString *)firstButtonTitle secondButtonTitle:(nullable NSString *)secondButtonTitle linkButtonTitle:(nullable NSString *)linkButtonTitle;
/// The initializer the other three call. Set `templateView` afterwards.
- (instancetype)initWithFirstButtonTitle:(NSString *)firstButtonTitle secondButtonTitle:(nullable NSString *)secondButtonTitle linkButtonTitle:(nullable NSString *)linkButtonTitle;
- (instancetype)initWithTemplateView:(OBTemplateView *)templateView primaryButtonTitle:(NSString *)primaryButtonTitle secondaryButtonTitle:(nullable NSString *)secondaryButtonTitle cancelButtonTitle:(nullable NSString *)cancelButtonTitle API_AVAILABLE(macos(26.0));
- (instancetype)initWithPrimaryButtonTitle:(NSString *)primaryButtonTitle secondaryButtonTitle:(nullable NSString *)secondaryButtonTitle cancelButtonTitle:(nullable NSString *)cancelButtonTitle API_AVAILABLE(macos(26.0));

@property (nonatomic, strong, nullable) OBTemplateView *templateView;

@property (nonatomic, readonly, nullable) NSButton *firstButton;
@property (nonatomic, readonly, nullable) NSButton *secondButton;
@property (nonatomic, readonly, nullable) NSButton *linkButton;
@property (nonatomic, strong, nullable) NSButton *primaryButton API_AVAILABLE(macos(26.0));
@property (nonatomic, strong, nullable) NSButton *secondaryButton API_AVAILABLE(macos(26.0));
@property (nonatomic, strong, nullable) NSButton *cancelButton API_AVAILABLE(macos(26.0));
/// The back button (a private NSButton subclass), shown at the top leading corner when set up.
@property (nonatomic, strong, nullable) NSButton *backButton API_AVAILABLE(macos(26.0));

@property (nonatomic, strong, nullable) NSView *templateContainerView;
@property (nonatomic, strong, nullable) NSView *buttonTray;
@property (nonatomic, strong, nullable) NSBox *divider;
@property (nonatomic, strong, nullable) NSProgressIndicator *spinner;
@property (nonatomic, strong, nullable) NSTextField *statusMessage;
@property (nonatomic, setter=setSpinnerVisible:) BOOL spinnerVisible;

/// Enables or disables every button of the tray.
- (void)setControlsEnabled:(BOOL)enabled;
/// Disables the buttons and, after the delay, shows a spinner with the status text.
- (void)disableControlsWithStatus:(nullable NSString *)status showingSpinnerAfter:(NSTimeInterval)delay;
- (void)showSpinnerWithMessage:(nullable NSString *)message API_AVAILABLE(macos(15.0));
- (void)hideSpinner API_AVAILABLE(macos(15.0));

@end

#pragma mark - Privacy pages

/// The "Data & Privacy" link with the privacy icon that sits under a template's content. Clicking it shows the page.
///
/// Create one with a `+link…` factory: they return an `OBPrivacyLinkController_macOS`, the subclass that builds the
/// view, or nil when the identifiers or bundles are nil or empty. The base class's own initializers create a
/// controller without a view, so Swift does not offer them.
@interface OBPrivacyLinkController : NSViewController

+ (nullable instancetype)linkWithBundleIdentifier:(OBPrivacyIdentifier)bundleIdentifier;
+ (nullable instancetype)linkWithBundleIdentifiers:(NSArray<OBPrivacyIdentifier> *)bundleIdentifiers;
+ (nullable instancetype)linkWithBundleAtPath:(NSString *)path;
+ (nullable instancetype)linkWithBundlesAtPaths:(NSArray<NSString *> *)paths;
+ (nullable instancetype)linkWithPrivacyBundle:(OBBundle *)privacyBundle API_AVAILABLE(macos(15.0));

- (instancetype)init NS_SWIFT_UNAVAILABLE("Use OBPrivacyLinkController.link(withBundleIdentifiers:)");
- (nullable instancetype)initWithBundleIdentifiers:(NSArray<OBPrivacyIdentifier> *)bundleIdentifiers NS_SWIFT_UNAVAILABLE("Use OBPrivacyLinkController.link(withBundleIdentifiers:)");
- (nullable instancetype)initWithPrivacyBundle:(OBBundle *)privacyBundle NS_SWIFT_UNAVAILABLE("Use OBPrivacyLinkController.link(withPrivacyBundle:)");
- (nullable instancetype)initWithPrivacyBundles:(NSArray<OBBundle *> *)privacyBundles NS_SWIFT_UNAVAILABLE("Use OBPrivacyLinkController.link(withBundlesAtPaths:)");

@property (readonly, strong, nullable) OBBundle *bundle;
@property (readonly, copy, nullable) NSArray<OBBundle *> *bundles;
@property (readonly, strong, nullable) OBPrivacyFlow *flow;
@property (strong, nullable) NSColor *iconTintColor;
@property (strong, nullable) NSColor *textTintColor;
@property NSTextAlignment textAlignment;
@property BOOL displayIcon;
@property BOOL displayLargeIcon;
@property BOOL displayCaptionText;
@property BOOL displayInfoIcon API_AVAILABLE(macos(26.0));
@property BOOL allowsOpeningSafari;
@property (copy, nullable) NSString *displayLanguage;
@property OBDeviceType displayDeviceType;
/// Called when the link is clicked, after the page is shown.
@property (nonatomic, copy, nullable) void (^privacyLinkCallback)(void) API_AVAILABLE(macos(26.0));

@end

/// The macOS implementation the `+link…` factories of `OBPrivacyLinkController` create.
@interface OBPrivacyLinkController_macOS : OBPrivacyLinkController
@end

/// A window controller showing one privacy page.
@interface OBPrivacySplashController : NSWindowController <OBPrivacyPresenting>

+ (nullable instancetype)splashPageWithBundleIdentifier:(OBPrivacyIdentifier)bundleIdentifier;
- (nullable instancetype)initWithPrivacyIdentifier:(OBPrivacyIdentifier)privacyIdentifier;
- (instancetype)initWithFlow:(OBPrivacyFlow *)flow;

@property (nonatomic, strong, nullable) OBPrivacyFlow *flow;
@property (strong, nullable) OBTemplateContainerViewController *containerViewController;
@property (nonatomic, strong, nullable) NSColor *customTintColor API_AVAILABLE(macos(26.0));
@property (copy, nullable) NSString *displayLanguage;
@property OBDeviceType displayDeviceType;
@property BOOL allowsOpeningSafari;
@property BOOL showsLinkToUnifiedAbout;
@property (nonatomic) BOOL showLinkToPrivacyGateway;
@property BOOL showPIIIcon;
@property BOOL forceLargeMargins;
@property BOOL useModalStyle;
@property BOOL suppressPerPageAnalyticsLogging;
@property (nonatomic) BOOL isCombined;

/// Does nothing on macOS 27.2. To learn when a page closes, use `OBPrivacyPresenter.dismissHandler`.
- (void)setDismissHandlerForDefaultButton:(nullable void (^)(void))dismissHandler;
- (void)addPrivacyFlowGroups:(NSArray<OBPrivacyFlowGroup *> *)privacyFlowGroups;
- (void)setHierarchicalSymbol:(NSString *)symbolName withAccesibilityDescription:(nullable NSString *)accessibilityDescription API_AVAILABLE(macos(26.4));
- (void)scrollToTop;
- (void)endSheet;
- (void)endSheetWithReturnCode:(NSModalResponse)returnCode;

@end

/// A window controller showing the combined "About Apple & Privacy" page for several privacy bundles. A class
/// cluster: creating the base class returns an `OBPrivacyCombinedController_macOS`.
@interface OBPrivacyCombinedController : NSWindowController <OBPrivacyPresenting>

/// Shows the combined page for every privacy bundle as a sheet on the window, through an `OBPrivacyPresenter`.
+ (void)presentPrivacyCombinedControllerOnWindow:(nullable NSWindow *)window dismissHandler:(nullable void (^)(void))dismissHandler;
+ (void)presentPrivacyCombinedControllerOnWindow:(nullable NSWindow *)window identifiers:(NSArray<OBPrivacyIdentifier> *)identifiers dismissHandler:(nullable void (^)(void))dismissHandler;

- (instancetype)initWithBundles:(NSArray<OBBundle *> *)bundles;

@property (nonatomic, strong, nullable) NSColor *customTintColor API_AVAILABLE(macos(26.0));
@property (copy, nullable) NSString *displayLanguage;
@property OBDeviceType displayDeviceType API_AVAILABLE(macos(26.0));
@property BOOL allowsOpeningSafari;
@property BOOL presentedFromPrivacyPane;

@end

/// The macOS implementation of `OBPrivacyCombinedController`.
@interface OBPrivacyCombinedController_macOS : OBPrivacyCombinedController

@property (strong, nullable) NSArray<OBBundle *> *bundles;
@property (strong, nullable) NSArray<OBPrivacyFlowGroup *> *privacyFlowGroups;

@end

/// Shows privacy pages as a sheet: one bundle's splash page, or the combined "About Apple & Privacy" page for several.
/// Create one with a `+presenterFor…` factory, set `presentingWindow`, and call `-present`.
NS_SWIFT_UI_ACTOR
@interface OBPrivacyPresenter : NSObject

+ (nullable instancetype)presenterForPrivacySplashWithIdentifier:(OBPrivacyIdentifier)identifier NS_SWIFT_NAME(init(splashFor:));
/// The misspelled original of `+presenterForPrivacySplashWithIdentifier:`, kept by the framework.
+ (nullable instancetype)presenterForPrivacySplashWithIdentifer:(OBPrivacyIdentifier)identifier NS_SWIFT_UNAVAILABLE("Use OBPrivacyPresenter(splashFor:)");
+ (nullable instancetype)presenterForPrivacySplashWithBundle:(OBBundle *)bundle NS_SWIFT_NAME(init(splashFor:));
+ (nullable instancetype)presenterForPrivacySplashWithBundleAtPath:(NSString *)path NS_SWIFT_NAME(init(splashForBundleAtPath:));
/// The combined page for every privacy bundle on the system.
+ (nullable instancetype)presenterForPrivacyUnifiedAbout NS_SWIFT_NAME(unifiedAbout());
+ (nullable instancetype)presenterForPrivacyUnifiedAboutWithIdentifiers:(NSArray<OBPrivacyIdentifier> *)identifiers NS_SWIFT_NAME(init(unifiedAboutFor:));
+ (nullable instancetype)presenterForPrivacyUnifiedAboutWithBundles:(NSArray<OBBundle *> *)bundles NS_SWIFT_NAME(init(unifiedAboutFor:));
+ (nullable instancetype)presenterForPrivacyUnifiedAboutWithBundlesAtPaths:(NSArray<NSString *> *)paths NS_SWIFT_NAME(init(unifiedAboutForBundlesAtPaths:));

/// The window the page is shown on, as a sheet. Required: with no window, `-present` logs a message and shows
/// nothing, and `dismissHandler` is never called.
@property (weak, nullable) NSWindow *presentingWindow;
/// Called after the sheet ends.
@property (copy, nullable) void (^dismissHandler)(void);
@property (nonatomic, copy, nullable) NSString *displayLanguage;
@property (nonatomic) OBDeviceType displayDeviceType API_AVAILABLE(macos(26.0));
@property (nonatomic, strong, nullable) NSColor *customTintColor API_AVAILABLE(macos(26.0));

@property (strong, nullable) OBPrivacySplashController *splashController;
@property (strong, nullable) OBPrivacyCombinedController *combinedController;
@property (strong, nullable) NSWindowController *presentedController;
@property (copy, nullable) NSArray<OBPrivacyIdentifier> *presentedIdentifiers;

- (void)present;

@end

NS_HEADER_AUDIT_END(nullability, sendability)

#endif
