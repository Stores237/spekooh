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
  String get helpWhatsappTitle => 'Assistance WhatsApp';

  @override
  String get helpWhatsappSubtitle => 'Discutez avec nous sur WhatsApp';

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
  String get authTermsCheckboxLabel =>
      'J\'accepte les Conditions d\'utilisation et la Politique de confidentialité';

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
  String get authErrorGuest =>
      'Impossible de continuer en tant qu\'invité. Vérifiez votre connexion et réessayez.';

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
  String get homeExploringBadge => 'Vous explorez : sans compte';

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
      'Aucune épreuve publiée pour l\'instant. Revenez bientôt.';

  @override
  String homePaperLabelWithYear(String label, int year) {
    return '$label $year';
  }

  @override
  String get homeFreeToView =>
      'Consultation gratuite (corrigé vendu séparément)';

  @override
  String get homeFreeToViewReport => 'Gratuit à consulter et télécharger';

  @override
  String get homeReportPaymentRequired => 'Paiement requis pour consulter';

  @override
  String get homeContributionTitle => 'Contribution : gagnez des crédits';

  @override
  String get homeContributionPrompt =>
      'Vous avez une ancienne épreuve ou un rapport que nous n\'avons pas ?';

  @override
  String get homeContributionSubtitle =>
      'Prenez une photo, identifiez-la, et gagnez un bonus une fois vérifiée. La première contribution compte.';

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
      'La lecture des épreuves reste ouverte à tous : 3 consultations gratuites par jour, sans compte.';

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
  String get readyOfflineTitle => 'Disponible hors ligne';

  @override
  String offlineDownloadsCount(int count) {
    return 'Téléchargements · $count';
  }

  @override
  String get offlineReadyTag => 'PRÊT HORS LIGNE';

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
      'Tous les niveaux, tous les systèmes, du Primaire au Concours des Grandes Écoles.';

  @override
  String get categoryLabel => 'CATÉGORIE';

  @override
  String chooseSystemHeader(String category) {
    return '$category : choisir le système';
  }

  @override
  String examTypeStepHeaderWithSystem(String category, String system) {
    return '$category · $system';
  }

  @override
  String examTypeOfficialPlus(String variant) {
    return 'Officiel + $variant';
  }

  @override
  String get examTypeOfficialOnly => 'Officiel uniquement';

  @override
  String chooseTrackHeader(String examType) {
    return '$examType : choisir la filière';
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
    return 'Personne n\'a encore soumis d\'épreuve de $subject pour ce type d\'examen. Soyez le premier à en soumettre une depuis l\'onglet Contribuer.';
  }

  @override
  String noReportsYetBody(String examType) {
    return 'Personne n\'a encore soumis de $examType. Soyez le premier à en soumettre un depuis l\'onglet Contribuer.';
  }

  @override
  String get searchPapersInCategory => 'Rechercher par année...';

  @override
  String get paperSearchNoResultsTitle => 'Aucun résultat';

  @override
  String get paperSearchNoResultsBody =>
      'Aucune épreuve ici ne correspond à votre recherche.';

  @override
  String get contributionTitle => 'Contribution';

  @override
  String get contributionSubtitle =>
      'Partagez une ancienne épreuve ou un rapport académique. Chaque contribution aide un autre étudiant.';

  @override
  String get contributorNameTitle => 'Nom du contributeur';

  @override
  String get contributorNameSubtitle =>
      'Aucun compte n\'est nécessaire pour contribuer. Nous créditerons le nom que vous nous donnez.';

  @override
  String get contributorNameLabel => 'Votre nom';

  @override
  String get examPaperTab => 'Épreuve d\'examen';

  @override
  String get academicReportTab => 'Rapport académique';

  @override
  String get notAvailableYet => 'Pas encore disponible';

  @override
  String get academicReportComingSoon =>
      'Les soumissions de rapports académiques ne sont pas encore connectées au serveur. Seules les épreuves d\'examen peuvent être soumises pour l\'instant. Revenez bientôt.';

  @override
  String get takePhotoOrUploadPdf => 'Prenez une photo ou téléversez un PDF';

  @override
  String get fileFormatsHint => 'JPG, PNG ou PDF · jusqu\'à 20 Mo';

  @override
  String fileFormatsHintWithSize(int maxMb) {
    return 'JPG, PNG ou PDF · jusqu\'à $maxMb Mo';
  }

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
  String get addCustomSubject => 'Ajouter une matière';

  @override
  String get customSubjectHint => 'ex. Géologie';

  @override
  String get addCustomSubjectCta => 'Ajouter';

  @override
  String get addCustomSubjectError =>
      'Impossible d\'ajouter cette matière. Réessayez.';

  @override
  String get yearLabel => 'Année';

  @override
  String get examBoardHint => 'Jury d\'examen / établissement (facultatif)';

  @override
  String get contributionBonusBanner =>
      'Les nouvelles soumissions vérifiées rapportent un bonus de crédit, utilisable pour débloquer des corrigés.';

  @override
  String get submitPaperButton => 'Soumettre l\'épreuve';

  @override
  String get reportTypeLabel => 'Type de rapport';

  @override
  String get institutionLabel => 'Établissement / Université';

  @override
  String get disciplineLabel => 'Discipline / Département';

  @override
  String get supervisorOptionalLabel => 'Encadreur (facultatif)';

  @override
  String get submitReportButton => 'Soumettre le rapport';

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
      'Nous la vérifierons d\'abord par rapport aux épreuves existantes. Si elle est nouvelle, elle passe en revue par l\'instructeur. Suivez-la depuis Profil.';

  @override
  String submissionFailed(String error) {
    return 'Échec de la soumission : $error';
  }

  @override
  String fileTooLargeError(int maxMb) {
    return 'Le fichier est trop volumineux. Ce type de rapport autorise jusqu\'à $maxMb Mo.';
  }

  @override
  String get choosePdfOrImage => 'Choisir un PDF ou une image';

  @override
  String get takePhoto => 'Prendre une photo';

  @override
  String get filterAll => 'Toutes';

  @override
  String get filtersTitle => 'Filtres';

  @override
  String get filterClearAll => 'Tout effacer';

  @override
  String get filterDone => 'Terminé';

  @override
  String get forumFilterMySubjects => 'Mes matières';

  @override
  String get forumFilterUnanswered => 'Sans réponse';

  @override
  String get forumFilterSolved => 'Résolu';

  @override
  String get forumMySubjectsUnavailable =>
      'La personnalisation par matière n\'est pas encore disponible.';

  @override
  String get forumSolvedUnavailable =>
      'Marquer les questions comme résolues n\'est pas encore disponible.';

  @override
  String get forumNoUnanswered =>
      'Aucune question sans réponse pour le moment.';

  @override
  String get forumNoPosts =>
      'Aucune question pour l\'instant. Soyez le premier à en poser une.';

  @override
  String get forumAskButton => '+ Question';

  @override
  String forumAnswersCount(int count) {
    return '$count réponses';
  }

  @override
  String get questionTitle => 'Question';

  @override
  String repliesCount(int count) {
    return '$count réponses';
  }

  @override
  String get writeReplyHint => 'Écrivez une réponse…';

  @override
  String get askForumTitle => 'Posez une question au forum';

  @override
  String get askSubjectHint => 'Matière (ex. Physique)';

  @override
  String get askQuestionTitleHint => 'Titre de la question';

  @override
  String get askExplainHint => 'Expliquez ce dont vous avez besoin d\'aide…';

  @override
  String get askFormRequiredError =>
      'Le titre et la question sont obligatoires.';

  @override
  String get postingLabel => 'Publication…';

  @override
  String get postQuestionButton => 'Publier la question';

  @override
  String get quizzesPageTitle => 'Quiz';

  @override
  String get dailyChallengeCapsLabel => 'DÉFI DU JOUR';

  @override
  String resetsInLabel(int hours, int minutes) {
    return 'Réinitialisation dans ${hours}h ${minutes}m';
  }

  @override
  String dailyQuestionsAndPlayed(int count, int played) {
    return '$count questions · $played étudiants ont participé';
  }

  @override
  String dailyStreakLabel(int count) {
    return 'Série de $count jours';
  }

  @override
  String get playDailyChallenge => 'Jouer au défi du jour';

  @override
  String get timedPracticeTitle => 'Entraînement chronométré';

  @override
  String get timedPracticeSubtitle => 'Conditions d\'examen';

  @override
  String get revisionModeTitle => 'Mode révision';

  @override
  String get revisionModeSubtitle => 'Sans chronomètre, indices activés';

  @override
  String get pastPaperPracticeTitle => 'Entraînement aux anciennes épreuves';

  @override
  String get pastPaperPracticeSubtitle =>
      'Généré automatiquement à partir des épreuves soumises (bientôt disponible)';

  @override
  String get fridayArenaTitle => 'Arène du vendredi';

  @override
  String get fridayArenaSubtitle =>
      'Quiz d\'élimination en direct (bientôt disponible)';

  @override
  String get topPlayers => 'Meilleurs joueurs';

  @override
  String get bySubjectTitle => 'Par matière';

  @override
  String get statQuestionsLabel => 'questions';

  @override
  String get statSuggestedLabel => 'suggéré';

  @override
  String get statPlayedLabel => 'joués';

  @override
  String get timerRowLabel => 'Minuteur 8:00';

  @override
  String get hintsRowLabel => 'Indices  2 disponibles';

  @override
  String get shuffleRowLabel => 'Mélanger les questions';

  @override
  String quizScoreLine(int score, int total) {
    return 'Vous avez obtenu $score / $total';
  }

  @override
  String get startQuizButton => 'Commencer le quiz';

  @override
  String get submittingLabel => 'Envoi en cours…';

  @override
  String get doneLabel => 'Terminé';

  @override
  String get profileTitle => 'Profil';

  @override
  String submissionsCountBadge(int count) {
    return '$count soumissions';
  }

  @override
  String quizzesCountBadge(int count) {
    return '$count quiz';
  }

  @override
  String get bonusCreditBalanceLabel => 'SOLDE DE CRÉDIT BONUS';

  @override
  String get ptsLabel => 'pts';

  @override
  String submissionsScaleNote(int count) {
    return '$count épreuves soumises · la valeur du code de réduction augmente avec vos contributions';
  }

  @override
  String get redeemCodeNotActive => 'Aucun code de réduction actif';

  @override
  String get redeemCodeReady => 'Code de réduction prêt';

  @override
  String get redeemCodeEarnHint =>
      'Vous en recevrez un dès qu\'une soumission vérifiée atteint un palier de bonus.';

  @override
  String get shareLabel => 'Partager';

  @override
  String shareRedeemCodeMessage(String code, String subtitle) {
    return 'Utilisez mon code de réduction Spekooh $code : $subtitle';
  }

  @override
  String get shareRedeemCodeSubject => 'Code de réduction Spekooh';

  @override
  String get inviteAFriendTitle => 'Invitez un ami';

  @override
  String get inviteAFriendSubtitle =>
      'Vous gagnez un bonus dès qu\'ils débloquent leur première épreuve.';

  @override
  String shareReferralMessage(String code) {
    return 'Rejoignez-moi sur Spekooh. Inscrivez-vous avec mon code de parrainage $code.';
  }

  @override
  String get shareReferralSubject => 'Code de parrainage Spekooh';

  @override
  String get badgesSectionLabel => 'Badges';

  @override
  String get submissionStatusSectionLabel => 'Statut des soumissions';

  @override
  String get profileLoginPrompt => 'Connectez-vous pour voir votre profil';

  @override
  String get profileLoginPromptSubtitle =>
      'Vos soumissions, votre solde de crédit et vos badges apparaîtront ici une fois que vous aurez un compte.';

  @override
  String get shopHeaderSubtitle =>
      'Fascicules partenaires · payez dans l\'appli, retirez avec un code QR';

  @override
  String get searchPamphlets => 'Rechercher des fascicules...';

  @override
  String pamphletSoldByQr(String partner) {
    return 'Vendu par $partner · retrait par QR';
  }

  @override
  String get notesScreenSubtitle =>
      'Fiches de révision, partagées avec les épreuves';

  @override
  String get searchTopics => 'Rechercher des sujets...';

  @override
  String get academicLevelFilterLabel => 'Niveau';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get allCaughtUp => 'Tout est à jour';

  @override
  String get adNotCompletedError =>
      'Publicité non terminée. Aucune consultation accordée.';

  @override
  String adLoadError(String error) {
    return 'Impossible de charger la publicité : $error';
  }

  @override
  String unlockFailedError(String error) {
    return 'Échec du déblocage : $error';
  }

  @override
  String get couldNotOpenFile => 'Impossible d\'ouvrir le fichier.';

  @override
  String get couldNotOpenLink => 'Impossible d\'ouvrir le lien.';

  @override
  String get viewOnlyNotice =>
      'Consultation uniquement. Débloquez pour télécharger une copie';

  @override
  String get reportThanksMessage =>
      'Merci ! L\'équipe de vérification a été notifiée.';

  @override
  String reportSendError(String error) {
    return 'Impossible d\'envoyer le signalement : $error';
  }

  @override
  String get noPaperSelectedTitle => 'Aucune épreuve sélectionnée';

  @override
  String get noPaperSelectedBody =>
      'Parcourez l\'onglet Épreuves et choisissez une matière pour ouvrir une vraie épreuve.';

  @override
  String get backButton => 'Retour';

  @override
  String get publishedStatus => 'Publié';

  @override
  String get reportTooltip => 'Signaler un problème avec cette épreuve';

  @override
  String get noScannedFileYet =>
      'Aucun fichier scanné pour cette soumission pour l\'instant.';

  @override
  String get openScannedPaper => 'Ouvrir l\'épreuve scannée';

  @override
  String get saveOffline => 'Enregistrer hors ligne';

  @override
  String get offlineSaved => 'Enregistré hors ligne';

  @override
  String offlineSaveError(String error) {
    return 'Impossible d\'enregistrer hors ligne : $error';
  }

  @override
  String examBoardLabel(String board) {
    return 'Jury d\'examen : $board';
  }

  @override
  String get watchAdForView => 'Regarder une pub pour +1 consultation';

  @override
  String get markingGuideTitle => 'Corrigé';

  @override
  String get markingGuideSubtitle =>
      'Rédigé par l\'instructeur + clé QCM interne';

  @override
  String get reportDownloadTitle => 'Accès au téléchargement';

  @override
  String get reportDownloadSubtitle =>
      'La consultation dans l\'application est gratuite. Débloquez une fois pour enregistrer une copie hors ligne';

  @override
  String unlockedForAmount(int amount) {
    return 'Débloqué pour $amount FCFA.';
  }

  @override
  String get unlockButton => 'Débloquer : 500 FCFA';

  @override
  String get alreadyUnlocked => 'Débloqué.';

  @override
  String get viewButton => 'Consulter';

  @override
  String get reportLockedTitle => 'Ce rapport nécessite un déblocage';

  @override
  String get reportLockedMessage =>
      'Les thèses de Master et de Doctorat nécessitent un paiement pour être consultées. Débloquez ci-dessous pour la lire.';

  @override
  String get unlockToDownloadHint =>
      'Débloquez ci-dessous pour enregistrer une copie hors ligne.';

  @override
  String get haveRedeemCode => 'Vous avez un code de réduction ?';

  @override
  String get redeemCodeHint => 'Code de réduction';

  @override
  String get mcqDisclaimer =>
      'Les réponses aux questions à choix multiples sont corrigées en interne par l\'équipe Spekooh, pas par l\'instructeur.';

  @override
  String get reportDialogTitle => 'Signaler un problème';

  @override
  String get reportWhatsWrong => 'Quel est le problème ?';

  @override
  String get reportDetailsOptional => 'Détails (facultatif)';

  @override
  String get cancelButton => 'Annuler';

  @override
  String get submitButton => 'Soumettre';

  @override
  String get contributeNudgeTitle => 'Aidez d\'autres étudiants';

  @override
  String get contributeNudgeBody =>
      'Si vous avez une ancienne épreuve ou un rapport académique, le soumettre avec précision et dès que possible aide d\'autres étudiants qui en ont besoin maintenant. Chaque contribution fait une vraie différence.';

  @override
  String get contributeNudgeCta => 'Contribuer maintenant';

  @override
  String get contributeNudgeDismiss => 'Plus tard';

  @override
  String get reasonWrongAnswers => 'Réponses incorrectes ou manquantes';

  @override
  String get reasonPoorQuality => 'Mauvaise qualité de scan / illisible';

  @override
  String get reasonWrongSubject => 'Mauvaise matière ou type d\'examen';

  @override
  String get reasonDuplicate => 'Doublon d\'une autre épreuve';

  @override
  String get reasonCopyright => 'Problème de droits d\'auteur';

  @override
  String get reasonOther => 'Autre';

  @override
  String get paywallEnterPhoneError =>
      'Entrez votre numéro MTN MoMo ou Orange Money.';

  @override
  String paywallSubscriptionFailed(String error) {
    return 'Échec de l\'abonnement : $error';
  }

  @override
  String get paywallYoureProTitle => 'Vous êtes Pro';

  @override
  String get paywallGetProTitle => 'Passer à Spekooh Pro';

  @override
  String paywallRenewsOn(String date) {
    return 'Renouvellement le $date.';
  }

  @override
  String get paywallDescription =>
      'Consultations d\'épreuves illimitées et une application sans publicité. Les corrigés restent toujours débloqués séparément.';

  @override
  String get paywallBenefitViews => 'Consultations d\'épreuves illimitées';

  @override
  String get paywallBenefitAds => 'Zéro publicité pendant vos révisions';

  @override
  String get paywallBenefitAlerts => 'Alertes de statut instructeur';

  @override
  String get spekoohProCaps => 'SPEKOOH PRO';

  @override
  String get momoOrangeLabel => 'NUMÉRO MTN MOMO OU ORANGE MONEY';

  @override
  String get payButton => 'Payer 500 FCFA';

  @override
  String get paywallDisclaimer =>
      'Marchand officiel Spekooh · nous ne demandons jamais votre code PIN · reçu + SMS sous 2 min';

  @override
  String pamphletSoldBy(String partner) {
    return 'Vendu par $partner';
  }

  @override
  String get escrowExplanation =>
      'Spekooh conserve votre paiement en séquestre. Vous recevrez un ticket QR à usage unique pour le récupérer à la librairie. Le paiement n\'est débloqué au partenaire qu\'une fois le ticket scanné.';

  @override
  String get pickupInStoreLabel => 'RETRAIT · EN BOUTIQUE';

  @override
  String payAndReserve(String amount) {
    return 'Payer et réserver : $amount FCFA';
  }

  @override
  String get processingLabel => 'Traitement en cours…';

  @override
  String get escrowFooterNote =>
      'Conservé en séquestre · débloqué au partenaire seulement après confirmation du retrait · 5 % de commission plateforme';

  @override
  String get pickupTicketReady => 'Ticket de retrait prêt';

  @override
  String showQrAtPartner(String partner) {
    return 'Montrez ce QR à $partner. Usage unique, expire dans 30 jours. Le paiement est débloqué au partenaire une fois scanné.';
  }

  @override
  String ticketRefLabel(String ref) {
    return 'Réf. du ticket : $ref…';
  }

  @override
  String get paymentFailedGeneric =>
      'Échec du paiement. Vérifiez votre connexion et réessayez.';

  @override
  String get paywallBlockedMessage =>
      'Limite quotidienne de consultations gratuites atteinte. Regardez une pub ou passez à Pro.';

  @override
  String get alreadyReportedMessage => 'Vous avez déjà signalé cette épreuve.';

  @override
  String get aiAssistantTitle => 'Assistant Spekooh';

  @override
  String get aiAssistantSubtitle =>
      'Explique des notions à partir de vraies épreuves';

  @override
  String get aiPromptExplainPhysics =>
      'Expliquer une notion difficile de Physique';

  @override
  String get aiPromptMathsQuestions =>
      'Donne-moi 5 questions d\'entraînement en Maths';

  @override
  String get aiPromptSummarizeGuide => 'Résume le corrigé de cette épreuve';

  @override
  String get aiAssistantInputHint =>
      'Posez une question sur un sujet ou une épreuve...';
}
