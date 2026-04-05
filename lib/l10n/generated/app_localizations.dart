import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of S
/// returned by `S.of(context)`.
///
/// Applications need to include `S.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: S.localizationsDelegates,
///   supportedLocales: S.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the S.supportedLocales
/// property.
abstract class S {
  S(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static S of(BuildContext context) {
    return Localizations.of<S>(context, S)!;
  }

  static const LocalizationsDelegate<S> delegate = _SDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('tr'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In tr, this message translates to:
  /// **'OrientPro'**
  String get appTitle;

  /// No description provided for @systemActive.
  ///
  /// In tr, this message translates to:
  /// **'Sistem aktif'**
  String get systemActive;

  /// No description provided for @loginTitle.
  ///
  /// In tr, this message translates to:
  /// **'SISTEM GİRİŞİ'**
  String get loginTitle;

  /// No description provided for @loginButton.
  ///
  /// In tr, this message translates to:
  /// **'Giriş Yap'**
  String get loginButton;

  /// No description provided for @loginEmail.
  ///
  /// In tr, this message translates to:
  /// **'E-posta'**
  String get loginEmail;

  /// No description provided for @loginPassword.
  ///
  /// In tr, this message translates to:
  /// **'Şifre'**
  String get loginPassword;

  /// No description provided for @loginSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'SCADA & Tesis Yönetim Sistemi'**
  String get loginSubtitle;

  /// No description provided for @validationEmailRequired.
  ///
  /// In tr, this message translates to:
  /// **'E-posta adresi gerekli'**
  String get validationEmailRequired;

  /// No description provided for @validationEmailInvalid.
  ///
  /// In tr, this message translates to:
  /// **'Gecerli bir e-posta adresi girin'**
  String get validationEmailInvalid;

  /// No description provided for @validationPasswordRequired.
  ///
  /// In tr, this message translates to:
  /// **'Şifre gerekli'**
  String get validationPasswordRequired;

  /// No description provided for @validationPasswordTooShort.
  ///
  /// In tr, this message translates to:
  /// **'Şifre en az 4 karakter olmali'**
  String get validationPasswordTooShort;

  /// No description provided for @rememberMe.
  ///
  /// In tr, this message translates to:
  /// **'Beni hatirla'**
  String get rememberMe;

  /// No description provided for @orgSelectTitle.
  ///
  /// In tr, this message translates to:
  /// **'Tesis Secimi'**
  String get orgSelectTitle;

  /// No description provided for @orgSelectSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Birden fazla tesise uyesiniz.\nDevam etmek icin bir tesis secin.'**
  String get orgSelectSubtitle;

  /// No description provided for @orgSelectDefault.
  ///
  /// In tr, this message translates to:
  /// **'Varsayilan'**
  String get orgSelectDefault;

  /// No description provided for @orgSelectOtherAccount.
  ///
  /// In tr, this message translates to:
  /// **'Farkli Hesapla Giriş Yap'**
  String get orgSelectOtherAccount;

  /// No description provided for @orgSelectMember.
  ///
  /// In tr, this message translates to:
  /// **'Uye'**
  String get orgSelectMember;

  /// No description provided for @moduleSelectionTitle.
  ///
  /// In tr, this message translates to:
  /// **'Modul Secimi'**
  String get moduleSelectionTitle;

  /// No description provided for @moduleOrientation.
  ///
  /// In tr, this message translates to:
  /// **'Oryantasyon'**
  String get moduleOrientation;

  /// No description provided for @moduleOrientationSub.
  ///
  /// In tr, this message translates to:
  /// **'Eğitim & Rehber'**
  String get moduleOrientationSub;

  /// No description provided for @moduleOrientationDesc.
  ///
  /// In tr, this message translates to:
  /// **'Personel oryantasyon süreçleri,\neğitim rotalari ve takip'**
  String get moduleOrientationDesc;

  /// No description provided for @moduleAdmin.
  ///
  /// In tr, this message translates to:
  /// **'Yönetim'**
  String get moduleAdmin;

  /// No description provided for @moduleAdminSub.
  ///
  /// In tr, this message translates to:
  /// **'Admin Paneli'**
  String get moduleAdminSub;

  /// No description provided for @moduleContent.
  ///
  /// In tr, this message translates to:
  /// **'İçerik'**
  String get moduleContent;

  /// No description provided for @moduleContentSub.
  ///
  /// In tr, this message translates to:
  /// **'İçerik Yönetimi'**
  String get moduleContentSub;

  /// No description provided for @modulePro.
  ///
  /// In tr, this message translates to:
  /// **'Pro'**
  String get modulePro;

  /// No description provided for @moduleProSub.
  ///
  /// In tr, this message translates to:
  /// **'Teknik Yönetim'**
  String get moduleProSub;

  /// No description provided for @moduleProLocked.
  ///
  /// In tr, this message translates to:
  /// **'Plan Yukseltme Gerekli'**
  String get moduleProLocked;

  /// No description provided for @orientationTitle.
  ///
  /// In tr, this message translates to:
  /// **'Oryantasyon'**
  String get orientationTitle;

  /// No description provided for @orientationWelcome.
  ///
  /// In tr, this message translates to:
  /// **'Hoşgeldiniz, {name}'**
  String orientationWelcome(String name);

  /// No description provided for @orientationSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Oryantasyon ve eğitim modulune hoşgeldiniz'**
  String get orientationSubtitle;

  /// No description provided for @orientationOverallProgress.
  ///
  /// In tr, this message translates to:
  /// **'Genel Ilerleme'**
  String get orientationOverallProgress;

  /// No description provided for @orientationCompleted.
  ///
  /// In tr, this message translates to:
  /// **'Tamamlanan'**
  String get orientationCompleted;

  /// No description provided for @orientationOngoing.
  ///
  /// In tr, this message translates to:
  /// **'Devam Eden'**
  String get orientationOngoing;

  /// No description provided for @orientationQuizSuccess.
  ///
  /// In tr, this message translates to:
  /// **'Quiz Başarı'**
  String get orientationQuizSuccess;

  /// No description provided for @orientationPendingTasks.
  ///
  /// In tr, this message translates to:
  /// **'BEKLEYEN ISLEMLER'**
  String get orientationPendingTasks;

  /// No description provided for @orientationPendingApproval.
  ///
  /// In tr, this message translates to:
  /// **'{count} modul onay bekliyor'**
  String orientationPendingApproval(int count);

  /// No description provided for @orientationReviewRequired.
  ///
  /// In tr, this message translates to:
  /// **'{count} tekrar gerektiren konu'**
  String orientationReviewRequired(int count);

  /// No description provided for @orientationMandatoryIncomplete.
  ///
  /// In tr, this message translates to:
  /// **'TAMAMLANMAMIS ZORUNLU EĞİTİMLER'**
  String get orientationMandatoryIncomplete;

  /// No description provided for @orientationGeneralBadge.
  ///
  /// In tr, this message translates to:
  /// **'Genel Oryantasyon'**
  String get orientationGeneralBadge;

  /// No description provided for @orientationThisWeek.
  ///
  /// In tr, this message translates to:
  /// **'Bu Hafta'**
  String get orientationThisWeek;

  /// No description provided for @orientationDuration.
  ///
  /// In tr, this message translates to:
  /// **'Sure'**
  String get orientationDuration;

  /// No description provided for @orientationApproval.
  ///
  /// In tr, this message translates to:
  /// **'Onay'**
  String get orientationApproval;

  /// No description provided for @orientationAnnouncements.
  ///
  /// In tr, this message translates to:
  /// **'DUYURULAR'**
  String get orientationAnnouncements;

  /// No description provided for @orientationNewCount.
  ///
  /// In tr, this message translates to:
  /// **'{count} yeni'**
  String orientationNewCount(int count);

  /// No description provided for @orientationModules.
  ///
  /// In tr, this message translates to:
  /// **'MODULLER'**
  String get orientationModules;

  /// No description provided for @navTrainingRoutes.
  ///
  /// In tr, this message translates to:
  /// **'Eğitim Rotalari'**
  String get navTrainingRoutes;

  /// No description provided for @navTrainingRoutesSub.
  ///
  /// In tr, this message translates to:
  /// **'Departman bazli eğitim rotalari ve içerikler'**
  String get navTrainingRoutesSub;

  /// No description provided for @navQuizzes.
  ///
  /// In tr, this message translates to:
  /// **'Quiz & Sinavlar'**
  String get navQuizzes;

  /// No description provided for @navQuizzesSub.
  ///
  /// In tr, this message translates to:
  /// **'Bilgi testleri ve degerlendirmeler'**
  String get navQuizzesSub;

  /// No description provided for @navProgress.
  ///
  /// In tr, this message translates to:
  /// **'Ilerleme Takibi'**
  String get navProgress;

  /// No description provided for @navProgressSub.
  ///
  /// In tr, this message translates to:
  /// **'Eğitim tamamlama durumu ve raporlar'**
  String get navProgressSub;

  /// No description provided for @navAiAssistant.
  ///
  /// In tr, this message translates to:
  /// **'AI Asistan'**
  String get navAiAssistant;

  /// No description provided for @navAiAssistantSub.
  ///
  /// In tr, this message translates to:
  /// **'Oryantasyon süreçi icin yapay zeka destegi'**
  String get navAiAssistantSub;

  /// No description provided for @navAnnouncements.
  ///
  /// In tr, this message translates to:
  /// **'Duyuru Panosu'**
  String get navAnnouncements;

  /// No description provided for @navAnnouncementsSub.
  ///
  /// In tr, this message translates to:
  /// **'Sirket ve departman duyurulari'**
  String get navAnnouncementsSub;

  /// No description provided for @navLibrary.
  ///
  /// In tr, this message translates to:
  /// **'İçerik Kutuphanesi'**
  String get navLibrary;

  /// No description provided for @navLibrarySub.
  ///
  /// In tr, this message translates to:
  /// **'Kişisel ve paylaşılan belgeler'**
  String get navLibrarySub;

  /// No description provided for @navProfile.
  ///
  /// In tr, this message translates to:
  /// **'Profil Karti'**
  String get navProfile;

  /// No description provided for @navProfileSub.
  ///
  /// In tr, this message translates to:
  /// **'Kişisel bilgiler, acil durum, sertifikalar'**
  String get navProfileSub;

  /// No description provided for @navShifts.
  ///
  /// In tr, this message translates to:
  /// **'Vardiya & Görevler'**
  String get navShifts;

  /// No description provided for @navShiftsSub.
  ///
  /// In tr, this message translates to:
  /// **'Haftalik vardiya plani ve görev takibi'**
  String get navShiftsSub;

  /// No description provided for @viewAll.
  ///
  /// In tr, this message translates to:
  /// **'Tümünu Gor'**
  String get viewAll;

  /// No description provided for @libraryTitle.
  ///
  /// In tr, this message translates to:
  /// **'İçerik Kutuphanesi'**
  String get libraryTitle;

  /// No description provided for @libraryPersonalTab.
  ///
  /// In tr, this message translates to:
  /// **'Kişisel ({count})'**
  String libraryPersonalTab(int count);

  /// No description provided for @librarySharedTab.
  ///
  /// In tr, this message translates to:
  /// **'Paylaşılan ({count})'**
  String librarySharedTab(int count);

  /// No description provided for @librarySearch.
  ///
  /// In tr, this message translates to:
  /// **'Belge ara...'**
  String get librarySearch;

  /// No description provided for @libraryEmptyPersonal.
  ///
  /// In tr, this message translates to:
  /// **'Henuz kişisel belgeniz yok'**
  String get libraryEmptyPersonal;

  /// No description provided for @libraryEmptyCategory.
  ///
  /// In tr, this message translates to:
  /// **'Bu kategoride belge yok'**
  String get libraryEmptyCategory;

  /// No description provided for @libraryFilterAll.
  ///
  /// In tr, this message translates to:
  /// **'Tümü'**
  String get libraryFilterAll;

  /// No description provided for @libraryFilterSOP.
  ///
  /// In tr, this message translates to:
  /// **'SOP'**
  String get libraryFilterSOP;

  /// No description provided for @libraryFilterEmergency.
  ///
  /// In tr, this message translates to:
  /// **'Acil Durum'**
  String get libraryFilterEmergency;

  /// No description provided for @libraryFilterCert.
  ///
  /// In tr, this message translates to:
  /// **'Sertifika'**
  String get libraryFilterCert;

  /// No description provided for @libraryFilterOther.
  ///
  /// In tr, this message translates to:
  /// **'Diger'**
  String get libraryFilterOther;

  /// No description provided for @libraryDeleteTitle.
  ///
  /// In tr, this message translates to:
  /// **'Belge Sil'**
  String get libraryDeleteTitle;

  /// No description provided for @libraryDeleteConfirm.
  ///
  /// In tr, this message translates to:
  /// **'{title} silinsin mi?'**
  String libraryDeleteConfirm(String title);

  /// No description provided for @libraryDeleted.
  ///
  /// In tr, this message translates to:
  /// **'Belge silindi'**
  String get libraryDeleted;

  /// No description provided for @libraryUploadTitle.
  ///
  /// In tr, this message translates to:
  /// **'Dosya Yükle'**
  String get libraryUploadTitle;

  /// No description provided for @libraryDocTitle.
  ///
  /// In tr, this message translates to:
  /// **'Baslik'**
  String get libraryDocTitle;

  /// No description provided for @libraryDocTitleHint.
  ///
  /// In tr, this message translates to:
  /// **'Belge adi'**
  String get libraryDocTitleHint;

  /// No description provided for @libraryDocType.
  ///
  /// In tr, this message translates to:
  /// **'Belge Tipi'**
  String get libraryDocType;

  /// No description provided for @libraryDocTypeCert.
  ///
  /// In tr, this message translates to:
  /// **'Sertifika'**
  String get libraryDocTypeCert;

  /// No description provided for @libraryDocTypeHealth.
  ///
  /// In tr, this message translates to:
  /// **'Saglik Raporu'**
  String get libraryDocTypeHealth;

  /// No description provided for @libraryDocTypeId.
  ///
  /// In tr, this message translates to:
  /// **'Kimlik Fotokopisi'**
  String get libraryDocTypeId;

  /// No description provided for @libraryDocTypeEmergency.
  ///
  /// In tr, this message translates to:
  /// **'Acil Durum Plani'**
  String get libraryDocTypeEmergency;

  /// No description provided for @libraryDepartment.
  ///
  /// In tr, this message translates to:
  /// **'Departman'**
  String get libraryDepartment;

  /// No description provided for @libraryDepartmentError.
  ///
  /// In tr, this message translates to:
  /// **'Departmanlar yüklenemedi'**
  String get libraryDepartmentError;

  /// No description provided for @librarySelectFile.
  ///
  /// In tr, this message translates to:
  /// **'Dosya Sec'**
  String get librarySelectFile;

  /// No description provided for @libraryUploadValidation.
  ///
  /// In tr, this message translates to:
  /// **'Baslik ve dosya secimi zorunlu'**
  String get libraryUploadValidation;

  /// No description provided for @libraryUploaded.
  ///
  /// In tr, this message translates to:
  /// **'Dosya yüklendi'**
  String get libraryUploaded;

  /// No description provided for @libraryUploadFailed.
  ///
  /// In tr, this message translates to:
  /// **'Yükleme başarısız'**
  String get libraryUploadFailed;

  /// No description provided for @libraryUploadButton.
  ///
  /// In tr, this message translates to:
  /// **'Yükle'**
  String get libraryUploadButton;

  /// No description provided for @profileTitle.
  ///
  /// In tr, this message translates to:
  /// **'Profil Karti'**
  String get profileTitle;

  /// No description provided for @profilePhoneValidation.
  ///
  /// In tr, this message translates to:
  /// **'Gecerli bir telefon numarasi girin (05xx xxx xxxx)'**
  String get profilePhoneValidation;

  /// No description provided for @profileSectionContact.
  ///
  /// In tr, this message translates to:
  /// **'ILETISIM BILGILERI'**
  String get profileSectionContact;

  /// No description provided for @profileEmail.
  ///
  /// In tr, this message translates to:
  /// **'E-posta'**
  String get profileEmail;

  /// No description provided for @profilePhone.
  ///
  /// In tr, this message translates to:
  /// **'Telefon'**
  String get profilePhone;

  /// No description provided for @profileAddress.
  ///
  /// In tr, this message translates to:
  /// **'Adres'**
  String get profileAddress;

  /// No description provided for @profileSectionEmergency.
  ///
  /// In tr, this message translates to:
  /// **'ACIL DURUM KISI'**
  String get profileSectionEmergency;

  /// No description provided for @profileFullName.
  ///
  /// In tr, this message translates to:
  /// **'Ad Soyad'**
  String get profileFullName;

  /// No description provided for @profileRelation.
  ///
  /// In tr, this message translates to:
  /// **'Yakinlik'**
  String get profileRelation;

  /// No description provided for @profileSectionPersonal.
  ///
  /// In tr, this message translates to:
  /// **'KISISEL BILGILER'**
  String get profileSectionPersonal;

  /// No description provided for @profileBirthDate.
  ///
  /// In tr, this message translates to:
  /// **'Dogum Tarihi'**
  String get profileBirthDate;

  /// No description provided for @profileBloodType.
  ///
  /// In tr, this message translates to:
  /// **'Kan Grubu'**
  String get profileBloodType;

  /// No description provided for @profileTcId.
  ///
  /// In tr, this message translates to:
  /// **'TC Kimlik'**
  String get profileTcId;

  /// No description provided for @profileShift.
  ///
  /// In tr, this message translates to:
  /// **'Vardiya'**
  String get profileShift;

  /// No description provided for @profileStartDate.
  ///
  /// In tr, this message translates to:
  /// **'Ise Giriş'**
  String get profileStartDate;

  /// No description provided for @profileSectionSkills.
  ///
  /// In tr, this message translates to:
  /// **'YETENEKLER'**
  String get profileSectionSkills;

  /// No description provided for @profileSectionCerts.
  ///
  /// In tr, this message translates to:
  /// **'SERTIFIKALAR'**
  String get profileSectionCerts;

  /// No description provided for @profileSectionAbout.
  ///
  /// In tr, this message translates to:
  /// **'HAKKINDA'**
  String get profileSectionAbout;

  /// No description provided for @profileLoadError.
  ///
  /// In tr, this message translates to:
  /// **'Profil yüklenemedi'**
  String get profileLoadError;

  /// No description provided for @profileEditTitle.
  ///
  /// In tr, this message translates to:
  /// **'Profil Düzenle'**
  String get profileEditTitle;

  /// No description provided for @profileEditPhone.
  ///
  /// In tr, this message translates to:
  /// **'Telefon (05xx xxx xxxx)'**
  String get profileEditPhone;

  /// No description provided for @profileEditBloodType.
  ///
  /// In tr, this message translates to:
  /// **'Kan Grubu'**
  String get profileEditBloodType;

  /// No description provided for @profileEditEmergencyName.
  ///
  /// In tr, this message translates to:
  /// **'Acil Durum Kisi Adi'**
  String get profileEditEmergencyName;

  /// No description provided for @profileEditEmergencyPhone.
  ///
  /// In tr, this message translates to:
  /// **'Acil Durum Telefon (05xx xxx xxxx)'**
  String get profileEditEmergencyPhone;

  /// No description provided for @profileEditRelation.
  ///
  /// In tr, this message translates to:
  /// **'Yakinlik Derecesi'**
  String get profileEditRelation;

  /// No description provided for @profileRelationSpouse.
  ///
  /// In tr, this message translates to:
  /// **'Es'**
  String get profileRelationSpouse;

  /// No description provided for @profileRelationMother.
  ///
  /// In tr, this message translates to:
  /// **'Anne'**
  String get profileRelationMother;

  /// No description provided for @profileRelationFather.
  ///
  /// In tr, this message translates to:
  /// **'Baba'**
  String get profileRelationFather;

  /// No description provided for @profileRelationSibling.
  ///
  /// In tr, this message translates to:
  /// **'Kardes'**
  String get profileRelationSibling;

  /// No description provided for @profileRelationOther.
  ///
  /// In tr, this message translates to:
  /// **'Diger'**
  String get profileRelationOther;

  /// No description provided for @profileEditAbout.
  ///
  /// In tr, this message translates to:
  /// **'Hakkinda'**
  String get profileEditAbout;

  /// No description provided for @profilePhoneInvalid.
  ///
  /// In tr, this message translates to:
  /// **'Lütfen gecerli telefon numaralari girin'**
  String get profilePhoneInvalid;

  /// No description provided for @profileUpdated.
  ///
  /// In tr, this message translates to:
  /// **'Profil güncellendi'**
  String get profileUpdated;

  /// No description provided for @profileUpdateFailed.
  ///
  /// In tr, this message translates to:
  /// **'Güncelleme başarısız'**
  String get profileUpdateFailed;

  /// No description provided for @announcementTitle.
  ///
  /// In tr, this message translates to:
  /// **'Duyuru Panosu'**
  String get announcementTitle;

  /// No description provided for @announcementEmpty.
  ///
  /// In tr, this message translates to:
  /// **'Henuz duyuru yok'**
  String get announcementEmpty;

  /// No description provided for @announcementSearch.
  ///
  /// In tr, this message translates to:
  /// **'Duyuru ara...'**
  String get announcementSearch;

  /// No description provided for @announcementNoResult.
  ///
  /// In tr, this message translates to:
  /// **'Sonuç bulunamadi'**
  String get announcementNoResult;

  /// No description provided for @announcementDeleteTitle.
  ///
  /// In tr, this message translates to:
  /// **'Duyuru Sil'**
  String get announcementDeleteTitle;

  /// No description provided for @announcementDeleteConfirm.
  ///
  /// In tr, this message translates to:
  /// **'\"{title}\" silinsin mi?'**
  String announcementDeleteConfirm(String title);

  /// No description provided for @announcementReadCount.
  ///
  /// In tr, this message translates to:
  /// **'{count} kisi okudu'**
  String announcementReadCount(int count);

  /// No description provided for @announcementMarkRead.
  ///
  /// In tr, this message translates to:
  /// **'Okudum'**
  String get announcementMarkRead;

  /// No description provided for @announcementRead.
  ///
  /// In tr, this message translates to:
  /// **'Okundu'**
  String get announcementRead;

  /// No description provided for @announcementMarkedRead.
  ///
  /// In tr, this message translates to:
  /// **'Duyuru okundu olarak isaretlendi'**
  String get announcementMarkedRead;

  /// No description provided for @announcementDeleted.
  ///
  /// In tr, this message translates to:
  /// **'Duyuru silindi'**
  String get announcementDeleted;

  /// No description provided for @announcementDeleteFailed.
  ///
  /// In tr, this message translates to:
  /// **'Silme başarısız'**
  String get announcementDeleteFailed;

  /// No description provided for @announcementNew.
  ///
  /// In tr, this message translates to:
  /// **'Yeni Duyuru'**
  String get announcementNew;

  /// No description provided for @announcementEditTitle.
  ///
  /// In tr, this message translates to:
  /// **'Duyuru Düzenle'**
  String get announcementEditTitle;

  /// No description provided for @announcementFieldTitle.
  ///
  /// In tr, this message translates to:
  /// **'Baslik'**
  String get announcementFieldTitle;

  /// No description provided for @announcementFieldContent.
  ///
  /// In tr, this message translates to:
  /// **'İçerik'**
  String get announcementFieldContent;

  /// No description provided for @announcementFieldPriority.
  ///
  /// In tr, this message translates to:
  /// **'Oncelik'**
  String get announcementFieldPriority;

  /// No description provided for @announcementPriorityNormal.
  ///
  /// In tr, this message translates to:
  /// **'Normal'**
  String get announcementPriorityNormal;

  /// No description provided for @announcementPriorityHigh.
  ///
  /// In tr, this message translates to:
  /// **'Yuksek'**
  String get announcementPriorityHigh;

  /// No description provided for @announcementPriorityCritical.
  ///
  /// In tr, this message translates to:
  /// **'Kritik'**
  String get announcementPriorityCritical;

  /// No description provided for @announcementTargetDept.
  ///
  /// In tr, this message translates to:
  /// **'Hedef Departman'**
  String get announcementTargetDept;

  /// No description provided for @announcementAllCompany.
  ///
  /// In tr, this message translates to:
  /// **'Tum Sirket'**
  String get announcementAllCompany;

  /// No description provided for @announcementPin.
  ///
  /// In tr, this message translates to:
  /// **'Sabitle'**
  String get announcementPin;

  /// No description provided for @announcementValidation.
  ///
  /// In tr, this message translates to:
  /// **'Baslik ve içerik zorunlu'**
  String get announcementValidation;

  /// No description provided for @announcementUpdated.
  ///
  /// In tr, this message translates to:
  /// **'Duyuru güncellendi'**
  String get announcementUpdated;

  /// No description provided for @announcementCreated.
  ///
  /// In tr, this message translates to:
  /// **'Duyuru oluşturuldu'**
  String get announcementCreated;

  /// No description provided for @announcementUpdateFailed.
  ///
  /// In tr, this message translates to:
  /// **'Güncelleme başarısız'**
  String get announcementUpdateFailed;

  /// No description provided for @announcementCreateFailed.
  ///
  /// In tr, this message translates to:
  /// **'Duyuru oluşturulamadı'**
  String get announcementCreateFailed;

  /// No description provided for @announcementEdit.
  ///
  /// In tr, this message translates to:
  /// **'Düzenle'**
  String get announcementEdit;

  /// No description provided for @announcementPublish.
  ///
  /// In tr, this message translates to:
  /// **'Yayinla'**
  String get announcementPublish;

  /// No description provided for @tourTitle.
  ///
  /// In tr, this message translates to:
  /// **'Tur'**
  String get tourTitle;

  /// No description provided for @tourLoading.
  ///
  /// In tr, this message translates to:
  /// **'Yükleniyor...'**
  String get tourLoading;

  /// No description provided for @tourRetry.
  ///
  /// In tr, this message translates to:
  /// **'Tekrar Dene'**
  String get tourRetry;

  /// No description provided for @tourCheckpoints.
  ///
  /// In tr, this message translates to:
  /// **'{scanned}/{total} nokta'**
  String tourCheckpoints(int scanned, int total);

  /// No description provided for @tourSkipped.
  ///
  /// In tr, this message translates to:
  /// **'{count} atlandi'**
  String tourSkipped(int count);

  /// No description provided for @tourScanQR.
  ///
  /// In tr, this message translates to:
  /// **'QR Tara'**
  String get tourScanQR;

  /// No description provided for @tourScanning.
  ///
  /// In tr, this message translates to:
  /// **'Taraniyor...'**
  String get tourScanning;

  /// No description provided for @tourScanHeader.
  ///
  /// In tr, this message translates to:
  /// **'QR Kodu Okutun'**
  String get tourScanHeader;

  /// No description provided for @tourScanError.
  ///
  /// In tr, this message translates to:
  /// **'Tarama hatasi: {error}'**
  String tourScanError(String error);

  /// No description provided for @tourRemaining.
  ///
  /// In tr, this message translates to:
  /// **'{count} kaldi'**
  String tourRemaining(int count);

  /// No description provided for @tourSkipTitle.
  ///
  /// In tr, this message translates to:
  /// **'{name} atla'**
  String tourSkipTitle(String name);

  /// No description provided for @tourSkipReason.
  ///
  /// In tr, this message translates to:
  /// **'Atlama sebebi (zorunlu)'**
  String get tourSkipReason;

  /// No description provided for @tourCompleted.
  ///
  /// In tr, this message translates to:
  /// **'Tur Tamamlandi!'**
  String get tourCompleted;

  /// No description provided for @tourCompletedAll.
  ///
  /// In tr, this message translates to:
  /// **'Tum kontrol noktalari tarandi.'**
  String get tourCompletedAll;

  /// No description provided for @tourCompleteSummary.
  ///
  /// In tr, this message translates to:
  /// **'Taranan: {scanned}/{total}\nAtlanan: {skipped}\nTamamlanma: %{rate}'**
  String tourCompleteSummary(
    String scanned,
    String total,
    String skipped,
    String rate,
  );

  /// No description provided for @tourComplete.
  ///
  /// In tr, this message translates to:
  /// **'Tamamla'**
  String get tourComplete;

  /// No description provided for @tourCancelTitle.
  ///
  /// In tr, this message translates to:
  /// **'Turu iptal et?'**
  String get tourCancelTitle;

  /// No description provided for @tourCancelWarning.
  ///
  /// In tr, this message translates to:
  /// **'Bu işlem geri alinamaz.'**
  String get tourCancelWarning;

  /// No description provided for @notificationTitle.
  ///
  /// In tr, this message translates to:
  /// **'Bildirimler'**
  String get notificationTitle;

  /// No description provided for @notificationMarkAllRead.
  ///
  /// In tr, this message translates to:
  /// **'Tümü Okundu'**
  String get notificationMarkAllRead;

  /// No description provided for @notificationEmpty.
  ///
  /// In tr, this message translates to:
  /// **'Bildirim yok'**
  String get notificationEmpty;

  /// No description provided for @notificationTime.
  ///
  /// In tr, this message translates to:
  /// **'Zaman'**
  String get notificationTime;

  /// No description provided for @notificationSource.
  ///
  /// In tr, this message translates to:
  /// **'Kaynak'**
  String get notificationSource;

  /// No description provided for @notificationCategory.
  ///
  /// In tr, this message translates to:
  /// **'Kategori'**
  String get notificationCategory;

  /// No description provided for @notificationPriority.
  ///
  /// In tr, this message translates to:
  /// **'Oncelik'**
  String get notificationPriority;

  /// No description provided for @quizTitle.
  ///
  /// In tr, this message translates to:
  /// **'Quiz'**
  String get quizTitle;

  /// No description provided for @quizNoQuestions.
  ///
  /// In tr, this message translates to:
  /// **'Soru bulunamadi'**
  String get quizNoQuestions;

  /// No description provided for @quizSubmit.
  ///
  /// In tr, this message translates to:
  /// **'Quizi Tamamla'**
  String get quizSubmit;

  /// No description provided for @quizIncomplete.
  ///
  /// In tr, this message translates to:
  /// **'Tum sorulari yanitlayin'**
  String get quizIncomplete;

  /// No description provided for @quizEditTitle.
  ///
  /// In tr, this message translates to:
  /// **'Soru Düzenle'**
  String get quizEditTitle;

  /// No description provided for @quizNewTitle.
  ///
  /// In tr, this message translates to:
  /// **'Yeni Soru Ekle'**
  String get quizNewTitle;

  /// No description provided for @quizQuestionText.
  ///
  /// In tr, this message translates to:
  /// **'Soru Metni'**
  String get quizQuestionText;

  /// No description provided for @quizLoadError.
  ///
  /// In tr, this message translates to:
  /// **'Quiz yüklenemedi: {error}'**
  String quizLoadError(String error);

  /// No description provided for @quizUpdated.
  ///
  /// In tr, this message translates to:
  /// **'Quiz güncellendi'**
  String get quizUpdated;

  /// No description provided for @quizCreated.
  ///
  /// In tr, this message translates to:
  /// **'Quiz oluşturuldu'**
  String get quizCreated;

  /// No description provided for @progressTitle.
  ///
  /// In tr, this message translates to:
  /// **'Ilerleme Takibi'**
  String get progressTitle;

  /// No description provided for @progressMyTab.
  ///
  /// In tr, this message translates to:
  /// **'Benim Ilerlemem'**
  String get progressMyTab;

  /// No description provided for @progressTeamTab.
  ///
  /// In tr, this message translates to:
  /// **'Ekip Takibi'**
  String get progressTeamTab;

  /// No description provided for @contentManagerTitle.
  ///
  /// In tr, this message translates to:
  /// **'İçerik Yönetimi'**
  String get contentManagerTitle;

  /// No description provided for @contentManagerSearch.
  ///
  /// In tr, this message translates to:
  /// **'Semantik Arama'**
  String get contentManagerSearch;

  /// No description provided for @contentManagerTreeBack.
  ///
  /// In tr, this message translates to:
  /// **'Agaca don'**
  String get contentManagerTreeBack;

  /// No description provided for @contentManagerTree.
  ///
  /// In tr, this message translates to:
  /// **'İçerik Agaci'**
  String get contentManagerTree;

  /// No description provided for @routeEditorEdit.
  ///
  /// In tr, this message translates to:
  /// **'Rotayi Düzenle'**
  String get routeEditorEdit;

  /// No description provided for @routeEditorNew.
  ///
  /// In tr, this message translates to:
  /// **'Yeni Eğitim Rotasi'**
  String get routeEditorNew;

  /// No description provided for @routeEditorSelectDept.
  ///
  /// In tr, this message translates to:
  /// **'Lütfen departman secin'**
  String get routeEditorSelectDept;

  /// No description provided for @routeEditorUpdated.
  ///
  /// In tr, this message translates to:
  /// **'Rota başarıyla güncellendi'**
  String get routeEditorUpdated;

  /// No description provided for @routeEditorCreated.
  ///
  /// In tr, this message translates to:
  /// **'Rota başarıyla oluşturuldu'**
  String get routeEditorCreated;

  /// No description provided for @routeEditorDeleteModule.
  ///
  /// In tr, this message translates to:
  /// **'Modulu Sil'**
  String get routeEditorDeleteModule;

  /// No description provided for @routeEditorDeleteConfirm.
  ///
  /// In tr, this message translates to:
  /// **'\"{title}\" modulunu silmek istediginize emin misiniz?'**
  String routeEditorDeleteConfirm(String title);

  /// No description provided for @ackTitle.
  ///
  /// In tr, this message translates to:
  /// **'Eğitim Onayi'**
  String get ackTitle;

  /// No description provided for @ackText.
  ///
  /// In tr, this message translates to:
  /// **'Onay Metni'**
  String get ackText;

  /// No description provided for @ackStatement.
  ///
  /// In tr, this message translates to:
  /// **'Bu eğitimi okudum, anladim ve uygulamayi taahhut ediyorum.'**
  String get ackStatement;

  /// No description provided for @ackCheckbox.
  ///
  /// In tr, this message translates to:
  /// **'Yukaridaki metni okudum ve kabul ediyorum'**
  String get ackCheckbox;

  /// No description provided for @ackConfirm.
  ///
  /// In tr, this message translates to:
  /// **'Onayla'**
  String get ackConfirm;

  /// No description provided for @ackFailed.
  ///
  /// In tr, this message translates to:
  /// **'Onay gonderilemedi'**
  String get ackFailed;

  /// No description provided for @scadaThresholds.
  ///
  /// In tr, this message translates to:
  /// **'Esik Degerleri'**
  String get scadaThresholds;

  /// No description provided for @scadaNoThreshold.
  ///
  /// In tr, this message translates to:
  /// **'Esik tanimlanmamis'**
  String get scadaNoThreshold;

  /// No description provided for @scadaAllNormal.
  ///
  /// In tr, this message translates to:
  /// **'Tum sistemler normal calisiyor'**
  String get scadaAllNormal;

  /// No description provided for @scadaAlarmAcked.
  ///
  /// In tr, this message translates to:
  /// **'Alarm onaylandi'**
  String get scadaAlarmAcked;

  /// No description provided for @scadaSensor.
  ///
  /// In tr, this message translates to:
  /// **'Sensor #{id}'**
  String scadaSensor(int id);

  /// No description provided for @scadaNoData.
  ///
  /// In tr, this message translates to:
  /// **'Henuz veri yok'**
  String get scadaNoData;

  /// No description provided for @scadaLoadError.
  ///
  /// In tr, this message translates to:
  /// **'Veri yüklenemedi: {error}'**
  String scadaLoadError(String error);

  /// No description provided for @commonCancel.
  ///
  /// In tr, this message translates to:
  /// **'İptal'**
  String get commonCancel;

  /// No description provided for @commonDelete.
  ///
  /// In tr, this message translates to:
  /// **'Sil'**
  String get commonDelete;

  /// No description provided for @commonSave.
  ///
  /// In tr, this message translates to:
  /// **'Kaydet'**
  String get commonSave;

  /// No description provided for @commonClose.
  ///
  /// In tr, this message translates to:
  /// **'Kapat'**
  String get commonClose;

  /// No description provided for @commonOk.
  ///
  /// In tr, this message translates to:
  /// **'Tamam'**
  String get commonOk;

  /// No description provided for @commonRetry.
  ///
  /// In tr, this message translates to:
  /// **'Tekrar Dene'**
  String get commonRetry;

  /// No description provided for @commonBack.
  ///
  /// In tr, this message translates to:
  /// **'Vazgec'**
  String get commonBack;

  /// No description provided for @commonError.
  ///
  /// In tr, this message translates to:
  /// **'Hata: {error}'**
  String commonError(String error);

  /// No description provided for @featureGateUpgradeRequired.
  ///
  /// In tr, this message translates to:
  /// **'Plan Yukseltme Gerekli'**
  String get featureGateUpgradeRequired;

  /// No description provided for @featureGateUpgradeMessage.
  ///
  /// In tr, this message translates to:
  /// **'Bu ozellige erismek icin planin yukseltilmesi gerekiyor.'**
  String get featureGateUpgradeMessage;

  /// No description provided for @featureGateContactAdmin.
  ///
  /// In tr, this message translates to:
  /// **'Yukseltme icin tesis yöneticinize basvurun'**
  String get featureGateContactAdmin;

  /// No description provided for @featureGateCurrentPlan.
  ///
  /// In tr, this message translates to:
  /// **'Mevcut Plan: {plan}'**
  String featureGateCurrentPlan(String plan);

  /// No description provided for @accessDeniedTitle.
  ///
  /// In tr, this message translates to:
  /// **'Erişim Yetkiniz Yok'**
  String get accessDeniedTitle;

  /// No description provided for @accessDeniedMessage.
  ///
  /// In tr, this message translates to:
  /// **'Bu sayfaya erişim icin yetkiniz bulunmamaktadir.'**
  String get accessDeniedMessage;

  /// No description provided for @accessDeniedHome.
  ///
  /// In tr, this message translates to:
  /// **'Ana Sayfaya Don'**
  String get accessDeniedHome;

  /// No description provided for @pageNotFound.
  ///
  /// In tr, this message translates to:
  /// **'Sayfa bulunamadi: {uri}'**
  String pageNotFound(String uri);

  /// No description provided for @certificateTitle.
  ///
  /// In tr, this message translates to:
  /// **'Tamamlama Sertifikasi'**
  String get certificateTitle;

  /// No description provided for @certificateHeader.
  ///
  /// In tr, this message translates to:
  /// **'TAMAMLAMA SERTIFIKASI'**
  String get certificateHeader;

  /// No description provided for @certificateConfirms.
  ///
  /// In tr, this message translates to:
  /// **'Bu belge ile onaylanir ki'**
  String get certificateConfirms;

  /// No description provided for @certificateCompleted.
  ///
  /// In tr, this message translates to:
  /// **'asagidaki eğitim rotasini başarıyla tamamlamistir'**
  String get certificateCompleted;

  /// No description provided for @certificateDate.
  ///
  /// In tr, this message translates to:
  /// **'Tarih'**
  String get certificateDate;

  /// No description provided for @certificateId.
  ///
  /// In tr, this message translates to:
  /// **'Sertifika No'**
  String get certificateId;

  /// No description provided for @certificateDownload.
  ///
  /// In tr, this message translates to:
  /// **'PDF Indir'**
  String get certificateDownload;

  /// No description provided for @certificateDownloadError.
  ///
  /// In tr, this message translates to:
  /// **'PDF indirilemedi'**
  String get certificateDownloadError;

  /// No description provided for @badgesTitle.
  ///
  /// In tr, this message translates to:
  /// **'Rozetler'**
  String get badgesTitle;

  /// No description provided for @badgesEarned.
  ///
  /// In tr, this message translates to:
  /// **'Rozet kazanildi'**
  String get badgesEarned;

  /// No description provided for @badgesAll.
  ///
  /// In tr, this message translates to:
  /// **'TUM ROZETLER'**
  String get badgesAll;

  /// No description provided for @badgeEarned.
  ///
  /// In tr, this message translates to:
  /// **'Kazanildi'**
  String get badgeEarned;

  /// No description provided for @badgeFirstStep.
  ///
  /// In tr, this message translates to:
  /// **'Ilk Adim'**
  String get badgeFirstStep;

  /// No description provided for @badgeFirstStepDesc.
  ///
  /// In tr, this message translates to:
  /// **'Ilk eğitim modulunu tamamla'**
  String get badgeFirstStepDesc;

  /// No description provided for @badgeQuizMaster.
  ///
  /// In tr, this message translates to:
  /// **'Quiz Ustasi'**
  String get badgeQuizMaster;

  /// No description provided for @badgeQuizMasterDesc.
  ///
  /// In tr, this message translates to:
  /// **'5 quizi başarıyla gec'**
  String get badgeQuizMasterDesc;

  /// No description provided for @badgeFastLearner.
  ///
  /// In tr, this message translates to:
  /// **'Hizli Öğrenci'**
  String get badgeFastLearner;

  /// No description provided for @badgeFastLearnerDesc.
  ///
  /// In tr, this message translates to:
  /// **'Bir modulu 10 dakikadan kisa surede tamamla'**
  String get badgeFastLearnerDesc;

  /// No description provided for @badgePerfectScore.
  ///
  /// In tr, this message translates to:
  /// **'Tam Puan'**
  String get badgePerfectScore;

  /// No description provided for @badgePerfectScoreDesc.
  ///
  /// In tr, this message translates to:
  /// **'Bir quizden %100 al'**
  String get badgePerfectScoreDesc;

  /// No description provided for @badgeTeamPlayer.
  ///
  /// In tr, this message translates to:
  /// **'Takim Oyuncusu'**
  String get badgeTeamPlayer;

  /// No description provided for @badgeTeamPlayerDesc.
  ///
  /// In tr, this message translates to:
  /// **'Bir rotadaki tum modulleri tamamla'**
  String get badgeTeamPlayerDesc;

  /// No description provided for @badgeBookworm.
  ///
  /// In tr, this message translates to:
  /// **'Bilgi Kurdu'**
  String get badgeBookworm;

  /// No description provided for @badgeBookwormDesc.
  ///
  /// In tr, this message translates to:
  /// **'10 kutuphane dokümanini oku'**
  String get badgeBookwormDesc;

  /// No description provided for @leaderboardTitle.
  ///
  /// In tr, this message translates to:
  /// **'Siralama'**
  String get leaderboardTitle;

  /// No description provided for @leaderboardSection.
  ///
  /// In tr, this message translates to:
  /// **'DEPARTMAN SIRALAMASI'**
  String get leaderboardSection;

  /// No description provided for @leaderboardEmpty.
  ///
  /// In tr, this message translates to:
  /// **'Siralama verisi bulunamadi'**
  String get leaderboardEmpty;

  /// No description provided for @leaderboardYou.
  ///
  /// In tr, this message translates to:
  /// **'Sen'**
  String get leaderboardYou;

  /// No description provided for @approvalTitle.
  ///
  /// In tr, this message translates to:
  /// **'İçerik Onaylari'**
  String get approvalTitle;

  /// No description provided for @approvalEmpty.
  ///
  /// In tr, this message translates to:
  /// **'Onay bekleyen içerik yok'**
  String get approvalEmpty;

  /// No description provided for @approvalApprove.
  ///
  /// In tr, this message translates to:
  /// **'Onayla'**
  String get approvalApprove;

  /// No description provided for @approvalReject.
  ///
  /// In tr, this message translates to:
  /// **'Reddet'**
  String get approvalReject;

  /// No description provided for @approvalRejectTitle.
  ///
  /// In tr, this message translates to:
  /// **'Icerigi Reddet'**
  String get approvalRejectTitle;

  /// No description provided for @approvalRejectReason.
  ///
  /// In tr, this message translates to:
  /// **'Red sebebi (opsiyonel)'**
  String get approvalRejectReason;

  /// No description provided for @approvalApproved.
  ///
  /// In tr, this message translates to:
  /// **'İçerik onaylandi'**
  String get approvalApproved;

  /// No description provided for @approvalRejected.
  ///
  /// In tr, this message translates to:
  /// **'İçerik reddedildi'**
  String get approvalRejected;

  /// No description provided for @themeToggle.
  ///
  /// In tr, this message translates to:
  /// **'Tema Değiştir'**
  String get themeToggle;

  /// No description provided for @themeDark.
  ///
  /// In tr, this message translates to:
  /// **'Karanlik Tema'**
  String get themeDark;

  /// No description provided for @themeLight.
  ///
  /// In tr, this message translates to:
  /// **'Aydinlik Tema'**
  String get themeLight;

  /// No description provided for @progressReportDownload.
  ///
  /// In tr, this message translates to:
  /// **'Rapor Indir'**
  String get progressReportDownload;

  /// No description provided for @progressReportError.
  ///
  /// In tr, this message translates to:
  /// **'Rapor indirilemedi'**
  String get progressReportError;

  /// No description provided for @dashboardTitle.
  ///
  /// In tr, this message translates to:
  /// **'Kontrol Paneli'**
  String get dashboardTitle;

  /// No description provided for @dashboardWelcome.
  ///
  /// In tr, this message translates to:
  /// **'Hoşgeldin, {name}'**
  String dashboardWelcome(String name);

  /// No description provided for @commonLoading.
  ///
  /// In tr, this message translates to:
  /// **'Yükleniyor...'**
  String get commonLoading;

  /// No description provided for @commonNoData.
  ///
  /// In tr, this message translates to:
  /// **'Veri bulunamadi'**
  String get commonNoData;

  /// No description provided for @commonSearch.
  ///
  /// In tr, this message translates to:
  /// **'Ara...'**
  String get commonSearch;

  /// No description provided for @commonFilter.
  ///
  /// In tr, this message translates to:
  /// **'Filtrele'**
  String get commonFilter;

  /// No description provided for @commonSort.
  ///
  /// In tr, this message translates to:
  /// **'Sirala'**
  String get commonSort;

  /// No description provided for @commonRefresh.
  ///
  /// In tr, this message translates to:
  /// **'Yenile'**
  String get commonRefresh;

  /// No description provided for @commonSettings.
  ///
  /// In tr, this message translates to:
  /// **'Ayarlar'**
  String get commonSettings;

  /// No description provided for @commonLogout.
  ///
  /// In tr, this message translates to:
  /// **'Çıkış Yap'**
  String get commonLogout;

  /// No description provided for @commonYes.
  ///
  /// In tr, this message translates to:
  /// **'Evet'**
  String get commonYes;

  /// No description provided for @commonNo.
  ///
  /// In tr, this message translates to:
  /// **'Hayir'**
  String get commonNo;

  /// No description provided for @commonConfirm.
  ///
  /// In tr, this message translates to:
  /// **'Onayla'**
  String get commonConfirm;

  /// No description provided for @commonSuccess.
  ///
  /// In tr, this message translates to:
  /// **'Başarılı'**
  String get commonSuccess;

  /// No description provided for @commonFailed.
  ///
  /// In tr, this message translates to:
  /// **'Başarısız'**
  String get commonFailed;
}

class _SDelegate extends LocalizationsDelegate<S> {
  const _SDelegate();

  @override
  Future<S> load(Locale locale) {
    return SynchronousFuture<S>(lookupS(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_SDelegate old) => false;
}

S lookupS(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return SEn();
    case 'tr':
      return STr();
  }

  throw FlutterError(
    'S.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
