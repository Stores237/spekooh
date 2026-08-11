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
from django.views.generic import RedirectView
from drf_spectacular.views import SpectacularAPIView, SpectacularSwaggerView

from apps.pamphlets.views import redeem_page

urlpatterns = [
    path('', RedirectView.as_view(url='api/docs/', permanent=False)),
    path('admin/', admin.site.urls),
    path('redeem/<str:token>/', redeem_page, name='pamphlet-redeem'),
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
    path('api/schema/', SpectacularAPIView.as_view(), name='schema'),
    path('api/docs/', SpectacularSwaggerView.as_view(url_name='schema'), name='swagger-ui'),
]

if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
