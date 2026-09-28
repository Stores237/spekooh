"""
Owner request (2026-09-28): the Support team creates and updates study notes
in the admin. Support was seeded read-only (0004); this widens it for Note
and nothing else -- view/add/change, deliberately NOT delete (a note a
student is reading should be unpublished by an owner/Reviewer/Integration
Ops decision, not removed by a support agent).

Uses .add() rather than .set(): .set() would wipe the read-only lookup
permissions 0004 gave Support instead of layering Note access on top.

Forces permission creation for the notes app first (same reason as 0004):
on a fresh database this migration can run before auth's post_migrate
creates Note's permissions, and a silent "permission not found" skip would
leave Support with no notes access at all.
"""

from django.apps import apps as django_apps
from django.contrib.auth.management import create_permissions
from django.db import migrations

GROUP_NAME = "Support"
CODENAMES = ("view_note", "add_note", "change_note")


def add_permissions(apps, schema_editor):
    notes_config = django_apps.get_app_config("notes")
    notes_config.models_module = True
    create_permissions(notes_config, apps=apps, verbosity=0)
    notes_config.models_module = None

    Group = apps.get_model("auth", "Group")
    Permission = apps.get_model("auth", "Permission")

    group, _ = Group.objects.get_or_create(name=GROUP_NAME)
    perms = Permission.objects.filter(content_type__app_label="notes", codename__in=CODENAMES)
    group.permissions.add(*perms)


def remove_permissions(apps, schema_editor):
    Group = apps.get_model("auth", "Group")
    Permission = apps.get_model("auth", "Permission")

    group = Group.objects.filter(name=GROUP_NAME).first()
    if group is None:
        return
    perms = Permission.objects.filter(content_type__app_label="notes", codename__in=CODENAMES)
    group.permissions.remove(*perms)


class Migration(migrations.Migration):
    dependencies = [
        ("accounts", "0015_seed_it_helpdesk_role"),
        ("notes", "0006_alter_note_pdf_file"),
    ]

    operations = [
        migrations.RunPython(add_permissions, remove_permissions),
    ]
