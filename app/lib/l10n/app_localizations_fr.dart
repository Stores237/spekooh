// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get navHome => 'Accueil';

  @override
  String get navPapers => 'Épreuves';

  @override
  String get navForum => 'Forum';

  @override
  String get navQuizzes => 'Quiz';

  @override
  String get settingsTitle => 'Paramètres';

  @override
  String get settingsSubtitle => 'Compte et application';

  @override
  String get spekoohProTitle => 'Spekooh Pro';

  @override
  String get spekoohProSubtitle => 'Épreuves illimitées · sans publicité';

  @override
  String get languageSection => 'Langue';

  @override
  String get helpSection => 'Aide';

  @override
  String get helpSupportTitle => 'Aide et assistance';

  @override
  String get helpSupportSubtitle => 'Discutez avec une vraie personne';

  @override
  String get helpWhatsappTitle => 'Rejoignez notre groupe WhatsApp';

  @override
  String get helpWhatsappSubtitle => 'Astuces et actualités';

  @override
  String get helpContactTitle => 'Contactez-nous';

  @override
  String get helpContactSubtitle => 'Questions ou retours';

  @override
  String get aboutSection => 'À propos';

  @override
  String get aboutWebsiteTitle => 'Visitez notre site web';

  @override
  String get aboutPrivacyTitle => 'Politique de confidentialité';

  @override
  String get logOut => 'Déconnexion';

  @override
  String get logIn => 'Connexion';

  @override
  String get authCreateAccountTitle => 'Créez votre compte';

  @override
  String get authLoginTitle => 'Connexion à Spekooh';

  @override
  String get authNameLabel => 'NOM';

  @override
  String get authNameHint => 'Votre nom';

  @override
  String get authEmailLabel => 'EMAIL';

  @override
  String get authEmailHint => 'vous@exemple.com';

  @override
  String get authPasswordLabel => 'MOT DE PASSE';

  @override
  String get authReferralLabel => 'CODE DE PARRAINAGE (FACULTATIF)';

  @override
  String get authReferralHint => 'ex. A1B2C3D4';

  @override
  String get authPleaseWait => 'Veuillez patienter…';

  @override
  String get authCreateAccountButton => 'Créer un compte';

  @override
  String get authLoginButton => 'Se connecter';

  @override
  String get authSwitchToLogin => 'Vous avez déjà un compte ? Connectez-vous';

  @override
  String get authSwitchToRegister => 'Nouveau ici ? Créez un compte';

  @override
  String get authErrorLogin =>
      'Échec de la connexion. Vérifiez votre email et votre mot de passe.';

  @override
  String get authErrorRegisterReferral =>
      'Échec de l\'inscription. Vérifiez vos informations et que le code de parrainage est correct.';

  @override
  String get authErrorRegisterGeneric =>
      'Échec de l\'inscription. Cet email est peut-être déjà utilisé.';

  @override
  String get authErrorUnknown =>
      'Une erreur s\'est produite. Vérifiez votre connexion et réessayez.';

  @override
  String get homeWelcomeGreeting => 'Bienvenue';

  @override
  String get guestLabel => 'Invité';

  @override
  String get joinFree => 'Inscription gratuite';

  @override
  String get homeExploringBadge => 'Vous explorez — sans compte';

  @override
  String get homeFreeViewsLabel => 'ÉPREUVES GRATUITES';

  @override
  String get homeFreeViewsCount => '3 par jour';

  @override
  String get homeFreeViewsHint =>
      'Aucun compte requis. Inscrivez-vous pour suivre votre utilisation et débloquer plus.';

  @override
  String get goPro => 'Passer à Pro';

  @override
  String get homeNoPapersYet =>
      'Aucune épreuve publiée pour l\'instant — revenez bientôt.';

  @override
  String homePaperLabelWithYear(String label, int year) {
    return '$label $year';
  }

  @override
  String get homeFreeToView =>
      'Consultation gratuite — corrigé vendu séparément';

  @override
  String get homeContributionTitle => 'Contribution — gagnez des crédits';

  @override
  String get homeContributionPrompt =>
      'Vous avez une ancienne épreuve ou un rapport que nous n\'avons pas ?';

  @override
  String get homeContributionSubtitle =>
      'Prenez une photo, identifiez-la, gagnez un bonus une fois vérifiée — la première contribution compte.';

  @override
  String get notesTitle => 'Notes';

  @override
  String get notesSubtitle => 'Fiches de révision par matière';

  @override
  String get shopTitle => 'Boutique';

  @override
  String get shopSubtitle => 'Fascicules partenaires, retrait par QR code';

  @override
  String get partnerPamphletsTitle => 'Fascicules partenaires';

  @override
  String get homeNoPamphlet => 'Aucun fascicule à la une pour le moment.';

  @override
  String homePamphletSoldBy(String partner) {
    return 'Vendu par $partner · retrait avec un code QR.';
  }

  @override
  String get buy => 'Acheter';

  @override
  String get homeSignUpPrompt => 'INSCRIVEZ-VOUS SEULEMENT QUAND VOUS VOULEZ…';

  @override
  String get homeLockedCredits => 'Gagner et utiliser des crédits contributeur';

  @override
  String get homeLockedTrackContributions => 'Suivre vos contributions';

  @override
  String get homeLockedInstructorAlerts =>
      'Recevoir des alertes de statut instructeur';

  @override
  String get homeReadingOpenNote =>
      'La lecture des épreuves reste ouverte à tous — 3 consultations gratuites par jour, sans compte.';

  @override
  String get greetingMorning => 'Bonjour';

  @override
  String get greetingAfternoon => 'Bonjour';

  @override
  String get greetingEvening => 'Bonsoir';

  @override
  String get practiceModeLabel => 'MODE ENTRAÎNEMENT';

  @override
  String get practiceModeTitle => 'Apprenez sans pression de chronomètre';

  @override
  String get practiceModeSubtitle =>
      'Parcourez de vraies épreuves par matière et année.';

  @override
  String get trialLabel => 'VOTRE ESSAI GRATUIT';

  @override
  String get trialFirstUnlockFree =>
      'Ouvrez votre premier corrigé gratuitement';

  @override
  String get trialUnlimitedViews =>
      'Consultations illimitées pendant votre essai';

  @override
  String trialDaysLeft(int days) {
    return '$days jours restants';
  }

  @override
  String get trialFeatures => 'Consultations illimitées · Assistant IA';

  @override
  String get trialKeepAccess => 'Garder mon accès';

  @override
  String get quickActionContribute => 'Contribuer';

  @override
  String get dailyChallengeLabel => 'Défi du jour';

  @override
  String get dailyChallengeLoading => 'Chargement…';

  @override
  String dailyChallengeInfo(String title, int count) {
    return '$title · $count questions';
  }

  @override
  String get playNow => 'Jouer maintenant';

  @override
  String streakDayCount(int count) {
    return 'SÉRIE DE $count JOURS';
  }

  @override
  String get startAStreak => 'COMMENCER UNE SÉRIE';

  @override
  String streakDaysCount(int count) {
    return '$count jours';
  }

  @override
  String get streakStart => 'Commencer';

  @override
  String get streakKeepGoing => 'Continuez ainsi';

  @override
  String get streakPlayToBegin => 'Jouez à un quiz pour commencer';

  @override
  String get papersTitle => 'Anciennes épreuves';

  @override
  String get papersSubtitle =>
      'Tous les niveaux, tous les systèmes — du Primaire au Concours des Grandes Écoles.';

  @override
  String get searchExamOrSubject =>
      'Rechercher un type d\'examen ou une matière...';

  @override
  String get categoryLabel => 'CATÉGORIE';

  @override
  String chooseSystemHeader(String category) {
    return '$category — choisir le système';
  }

  @override
  String examTypeStepHeaderWithSystem(String category, String system) {
    return '$category · $system';
  }

  @override
  String get searchExamType => 'Rechercher un type d\'examen...';

  @override
  String examTypeOfficialPlus(String variant) {
    return 'Officiel + $variant';
  }

  @override
  String get examTypeOfficialOnly => 'Officiel uniquement';

  @override
  String chooseTrackHeader(String examType) {
    return '$examType — choisir la filière';
  }

  @override
  String get searchSubjects => 'Rechercher une matière...';

  @override
  String get subjectCardSubtitle => 'Épreuves + corrigés';

  @override
  String get paperMarkingGuideAvailable => 'Corrigé disponible';

  @override
  String get paperUnderReview => 'En cours de vérification';

  @override
  String get noPapersYetTitle => 'Aucune épreuve pour l\'instant';

  @override
  String noPapersYetBody(String subject) {
    return 'Personne n\'a encore soumis d\'épreuve de $subject pour ce type d\'examen. Soyez le premier — soumettez-en une depuis l\'onglet Contribuer.';
  }

  @override
  String get contributionTitle => 'Contribution';

  @override
  String get contributionSubtitle =>
      'Partagez une ancienne épreuve ou un rapport académique — chaque contribution aide un autre étudiant.';

  @override
  String get examPaperTab => 'Épreuve d\'examen';

  @override
  String get academicReportTab => 'Rapport académique';

  @override
  String get notAvailableYet => 'Pas encore disponible';

  @override
  String get academicReportComingSoon =>
      'Les soumissions de rapports académiques ne sont pas encore connectées au serveur — seules les épreuves d\'examen peuvent être soumises pour l\'instant. Revenez bientôt.';

  @override
  String get takePhotoOrUploadPdf => 'Prenez une photo ou téléversez un PDF';

  @override
  String get fileFormatsHint => 'JPG, PNG ou PDF · jusqu\'à 20 Mo';

  @override
  String get tapToReplace => 'Appuyez pour remplacer';

  @override
  String get educationLevelLabel => 'Niveau d\'étude';

  @override
  String get systemLabel => 'Système';

  @override
  String get examTypeLabel => 'Type d\'examen';

  @override
  String get trackLabel => 'Filière';

  @override
  String get subjectLabel => 'Matière';

  @override
  String get yearLabel => 'Année';

  @override
  String get examBoardHint => 'Jury d\'examen / établissement (facultatif)';

  @override
  String get contributionBonusBanner =>
      'Les nouvelles soumissions vérifiées rapportent un bonus de crédit — utilisable pour débloquer des corrigés.';

  @override
  String get submitPaperButton => 'Soumettre l\'épreuve';

  @override
  String get selectPlaceholder => 'Choisir';

  @override
  String get nothingAvailable => 'Rien de disponible.';

  @override
  String get submitAnother => 'Soumettre une autre';

  @override
  String get contributionReceivedTitle => 'Contribution reçue';

  @override
  String get contributionReceivedBody =>
      'Nous la vérifierons d\'abord par rapport aux épreuves existantes — si elle est nouvelle, elle passe en revue par l\'instructeur. Suivez-la depuis Profil.';

  @override
  String submissionFailed(String error) {
    return 'Échec de la soumission : $error';
  }

  @override
  String get choosePdfOrImage => 'Choisir un PDF ou une image';

  @override
  String get takePhoto => 'Prendre une photo';
}
