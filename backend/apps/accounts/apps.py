from django.apps import AppConfig


class AccountsConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'apps.accounts'

    def ready(self):
        # Owner report (2026-09-22): "Groups" is Django's own generic term
        # for what this app actually uses as staff roles (Reviewer, Support,
        # Integration Ops, IT Helpdesk) — confusing for anyone not already
        # fluent in Django admin. Relabeling the model here changes every
        # place its name is rendered (sidebar, page titles, breadcrumbs,
        # success messages) without forking django.contrib.auth — the
        # standard, documented way to rename a built-in admin model.
        from django.contrib.auth.models import Group

        Group._meta.verbose_name = "Staff role"
        Group._meta.verbose_name_plural = "Staff roles"
