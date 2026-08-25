"""
Seeds two Django Groups as the app's non-Owner admin roles (Owner = a real
superuser, which already bypasses every permission check — no group needed
for that tier). Modeled on the "GitHub-style" role discussion: Reviewer is
the Review Team from the spec (verifies/moderates submissions, marking
guides), Support is a read-only lookup role for handling support tickets
without any moderation or financial write access.

Data migration, not a fixture, so these roles exist consistently in every
environment (dev/staging/prod) the moment this migration runs, without
anyone having to click through the admin to recreate them.
"""

from django.apps import apps as django_apps
from django.contrib.auth.management import create_permissions
from django.db import migrations

REVIEWER_PERMISSIONS = {
    ("papers", "papersubmission"): ("view", "change"),
    ("papers", "academicreportsubmission"): ("view", "change"),
    ("papers", "paperflag"): ("view", "change"),
    # Review Team authors MCQ answer keys in-house (spec §2.1) — needs add,
    # not just view/change of existing ones.
    ("papers", "mcqanswerkey"): ("view", "add", "change"),
    ("papers", "publishedguide"): ("view", "change"),
    ("admin_queue", "adminflagqueue"): ("view", "change"),
    ("instructors", "instructorrequest"): ("view", "change"),
    ("instructors", "instructormarkingguide"): ("view", "change"),
}

SUPPORT_PERMISSIONS = {
    # User is view-only everywhere regardless of role — see UserAdmin's own
    # field-level redaction for the name-only rule that applies on top.
    ("accounts", "user"): ("view",),
    ("papers", "papersubmission"): ("view",),
    ("papers", "academicreportsubmission"): ("view",),
    ("papers", "paperflag"): ("view",),
    ("pamphlets", "pamphletorder"): ("view",),
    ("payments", "paymenttransaction"): ("view",),
    ("payments", "subscription"): ("view",),
    ("payments", "paperunlock"): ("view",),
}


def _assign(apps, group_name, permission_map):
    Group = apps.get_model("auth", "Group")
    Permission = apps.get_model("auth", "Permission")
    ContentType = apps.get_model("contenttypes", "ContentType")

    group, _ = Group.objects.get_or_create(name=group_name)
    perms = []
    for (app_label, model), actions in permission_map.items():
        try:
            content_type = ContentType.objects.get(app_label=app_label, model=model)
        except ContentType.DoesNotExist:
            continue
        for action in actions:
            try:
                perms.append(Permission.objects.get(content_type=content_type, codename=f"{action}_{model}"))
            except Permission.DoesNotExist:
                continue
    group.permissions.set(perms)


def seed_roles(apps, schema_editor):
    # On a fresh DB, every migration in this run (including the ones that
    # introduce the models above) applies before auth's post_migrate signal
    # creates their permissions — without this, Permission.objects.get()
    # below would find nothing on a clean install. Forcing it here makes
    # this migration correct regardless of run order.
    for app_config in django_apps.get_app_configs():
        app_config.models_module = True
        create_permissions(app_config, apps=apps, verbosity=0)
        app_config.models_module = None

    _assign(apps, "Reviewer", REVIEWER_PERMISSIONS)
    _assign(apps, "Support", SUPPORT_PERMISSIONS)


def remove_roles(apps, schema_editor):
    Group = apps.get_model("auth", "Group")
    Group.objects.filter(name__in=["Reviewer", "Support"]).delete()


class Migration(migrations.Migration):
    dependencies = [
        ("accounts", "0003_user_terms_accepted_at"),
        ("papers", "0014_academicreportsubmission"),
        ("admin_queue", "0003_alter_adminflagqueue_category"),
        ("instructors", "0001_initial"),
        ("payments", "0001_initial"),
        ("pamphlets", "0003_alter_pamphlet_options_pamphlet_is_featured"),
    ]

    operations = [
        migrations.RunPython(seed_roles, remove_roles),
    ]
