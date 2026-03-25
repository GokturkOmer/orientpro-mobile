// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class STr extends S {
  STr([String locale = 'tr']) : super(locale);

  @override
  String get appTitle => 'OrientPro';

  @override
  String get systemActive => 'Sistem aktif';

  @override
  String get loginTitle => 'SISTEM GIRISI';

  @override
  String get loginButton => 'Giris Yap';

  @override
  String get loginEmail => 'E-posta';

  @override
  String get loginPassword => 'Sifre';

  @override
  String get loginSubtitle => 'SCADA & Tesis Yonetim Sistemi';

  @override
  String get validationEmailRequired => 'E-posta adresi gerekli';

  @override
  String get validationEmailInvalid => 'Gecerli bir e-posta adresi girin';

  @override
  String get validationPasswordRequired => 'Sifre gerekli';

  @override
  String get validationPasswordTooShort => 'Sifre en az 4 karakter olmali';

  @override
  String get rememberMe => 'Beni hatirla';

  @override
  String get orgSelectTitle => 'Tesis Secimi';

  @override
  String get orgSelectSubtitle =>
      'Birden fazla tesise uyesiniz.\nDevam etmek icin bir tesis secin.';

  @override
  String get orgSelectDefault => 'Varsayilan';

  @override
  String get orgSelectOtherAccount => 'Farkli Hesapla Giris Yap';

  @override
  String get orgSelectMember => 'Uye';

  @override
  String get moduleSelectionTitle => 'Modul Secimi';

  @override
  String get moduleOrientation => 'Oryantasyon';

  @override
  String get moduleOrientationSub => 'Egitim & Rehber';

  @override
  String get moduleOrientationDesc =>
      'Personel oryantasyon surecleri,\negitim rotalari ve takip';

  @override
  String get moduleAdmin => 'Yonetim';

  @override
  String get moduleAdminSub => 'Admin Paneli';

  @override
  String get moduleContent => 'Icerik';

  @override
  String get moduleContentSub => 'Icerik Yonetimi';

  @override
  String get modulePro => 'Pro';

  @override
  String get moduleProSub => 'Teknik Yonetim';

  @override
  String get moduleProLocked => 'Plan Yukseltme Gerekli';

  @override
  String get orientationTitle => 'Oryantasyon';

  @override
  String orientationWelcome(String name) {
    return 'Hosgeldiniz, $name';
  }

  @override
  String get orientationSubtitle =>
      'Oryantasyon ve egitim modulune hosgeldiniz';

  @override
  String get orientationOverallProgress => 'Genel Ilerleme';

  @override
  String get orientationCompleted => 'Tamamlanan';

  @override
  String get orientationOngoing => 'Devam Eden';

  @override
  String get orientationQuizSuccess => 'Quiz Basari';

  @override
  String get orientationPendingTasks => 'BEKLEYEN ISLEMLER';

  @override
  String orientationPendingApproval(int count) {
    return '$count modul onay bekliyor';
  }

  @override
  String orientationReviewRequired(int count) {
    return '$count tekrar gerektiren konu';
  }

  @override
  String get orientationMandatoryIncomplete =>
      'TAMAMLANMAMIS ZORUNLU EGITIMLER';

  @override
  String get orientationGeneralBadge => 'Genel Oryantasyon';

  @override
  String get orientationThisWeek => 'Bu Hafta';

  @override
  String get orientationDuration => 'Sure';

  @override
  String get orientationApproval => 'Onay';

  @override
  String get orientationAnnouncements => 'DUYURULAR';

  @override
  String orientationNewCount(int count) {
    return '$count yeni';
  }

  @override
  String get orientationModules => 'MODULLER';

  @override
  String get navTrainingRoutes => 'Egitim Rotalari';

  @override
  String get navTrainingRoutesSub =>
      'Departman bazli egitim rotalari ve icerikler';

  @override
  String get navQuizzes => 'Quiz & Sinavlar';

  @override
  String get navQuizzesSub => 'Bilgi testleri ve degerlendirmeler';

  @override
  String get navProgress => 'Ilerleme Takibi';

  @override
  String get navProgressSub => 'Egitim tamamlama durumu ve raporlar';

  @override
  String get navAiAssistant => 'AI Asistan';

  @override
  String get navAiAssistantSub => 'Oryantasyon sureci icin yapay zeka destegi';

  @override
  String get navAnnouncements => 'Duyuru Panosu';

  @override
  String get navAnnouncementsSub => 'Sirket ve departman duyurulari';

  @override
  String get navLibrary => 'Icerik Kutuphanesi';

  @override
  String get navLibrarySub => 'Kisisel ve paylasilan belgeler';

  @override
  String get navProfile => 'Profil Karti';

  @override
  String get navProfileSub => 'Kisisel bilgiler, acil durum, sertifikalar';

  @override
  String get navShifts => 'Vardiya & Gorevler';

  @override
  String get navShiftsSub => 'Haftalik vardiya plani ve gorev takibi';

  @override
  String get viewAll => 'Tumunu Gor';

  @override
  String get libraryTitle => 'Icerik Kutuphanesi';

  @override
  String libraryPersonalTab(int count) {
    return 'Kisisel ($count)';
  }

  @override
  String librarySharedTab(int count) {
    return 'Paylasilan ($count)';
  }

  @override
  String get librarySearch => 'Belge ara...';

  @override
  String get libraryEmptyPersonal => 'Henuz kisisel belgeniz yok';

  @override
  String get libraryEmptyCategory => 'Bu kategoride belge yok';

  @override
  String get libraryFilterAll => 'Tumu';

  @override
  String get libraryFilterSOP => 'SOP';

  @override
  String get libraryFilterEmergency => 'Acil Durum';

  @override
  String get libraryFilterCert => 'Sertifika';

  @override
  String get libraryFilterOther => 'Diger';

  @override
  String get libraryDeleteTitle => 'Belge Sil';

  @override
  String libraryDeleteConfirm(String title) {
    return '$title silinsin mi?';
  }

  @override
  String get libraryDeleted => 'Belge silindi';

  @override
  String get libraryUploadTitle => 'Dosya Yukle';

  @override
  String get libraryDocTitle => 'Baslik';

  @override
  String get libraryDocTitleHint => 'Belge adi';

  @override
  String get libraryDocType => 'Belge Tipi';

  @override
  String get libraryDocTypeCert => 'Sertifika';

  @override
  String get libraryDocTypeHealth => 'Saglik Raporu';

  @override
  String get libraryDocTypeId => 'Kimlik Fotokopisi';

  @override
  String get libraryDocTypeEmergency => 'Acil Durum Plani';

  @override
  String get libraryDepartment => 'Departman';

  @override
  String get libraryDepartmentError => 'Departmanlar yuklenemedi';

  @override
  String get librarySelectFile => 'Dosya Sec';

  @override
  String get libraryUploadValidation => 'Baslik ve dosya secimi zorunlu';

  @override
  String get libraryUploaded => 'Dosya yuklendi';

  @override
  String get libraryUploadFailed => 'Yukleme basarisiz';

  @override
  String get libraryUploadButton => 'Yukle';

  @override
  String get profileTitle => 'Profil Karti';

  @override
  String get profilePhoneValidation =>
      'Gecerli bir telefon numarasi girin (05xx xxx xxxx)';

  @override
  String get profileSectionContact => 'ILETISIM BILGILERI';

  @override
  String get profileEmail => 'E-posta';

  @override
  String get profilePhone => 'Telefon';

  @override
  String get profileAddress => 'Adres';

  @override
  String get profileSectionEmergency => 'ACIL DURUM KISI';

  @override
  String get profileFullName => 'Ad Soyad';

  @override
  String get profileRelation => 'Yakinlik';

  @override
  String get profileSectionPersonal => 'KISISEL BILGILER';

  @override
  String get profileBirthDate => 'Dogum Tarihi';

  @override
  String get profileBloodType => 'Kan Grubu';

  @override
  String get profileTcId => 'TC Kimlik';

  @override
  String get profileShift => 'Vardiya';

  @override
  String get profileStartDate => 'Ise Giris';

  @override
  String get profileSectionSkills => 'YETENEKLER';

  @override
  String get profileSectionCerts => 'SERTIFIKALAR';

  @override
  String get profileSectionAbout => 'HAKKINDA';

  @override
  String get profileLoadError => 'Profil yuklenemedi';

  @override
  String get profileEditTitle => 'Profil Duzenle';

  @override
  String get profileEditPhone => 'Telefon (05xx xxx xxxx)';

  @override
  String get profileEditBloodType => 'Kan Grubu';

  @override
  String get profileEditEmergencyName => 'Acil Durum Kisi Adi';

  @override
  String get profileEditEmergencyPhone => 'Acil Durum Telefon (05xx xxx xxxx)';

  @override
  String get profileEditRelation => 'Yakinlik Derecesi';

  @override
  String get profileRelationSpouse => 'Es';

  @override
  String get profileRelationMother => 'Anne';

  @override
  String get profileRelationFather => 'Baba';

  @override
  String get profileRelationSibling => 'Kardes';

  @override
  String get profileRelationOther => 'Diger';

  @override
  String get profileEditAbout => 'Hakkinda';

  @override
  String get profilePhoneInvalid => 'Lutfen gecerli telefon numaralari girin';

  @override
  String get profileUpdated => 'Profil guncellendi';

  @override
  String get profileUpdateFailed => 'Guncelleme basarisiz';

  @override
  String get announcementTitle => 'Duyuru Panosu';

  @override
  String get announcementEmpty => 'Henuz duyuru yok';

  @override
  String get announcementSearch => 'Duyuru ara...';

  @override
  String get announcementNoResult => 'Sonuc bulunamadi';

  @override
  String get announcementDeleteTitle => 'Duyuru Sil';

  @override
  String announcementDeleteConfirm(String title) {
    return '\"$title\" silinsin mi?';
  }

  @override
  String announcementReadCount(int count) {
    return '$count kisi okudu';
  }

  @override
  String get announcementMarkRead => 'Okudum';

  @override
  String get announcementRead => 'Okundu';

  @override
  String get announcementMarkedRead => 'Duyuru okundu olarak isaretlendi';

  @override
  String get announcementDeleted => 'Duyuru silindi';

  @override
  String get announcementDeleteFailed => 'Silme basarisiz';

  @override
  String get announcementNew => 'Yeni Duyuru';

  @override
  String get announcementEditTitle => 'Duyuru Duzenle';

  @override
  String get announcementFieldTitle => 'Baslik';

  @override
  String get announcementFieldContent => 'Icerik';

  @override
  String get announcementFieldPriority => 'Oncelik';

  @override
  String get announcementPriorityNormal => 'Normal';

  @override
  String get announcementPriorityHigh => 'Yuksek';

  @override
  String get announcementPriorityCritical => 'Kritik';

  @override
  String get announcementTargetDept => 'Hedef Departman';

  @override
  String get announcementAllCompany => 'Tum Sirket';

  @override
  String get announcementPin => 'Sabitle';

  @override
  String get announcementValidation => 'Baslik ve icerik zorunlu';

  @override
  String get announcementUpdated => 'Duyuru guncellendi';

  @override
  String get announcementCreated => 'Duyuru olusturuldu';

  @override
  String get announcementUpdateFailed => 'Guncelleme basarisiz';

  @override
  String get announcementCreateFailed => 'Duyuru olusturulamadi';

  @override
  String get announcementEdit => 'Duzenle';

  @override
  String get announcementPublish => 'Yayinla';

  @override
  String get tourTitle => 'Tur';

  @override
  String get tourLoading => 'Yukleniyor...';

  @override
  String get tourRetry => 'Tekrar Dene';

  @override
  String tourCheckpoints(int scanned, int total) {
    return '$scanned/$total nokta';
  }

  @override
  String tourSkipped(int count) {
    return '$count atlandi';
  }

  @override
  String get tourScanQR => 'QR Tara';

  @override
  String get tourScanning => 'Taraniyor...';

  @override
  String get tourScanHeader => 'QR Kodu Okutun';

  @override
  String tourScanError(String error) {
    return 'Tarama hatasi: $error';
  }

  @override
  String tourRemaining(int count) {
    return '$count kaldi';
  }

  @override
  String tourSkipTitle(String name) {
    return '$name atla';
  }

  @override
  String get tourSkipReason => 'Atlama sebebi (zorunlu)';

  @override
  String get tourCompleted => 'Tur Tamamlandi!';

  @override
  String get tourCompletedAll => 'Tum kontrol noktalari tarandi.';

  @override
  String tourCompleteSummary(
    String scanned,
    String total,
    String skipped,
    String rate,
  ) {
    return 'Taranan: $scanned/$total\nAtlanan: $skipped\nTamamlanma: %$rate';
  }

  @override
  String get tourComplete => 'Tamamla';

  @override
  String get tourCancelTitle => 'Turu iptal et?';

  @override
  String get tourCancelWarning => 'Bu islem geri alinamaz.';

  @override
  String get notificationTitle => 'Bildirimler';

  @override
  String get notificationMarkAllRead => 'Tumu Okundu';

  @override
  String get notificationEmpty => 'Bildirim yok';

  @override
  String get notificationTime => 'Zaman';

  @override
  String get notificationSource => 'Kaynak';

  @override
  String get notificationCategory => 'Kategori';

  @override
  String get notificationPriority => 'Oncelik';

  @override
  String get quizTitle => 'Quiz';

  @override
  String get quizNoQuestions => 'Soru bulunamadi';

  @override
  String get quizSubmit => 'Quizi Tamamla';

  @override
  String get quizIncomplete => 'Tum sorulari yanitlayin';

  @override
  String get quizEditTitle => 'Soru Duzenle';

  @override
  String get quizNewTitle => 'Yeni Soru Ekle';

  @override
  String get quizQuestionText => 'Soru Metni';

  @override
  String quizLoadError(String error) {
    return 'Quiz yuklenemedi: $error';
  }

  @override
  String get quizUpdated => 'Quiz guncellendi';

  @override
  String get quizCreated => 'Quiz olusturuldu';

  @override
  String get progressTitle => 'Ilerleme Takibi';

  @override
  String get progressMyTab => 'Benim Ilerlemem';

  @override
  String get progressTeamTab => 'Ekip Takibi';

  @override
  String get contentManagerTitle => 'Icerik Yonetimi';

  @override
  String get contentManagerSearch => 'Semantik Arama';

  @override
  String get contentManagerTreeBack => 'Agaca don';

  @override
  String get contentManagerTree => 'Icerik Agaci';

  @override
  String get routeEditorEdit => 'Rotayi Duzenle';

  @override
  String get routeEditorNew => 'Yeni Egitim Rotasi';

  @override
  String get routeEditorSelectDept => 'Lutfen departman secin';

  @override
  String get routeEditorUpdated => 'Rota basariyla guncellendi';

  @override
  String get routeEditorCreated => 'Rota basariyla olusturuldu';

  @override
  String get routeEditorDeleteModule => 'Modulu Sil';

  @override
  String routeEditorDeleteConfirm(String title) {
    return '\"$title\" modulunu silmek istediginize emin misiniz?';
  }

  @override
  String get ackTitle => 'Egitim Onayi';

  @override
  String get ackText => 'Onay Metni';

  @override
  String get ackStatement =>
      'Bu egitimi okudum, anladim ve uygulamayi taahhut ediyorum.';

  @override
  String get ackCheckbox => 'Yukaridaki metni okudum ve kabul ediyorum';

  @override
  String get ackConfirm => 'Onayla';

  @override
  String get ackFailed => 'Onay gonderilemedi';

  @override
  String get scadaThresholds => 'Esik Degerleri';

  @override
  String get scadaNoThreshold => 'Esik tanimlanmamis';

  @override
  String get scadaAllNormal => 'Tum sistemler normal calisiyor';

  @override
  String get scadaAlarmAcked => 'Alarm onaylandi';

  @override
  String scadaSensor(int id) {
    return 'Sensor #$id';
  }

  @override
  String get scadaNoData => 'Henuz veri yok';

  @override
  String scadaLoadError(String error) {
    return 'Veri yuklenemedi: $error';
  }

  @override
  String get commonCancel => 'Iptal';

  @override
  String get commonDelete => 'Sil';

  @override
  String get commonSave => 'Kaydet';

  @override
  String get commonClose => 'Kapat';

  @override
  String get commonOk => 'Tamam';

  @override
  String get commonRetry => 'Tekrar Dene';

  @override
  String get commonBack => 'Vazgec';

  @override
  String commonError(String error) {
    return 'Hata: $error';
  }

  @override
  String get featureGateUpgradeRequired => 'Plan Yukseltme Gerekli';

  @override
  String get featureGateUpgradeMessage =>
      'Bu ozellige erismek icin planin yukseltilmesi gerekiyor.';

  @override
  String get featureGateContactAdmin =>
      'Yukseltme icin tesis yoneticinize basvurun';

  @override
  String featureGateCurrentPlan(String plan) {
    return 'Mevcut Plan: $plan';
  }

  @override
  String get accessDeniedTitle => 'Erisim Yetkiniz Yok';

  @override
  String get accessDeniedMessage =>
      'Bu sayfaya erisim icin yetkiniz bulunmamaktadir.';

  @override
  String get accessDeniedHome => 'Ana Sayfaya Don';

  @override
  String pageNotFound(String uri) {
    return 'Sayfa bulunamadi: $uri';
  }

  @override
  String get certificateTitle => 'Tamamlama Sertifikasi';

  @override
  String get certificateHeader => 'TAMAMLAMA SERTIFIKASI';

  @override
  String get certificateConfirms => 'Bu belge ile onaylanir ki';

  @override
  String get certificateCompleted =>
      'asagidaki egitim rotasini basariyla tamamlamistir';

  @override
  String get certificateDate => 'Tarih';

  @override
  String get certificateId => 'Sertifika No';

  @override
  String get certificateDownload => 'PDF Indir';

  @override
  String get certificateDownloadError => 'PDF indirilemedi';

  @override
  String get badgesTitle => 'Rozetler';

  @override
  String get badgesEarned => 'Rozet kazanildi';

  @override
  String get badgesAll => 'TUM ROZETLER';

  @override
  String get badgeEarned => 'Kazanildi';

  @override
  String get badgeFirstStep => 'Ilk Adim';

  @override
  String get badgeFirstStepDesc => 'Ilk egitim modulunu tamamla';

  @override
  String get badgeQuizMaster => 'Quiz Ustasi';

  @override
  String get badgeQuizMasterDesc => '5 quizi basariyla gec';

  @override
  String get badgeFastLearner => 'Hizli Ogrenci';

  @override
  String get badgeFastLearnerDesc =>
      'Bir modulu 10 dakikadan kisa surede tamamla';

  @override
  String get badgePerfectScore => 'Tam Puan';

  @override
  String get badgePerfectScoreDesc => 'Bir quizden %100 al';

  @override
  String get badgeTeamPlayer => 'Takim Oyuncusu';

  @override
  String get badgeTeamPlayerDesc => 'Bir rotadaki tum modulleri tamamla';

  @override
  String get badgeBookworm => 'Bilgi Kurdu';

  @override
  String get badgeBookwormDesc => '10 kutuphane dokumanini oku';

  @override
  String get leaderboardTitle => 'Siralama';

  @override
  String get leaderboardSection => 'DEPARTMAN SIRALAMASI';

  @override
  String get leaderboardEmpty => 'Siralama verisi bulunamadi';

  @override
  String get leaderboardYou => 'Sen';

  @override
  String get approvalTitle => 'Icerik Onaylari';

  @override
  String get approvalEmpty => 'Onay bekleyen icerik yok';

  @override
  String get approvalApprove => 'Onayla';

  @override
  String get approvalReject => 'Reddet';

  @override
  String get approvalRejectTitle => 'Icerigi Reddet';

  @override
  String get approvalRejectReason => 'Red sebebi (opsiyonel)';

  @override
  String get approvalApproved => 'Icerik onaylandi';

  @override
  String get approvalRejected => 'Icerik reddedildi';

  @override
  String get themeToggle => 'Tema Degistir';

  @override
  String get themeDark => 'Karanlik Tema';

  @override
  String get themeLight => 'Aydinlik Tema';

  @override
  String get progressReportDownload => 'Rapor Indir';

  @override
  String get progressReportError => 'Rapor indirilemedi';

  @override
  String get dashboardTitle => 'Kontrol Paneli';

  @override
  String dashboardWelcome(String name) {
    return 'Hosgeldin, $name';
  }

  @override
  String get commonLoading => 'Yukleniyor...';

  @override
  String get commonNoData => 'Veri bulunamadi';

  @override
  String get commonSearch => 'Ara...';

  @override
  String get commonFilter => 'Filtrele';

  @override
  String get commonSort => 'Sirala';

  @override
  String get commonRefresh => 'Yenile';

  @override
  String get commonSettings => 'Ayarlar';

  @override
  String get commonLogout => 'Cikis Yap';

  @override
  String get commonYes => 'Evet';

  @override
  String get commonNo => 'Hayir';

  @override
  String get commonConfirm => 'Onayla';

  @override
  String get commonSuccess => 'Basarili';

  @override
  String get commonFailed => 'Basarisiz';
}
