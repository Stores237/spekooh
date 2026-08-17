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
}
