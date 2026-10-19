"""
Owner request (2026-09-29): Notes now picks its Subject from a real dropdown
(apps.notes 0008) with a '+' to add one that isn't listed yet, same as a
contributor already can when submitting a paper. Support authors notes
(0016) but had no permission on apps.papers.Subject at all, so that '+'
would silently not appear for them. Adds only add_subject — not
view/change/delete — matching exactly what the '+' popup needs and nothing
wider than that.

Uses .add() rather than .set(), same reason as 0016: don't wipe Support's
existing permissions.
"""

from django.apps import apps as django_apps
from django.contrib.auth.management import create_permissions
from django.db import migrations

GROUP_NAME = "Support"
CODENAMES = ("add_subject",)


def add_permissions(apps, schema_editor):
    papers_config = django_apps.get_app_config("papers")
    papers_config.models_module = True
    create_permissions(papers_config, apps=apps, verbosity=0)
    papers_config.models_module = None

    Group = apps.get_model("auth", "Group")
    Permission = apps.get_model("auth", "Permission")

    group, _ = Group.objects.get_or_create(name=GROUP_NAME)
    perms = Permission.objects.filter(content_type__app_label="papers", codename__in=CODENAMES)
    group.permissions.add(*perms)


def remove_permissions(apps, schema_editor):
    Group = apps.get_model("auth", "Group")
    Permission = apps.get_model("auth", "Permission")

    group = Group.objects.filter(name=GROUP_NAME).first()
    if group is None:
        return
    perms = Permission.objects.filter(content_type__app_label="papers", codename__in=CODENAMES)
    group.permissions.remove(*perms)


class Migration(migrations.Migration):
    dependencies = [
        ("accounts", "0017_termsacceptance"),
        ("papers", "0020_fix_em_dash_in_category_subtitles"),
    ]

    operations = [
        migrations.RunPython(add_permissions, remove_permissions),
    ]
