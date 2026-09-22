"""
URL configuration for config project.

The `urlpatterns` list routes URLs to views. For more information please see:
    https://docs.djangoproject.com/en/5.2/topics/http/urls/
Examples:
Function views
    1. Add an import:  from my_app import views
    2. Add a URL to urlpatterns:  path('', views.home, name='home')
Class-based views
    1. Add an import:  from other_app.views import Home
    2. Add a URL to urlpatterns:  path('', Home.as_view(), name='home')
Including another URLconf
    1. Import the include() function: from django.urls import include, path
    2. Add a URL to urlpatterns:  path('blog/', include('blog.urls'))
"""
from django.conf import settings
from django.conf.urls.static import static
from django.contrib import admin
from django.urls import include, path
from drf_spectacular.views import SpectacularAPIView, SpectacularSwaggerView

from apps.accounts.views import staff_set_password_view
from apps.core.views import (
    healthz,
    marketing_home,
    privacy_policy_page,
    run_task,
    terms_of_service_page,
)
from apps.pamphlets.views import redeem_page

urlpatterns = [
    # Public marketing site (2026-09-18) — was a bare redirect to
    # api/docs/; that's still reachable directly for API consumers.
    path('', marketing_home, name='marketing-home'),
    path('admin/', admin.site.urls),
    # Plain HTML, not under api/auth/ — same reasoning as redeem/<token>/
    # below: whoever opens this link isn't logged in yet, so it's not an
    # API endpoint. See StaffAccountAdmin (apps.accounts.admin) for where
    # the link is generated and emailed.
    path('staff/set-password/<str:uidb64>/<str:token>/', staff_set_password_view, name='staff-set-password'),
    path('healthz/', healthz, name='healthz'),
    path('internal/tasks/<str:name>/', run_task, name='internal-task'),
    path('redeem/<str:token>/', redeem_page, name='pamphlet-redeem'),
    # Real public URLs (2026-09-14, owner request) — Play Console's Store
    # Listing and App Store Connect both require one for the Privacy
    # Policy specifically; previously these only existed as in-app Flutter
    # screens with no URL at all. See apps.core.legal_content's docstring.
    path('legal/privacy-policy/', privacy_policy_page, name='privacy-policy'),
    path('legal/terms-of-service/', terms_of_service_page, name='terms-of-service'),
    path('api/auth/', include('apps.accounts.urls')),
    path('api/papers/', include('apps.papers.urls')),
    path('api/credits/', include('apps.credits.urls')),
    path('api/payments/', include('apps.payments.urls')),
    path('api/pamphlets/', include('apps.pamphlets.urls')),
    path('api/admin-queue/', include('apps.admin_queue.urls')),
    path('api/instructors/', include('apps.instructors.urls')),
    path('api/notes/', include('apps.notes.urls')),
    path('api/forum/', include('apps.forum.urls')),
    path('api/quizzes/', include('apps.quizzes.urls')),
    path('api/notifications/', include('apps.notifications.urls')),
    path('api/ai/', include('apps.ai.urls')),
    path('api/promotions/', include('apps.promotions.urls')),
    path('api/xp/', include('apps.xp.urls')),
    path('api/schema/', SpectacularAPIView.as_view(), name='schema'),
    path('api/docs/', SpectacularSwaggerView.as_view(url_name='schema'), name='swagger-ui'),
]

if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
