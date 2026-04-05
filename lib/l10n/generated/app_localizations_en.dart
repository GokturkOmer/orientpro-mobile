// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class SEn extends S {
  SEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'OrientPro';

  @override
  String get systemActive => 'System active';

  @override
  String get loginTitle => 'SYSTEM LOGIN';

  @override
  String get loginButton => 'Sign In';

  @override
  String get loginEmail => 'Email';

  @override
  String get loginPassword => 'Password';

  @override
  String get loginSubtitle => 'SCADA & Facility Management System';

  @override
  String get validationEmailRequired => 'Email address is required';

  @override
  String get validationEmailInvalid => 'Enter a valid email address';

  @override
  String get validationPasswordRequired => 'Password is required';

  @override
  String get validationPasswordTooShort =>
      'Password must be at least 4 characters';

  @override
  String get rememberMe => 'Remember me';

  @override
  String get orgSelectTitle => 'Select Facility';

  @override
  String get orgSelectSubtitle =>
      'You are a member of multiple facilities.\nSelect a facility to continue.';

  @override
  String get orgSelectDefault => 'Default';

  @override
  String get orgSelectOtherAccount => 'Sign In with Different Account';

  @override
  String get orgSelectMember => 'Member';

  @override
  String get moduleSelectionTitle => 'Modüle Selection';

  @override
  String get moduleOrientation => 'Orientation';

  @override
  String get moduleOrientationSub => 'Training & Guide';

  @override
  String get moduleOrientationDesc =>
      'Personnel orientation processes,\ntraining routes and tracking';

  @override
  String get moduleAdmin => 'Management';

  @override
  String get moduleAdminSub => 'Admin Panel';

  @override
  String get moduleContent => 'Content';

  @override
  String get moduleContentSub => 'Content Management';

  @override
  String get modulePro => 'Pro';

  @override
  String get moduleProSub => 'Technical Management';

  @override
  String get moduleProLocked => 'Plan Upgrade Required';

  @override
  String get orientationTitle => 'Orientation';

  @override
  String orientationWelcome(String name) {
    return 'Welcome, $name';
  }

  @override
  String get orientationSubtitle =>
      'Welcome to the orientation and training module';

  @override
  String get orientationOverallProgress => 'Overall Progress';

  @override
  String get orientationCompleted => 'Completed';

  @override
  String get orientationOngoing => 'Ongoing';

  @override
  String get orientationQuizSuccess => 'Quiz Score';

  @override
  String get orientationPendingTasks => 'PENDING TASKS';

  @override
  String orientationPendingApproval(int count) {
    return '$count modules awaiting approval';
  }

  @override
  String orientationReviewRequired(int count) {
    return '$count topics need review';
  }

  @override
  String get orientationMandatoryIncomplete => 'INCOMPLETE MANDATORY TRAININGS';

  @override
  String get orientationGeneralBadge => 'General Orientation';

  @override
  String get orientationThisWeek => 'This Week';

  @override
  String get orientationDuration => 'Duration';

  @override
  String get orientationApproval => 'Approval';

  @override
  String get orientationAnnouncements => 'ANNOUNCEMENTS';

  @override
  String orientationNewCount(int count) {
    return '$count new';
  }

  @override
  String get orientationModules => 'MODULES';

  @override
  String get navTrainingRoutes => 'Training Routes';

  @override
  String get navTrainingRoutesSub =>
      'Department-based training routes and content';

  @override
  String get navQuizzes => 'Quizzes & Exams';

  @override
  String get navQuizzesSub => 'Knowledge tests and assessments';

  @override
  String get navProgress => 'Progress Tracking';

  @override
  String get navProgressSub => 'Training completion status and reports';

  @override
  String get navAiAssistant => 'AI Assistant';

  @override
  String get navAiAssistantSub => 'AI support for the orientation process';

  @override
  String get navAnnouncements => 'Announcement Board';

  @override
  String get navAnnouncementsSub => 'Company and department announcements';

  @override
  String get navLibrary => 'Content Library';

  @override
  String get navLibrarySub => 'Personal and shared documents';

  @override
  String get navProfile => 'Profile Card';

  @override
  String get navProfileSub => 'Personal info, emergency contacts, certificates';

  @override
  String get navShifts => 'Shifts & Tasks';

  @override
  String get navShiftsSub => 'Weekly shift schedule and task tracking';

  @override
  String get viewAll => 'View All';

  @override
  String get libraryTitle => 'Content Library';

  @override
  String libraryPersonalTab(int count) {
    return 'Personal ($count)';
  }

  @override
  String librarySharedTab(int count) {
    return 'Shared ($count)';
  }

  @override
  String get librarySearch => 'Search documents...';

  @override
  String get libraryEmptyPersonal => 'You have no personal documents yet';

  @override
  String get libraryEmptyCategory => 'No documents in this category';

  @override
  String get libraryFilterAll => 'All';

  @override
  String get libraryFilterSOP => 'SOP';

  @override
  String get libraryFilterEmergency => 'Emergency';

  @override
  String get libraryFilterCert => 'Certificate';

  @override
  String get libraryFilterOther => 'Other';

  @override
  String get libraryDeleteTitle => 'Delete Document';

  @override
  String libraryDeleteConfirm(String title) {
    return 'Delete $title?';
  }

  @override
  String get libraryDeleted => 'Document deleted';

  @override
  String get libraryUploadTitle => 'Upload File';

  @override
  String get libraryDocTitle => 'Title';

  @override
  String get libraryDocTitleHint => 'Document name';

  @override
  String get libraryDocType => 'Document Type';

  @override
  String get libraryDocTypeCert => 'Certificate';

  @override
  String get libraryDocTypeHealth => 'Health Report';

  @override
  String get libraryDocTypeId => 'ID Photocopy';

  @override
  String get libraryDocTypeEmergency => 'Emergency Plan';

  @override
  String get libraryDepartment => 'Department';

  @override
  String get libraryDepartmentError => 'Failed to load departments';

  @override
  String get librarySelectFile => 'Select File';

  @override
  String get libraryUploadValidation => 'Title and file selection are required';

  @override
  String get libraryUploaded => 'File uploaded';

  @override
  String get libraryUploadFailed => 'Upload failed';

  @override
  String get libraryUploadButton => 'Upload';

  @override
  String get profileTitle => 'Profile Card';

  @override
  String get profilePhoneValidation =>
      'Enter a valid phone number (05xx xxx xxxx)';

  @override
  String get profileSectionContact => 'CONTACT INFORMATION';

  @override
  String get profileEmail => 'Email';

  @override
  String get profilePhone => 'Phone';

  @override
  String get profileAddress => 'Address';

  @override
  String get profileSectionEmergency => 'EMERGENCY CONTACT';

  @override
  String get profileFullName => 'Full Name';

  @override
  String get profileRelation => 'Relationship';

  @override
  String get profileSectionPersonal => 'PERSONAL INFORMATION';

  @override
  String get profileBirthDate => 'Date of Birth';

  @override
  String get profileBloodType => 'Blood Type';

  @override
  String get profileTcId => 'ID Number';

  @override
  String get profileShift => 'Shift';

  @override
  String get profileStartDate => 'Start Date';

  @override
  String get profileSectionSkills => 'SKILLS';

  @override
  String get profileSectionCerts => 'CERTIFICATES';

  @override
  String get profileSectionAbout => 'ABOUT';

  @override
  String get profileLoadError => 'Failed to load profile';

  @override
  String get profileEditTitle => 'Edit Profile';

  @override
  String get profileEditPhone => 'Phone (05xx xxx xxxx)';

  @override
  String get profileEditBloodType => 'Blood Type';

  @override
  String get profileEditEmergencyName => 'Emergency Contact Name';

  @override
  String get profileEditEmergencyPhone => 'Emergency Phone (05xx xxx xxxx)';

  @override
  String get profileEditRelation => 'Relationship';

  @override
  String get profileRelationSpouse => 'Spouse';

  @override
  String get profileRelationMother => 'Mother';

  @override
  String get profileRelationFather => 'Father';

  @override
  String get profileRelationSibling => 'Sibling';

  @override
  String get profileRelationOther => 'Other';

  @override
  String get profileEditAbout => 'About';

  @override
  String get profilePhoneInvalid => 'Please enter valid phone numbers';

  @override
  String get profileUpdated => 'Profile updated';

  @override
  String get profileUpdateFailed => 'Update failed';

  @override
  String get announcementTitle => 'Announcement Board';

  @override
  String get announcementEmpty => 'No announcements yet';

  @override
  String get announcementSearch => 'Search announcements...';

  @override
  String get announcementNoResult => 'No results found';

  @override
  String get announcementDeleteTitle => 'Delete Announcement';

  @override
  String announcementDeleteConfirm(String title) {
    return 'Delete \"$title\"?';
  }

  @override
  String announcementReadCount(int count) {
    return '$count people read';
  }

  @override
  String get announcementMarkRead => 'Mark Read';

  @override
  String get announcementRead => 'Read';

  @override
  String get announcementMarkedRead => 'Announcement marked as read';

  @override
  String get announcementDeleted => 'Announcement deleted';

  @override
  String get announcementDeleteFailed => 'Delete failed';

  @override
  String get announcementNew => 'New Announcement';

  @override
  String get announcementEditTitle => 'Edit Announcement';

  @override
  String get announcementFieldTitle => 'Title';

  @override
  String get announcementFieldContent => 'Content';

  @override
  String get announcementFieldPriority => 'Priority';

  @override
  String get announcementPriorityNormal => 'Normal';

  @override
  String get announcementPriorityHigh => 'High';

  @override
  String get announcementPriorityCritical => 'Critical';

  @override
  String get announcementTargetDept => 'Target Department';

  @override
  String get announcementAllCompany => 'All Company';

  @override
  String get announcementPin => 'Pin';

  @override
  String get announcementValidation => 'Title and content are required';

  @override
  String get announcementUpdated => 'Announcement updated';

  @override
  String get announcementCreated => 'Announcement created';

  @override
  String get announcementUpdateFailed => 'Update failed';

  @override
  String get announcementCreateFailed => 'Failed to create announcement';

  @override
  String get announcementEdit => 'Edit';

  @override
  String get announcementPublish => 'Publish';

  @override
  String get tourTitle => 'Tour';

  @override
  String get tourLoading => 'Loading...';

  @override
  String get tourRetry => 'Retry';

  @override
  String tourCheckpoints(int scanned, int total) {
    return '$scanned/$total checkpoints';
  }

  @override
  String tourSkipped(int count) {
    return '$count skipped';
  }

  @override
  String get tourScanQR => 'Scan QR';

  @override
  String get tourScanning => 'Scanning...';

  @override
  String get tourScanHeader => 'Scan QR Code';

  @override
  String tourScanError(String error) {
    return 'Scan error: $error';
  }

  @override
  String tourRemaining(int count) {
    return '$count remaining';
  }

  @override
  String tourSkipTitle(String name) {
    return 'Skip $name';
  }

  @override
  String get tourSkipReason => 'Skip reason (required)';

  @override
  String get tourCompleted => 'Tour Completed!';

  @override
  String get tourCompletedAll => 'All checkpoints scanned.';

  @override
  String tourCompleteSummary(
    String scanned,
    String total,
    String skipped,
    String rate,
  ) {
    return 'Scanned: $scanned/$total\nSkipped: $skipped\nCompletion: $rate%';
  }

  @override
  String get tourComplete => 'Complete';

  @override
  String get tourCancelTitle => 'Cancel tour?';

  @override
  String get tourCancelWarning => 'This action cannot be undone.';

  @override
  String get notificationTitle => 'Notifications';

  @override
  String get notificationMarkAllRead => 'Mark All Read';

  @override
  String get notificationEmpty => 'No notifications';

  @override
  String get notificationTime => 'Time';

  @override
  String get notificationSource => 'Source';

  @override
  String get notificationCategory => 'Category';

  @override
  String get notificationPriority => 'Priority';

  @override
  String get quizTitle => 'Quiz';

  @override
  String get quizNoQuestions => 'No questions found';

  @override
  String get quizSubmit => 'Complete Quiz';

  @override
  String get quizIncomplete => 'Answer all questions';

  @override
  String get quizEditTitle => 'Edit Question';

  @override
  String get quizNewTitle => 'Add New Question';

  @override
  String get quizQuestionText => 'Question Text';

  @override
  String quizLoadError(String error) {
    return 'Failed to load quiz: $error';
  }

  @override
  String get quizUpdated => 'Quiz updated';

  @override
  String get quizCreated => 'Quiz created';

  @override
  String get progressTitle => 'Progress Tracking';

  @override
  String get progressMyTab => 'My Progress';

  @override
  String get progressTeamTab => 'Team Tracking';

  @override
  String get contentManagerTitle => 'Content Management';

  @override
  String get contentManagerSearch => 'Semantic Search';

  @override
  String get contentManagerTreeBack => 'Back to tree';

  @override
  String get contentManagerTree => 'Content Tree';

  @override
  String get routeEditorEdit => 'Edit Route';

  @override
  String get routeEditorNew => 'New Training Route';

  @override
  String get routeEditorSelectDept => 'Please select a department';

  @override
  String get routeEditorUpdated => 'Route updated successfully';

  @override
  String get routeEditorCreated => 'Route created successfully';

  @override
  String get routeEditorDeleteModule => 'Delete Module';

  @override
  String routeEditorDeleteConfirm(String title) {
    return 'Are you sure you want to delete \"$title\"?';
  }

  @override
  String get ackTitle => 'Training Acknowledgment';

  @override
  String get ackText => 'Acknowledgment Text';

  @override
  String get ackStatement =>
      'I have read, understood, and commit to applying this training.';

  @override
  String get ackCheckbox => 'I have read and accept the text above';

  @override
  String get ackConfirm => 'Confirm';

  @override
  String get ackFailed => 'Failed to send acknowledgment';

  @override
  String get scadaThresholds => 'Threshold Values';

  @override
  String get scadaNoThreshold => 'No thresholds defined';

  @override
  String get scadaAllNormal => 'All systems operating normally';

  @override
  String get scadaAlarmAcked => 'Alarm acknowledged';

  @override
  String scadaSensor(int id) {
    return 'Sensor #$id';
  }

  @override
  String get scadaNoData => 'No data yet';

  @override
  String scadaLoadError(String error) {
    return 'Failed to load data: $error';
  }

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonSave => 'Save';

  @override
  String get commonClose => 'Close';

  @override
  String get commonOk => 'OK';

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonBack => 'Back';

  @override
  String commonError(String error) {
    return 'Error: $error';
  }

  @override
  String get featureGateUpgradeRequired => 'Plan Upgrade Required';

  @override
  String get featureGateUpgradeMessage =>
      'Your plan needs to be upgraded to access this feature.';

  @override
  String get featureGateContactAdmin =>
      'Contact your facility manager for an upgrade';

  @override
  String featureGateCurrentPlan(String plan) {
    return 'Current Plan: $plan';
  }

  @override
  String get accessDeniedTitle => 'Access Denied';

  @override
  String get accessDeniedMessage =>
      'You don\'t have permission to access this page.';

  @override
  String get accessDeniedHome => 'Go to Home';

  @override
  String pageNotFound(String uri) {
    return 'Page not found: $uri';
  }

  @override
  String get certificateTitle => 'Completion Certificate';

  @override
  String get certificateHeader => 'COMPLETION CERTIFICATE';

  @override
  String get certificateConfirms => 'This certifies that';

  @override
  String get certificateCompleted =>
      'has successfully completed the following training route';

  @override
  String get certificateDate => 'Date';

  @override
  String get certificateId => 'Certificate No';

  @override
  String get certificateDownload => 'Download PDF';

  @override
  String get certificateDownloadError => 'Failed to download PDF';

  @override
  String get badgesTitle => 'Badges';

  @override
  String get badgesEarned => 'Badges earned';

  @override
  String get badgesAll => 'ALL BADGES';

  @override
  String get badgeEarned => 'Earned';

  @override
  String get badgeFirstStep => 'First Step';

  @override
  String get badgeFirstStepDesc => 'Complete your first training module';

  @override
  String get badgeQuizMaster => 'Quiz Master';

  @override
  String get badgeQuizMasterDesc => 'Pass 5 quizzes successfully';

  @override
  String get badgeFastLearner => 'Fast Learner';

  @override
  String get badgeFastLearnerDesc => 'Complete a module in under 10 minutes';

  @override
  String get badgePerfectScore => 'Perfect Score';

  @override
  String get badgePerfectScoreDesc => 'Score 100% on a quiz';

  @override
  String get badgeTeamPlayer => 'Team Player';

  @override
  String get badgeTeamPlayerDesc => 'Complete all modules in a route';

  @override
  String get badgeBookworm => 'Bookworm';

  @override
  String get badgeBookwormDesc => 'Read 10 library documents';

  @override
  String get leaderboardTitle => 'Leaderboard';

  @override
  String get leaderboardSection => 'DEPARTMENT RANKING';

  @override
  String get leaderboardEmpty => 'No ranking data available';

  @override
  String get leaderboardYou => 'You';

  @override
  String get approvalTitle => 'Content Approvals';

  @override
  String get approvalEmpty => 'No content pending approval';

  @override
  String get approvalApprove => 'Approve';

  @override
  String get approvalReject => 'Reject';

  @override
  String get approvalRejectTitle => 'Reject Content';

  @override
  String get approvalRejectReason => 'Rejection reason (optional)';

  @override
  String get approvalApproved => 'Content approved';

  @override
  String get approvalRejected => 'Content rejected';

  @override
  String get themeToggle => 'Toggle Theme';

  @override
  String get themeDark => 'Dark Theme';

  @override
  String get themeLight => 'Light Theme';

  @override
  String get progressReportDownload => 'Download Report';

  @override
  String get progressReportError => 'Failed to download report';

  @override
  String get dashboardTitle => 'Dashboard';

  @override
  String dashboardWelcome(String name) {
    return 'Welcome, $name';
  }

  @override
  String get commonLoading => 'Loading...';

  @override
  String get commonNoData => 'No data available';

  @override
  String get commonSearch => 'Search...';

  @override
  String get commonFilter => 'Filter';

  @override
  String get commonSort => 'Sort';

  @override
  String get commonRefresh => 'Refresh';

  @override
  String get commonSettings => 'Settings';

  @override
  String get commonLogout => 'Sign Out';

  @override
  String get commonYes => 'Yes';

  @override
  String get commonNo => 'No';

  @override
  String get commonConfirm => 'Confirm';

  @override
  String get commonSuccess => 'Success';

  @override
  String get commonFailed => 'Failed';
}
