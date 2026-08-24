from rest_framework.permissions import BasePermission

from .models import AccountType


class IsAuthenticatedNotGuest(BasePermission):
    """Like IsAuthenticated, but rejects guest accounts.

    A guest identity (see UserManager.create_guest / AuthSession.mintGuestAccessToken
    on the app side) is minted only to own the single paper/report submission it's
    created for. Every other authenticated action in the app requires a real
    account — this is the server-side backstop for that, since a guest's JWT is
    otherwise indistinguishable in shape from a registered user's.
    """

    def has_permission(self, request, view):
        user = request.user
        return bool(user and user.is_authenticated and user.account_type != AccountType.GUEST)
