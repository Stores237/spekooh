"""
Owner decision (2026-09-01): Notes and Pamphlets are catalog content that
only a superuser could create/edit until now — Reviewer (the Review Team)
gets that access too, the same team that already moderates paper
submissions and marking guides (see 0004_seed_admin_roles.py).

Note/Pamphlet get full add/change/delete — they're the actual "submitted"
catalog items the owner was doing by hand. PartnerBookshop (the business
relationship a Pamphlet belongs to) stays add/change only, no delete:
Pamphlet.partner is on_delete=CASCADE, so deleting a bookshop wipes out
every pamphlet under it — a business decision, not a content-moderation
one, kept at the Owner tier.

Uses .add() rather than replacing the group's permission set outright
(like 0004 does) — Reviewer already holds papers/admin_queue/instructors
permissions from that migration, and replacing wholesale here would
silently wipe those out instead of layering on top of them.
"""

from django.db import migrations

NEW_REVIEWER_PERMISSIONS = {
    ("notes", "note"): ("view", "add", "change", "delete"),
    ("pamphlets", "pamphlet"): ("view", "add", "change", "delete"),
    ("pamphlets", "partnerbookshop"): ("view", "add", "change"),
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
    _add(apps, "Reviewer", NEW_REVIEWER_PERMISSIONS)


def remove_permissions(apps, schema_editor):
    Group = apps.get_model("auth", "Group")
    Permission = apps.get_model("auth", "Permission")
    ContentType = apps.get_model("contenttypes", "ContentType")

    try:
        group = Group.objects.get(name="Reviewer")
    except Group.DoesNotExist:
        return
    perms = []
    for (app_label, model), actions in NEW_REVIEWER_PERMISSIONS.items():
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
        ("accounts", "0007_user_avatar"),
        ("notes", "0004_backfill_subject_and_level"),
        ("pamphlets", "0005_pamphlet_academic_level_pamphlet_subject_title"),
    ]

    operations = [
        migrations.RunPython(add_permissions, remove_permissions),
    ]
