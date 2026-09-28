/// Whether the signed-in account still has to accept the current Terms of
/// Service, and which version it would be accepting. The server decides (see
/// apps.accounts.services.needs_terms_acceptance): the app never compares
/// version strings itself, and sends [version] back on accept so an
/// acceptance is only ever recorded against the text the user was shown.
class TermsStatus {
  const TermsStatus({required this.needsAcceptance, required this.version});

  /// Nothing to accept (already accepted, a guest, or not known yet).
  const TermsStatus.accepted()
      : needsAcceptance = false,
        version = '';

  final bool needsAcceptance;
  final String version;
}
