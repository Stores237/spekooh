"""
Owner request (2026-09-17): Integration Ops uploads the PDF for a Note the
same way it enters a Pamphlet's details -- both are admin-authored catalog
content a partner/ops relays, not user-submitted. Full CRUD, same grant
Reviewer already has for Note (see 0008_reviewer_notes_pamphlets_permissions.py).

Uses .add() rather than .set() -- 0011 already gave Integration Ops
pamphlets/pamphletorder/adminflagqueue permissions, and .set() here would
silently wipe those out instead of layering Note access on top.
"""

from django.db import migrations

NOTES_PERMISSIONS = {
    ("notes", "note"): ("view", "add", "change", "delete"),
}


def _add(apps, group_name, permission_map):
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
    group.permissions.add(*perms)


def add_permissions(apps, schema_editor):
    _add(apps, "Integration Ops", NOTES_PERMISSIONS)


def remove_permissions(apps, schema_editor):
    Group = apps.get_model("auth", "Group")
    Permission = apps.get_model("auth", "Permission")
    ContentType = apps.get_model("contenttypes", "ContentType")

    try:
        group = Group.objects.get(name="Integration Ops")
    except Group.DoesNotExist:
        return
    perms = []
    for (app_label, model), actions in NOTES_PERMISSIONS.items():
        try:
            content_type = ContentType.objects.get(app_label=app_label, model=model)
        except ContentType.DoesNotExist:
            continue
        for action in actions:
            try:
                perms.append(Permission.objects.get(content_type=content_type, codename=f"{action}_{model}"))
            except Permission.DoesNotExist:
                continue
    group.permissions.remove(*perms)


class Migration(migrations.Migration):
    dependencies = [
        ("accounts", "0011_seed_integration_ops_role"),
        ("notes", "0005_note_pdf_file"),
    ]

    operations = [
        migrations.RunPython(add_permissions, remove_permissions),
    ]
