"""
Owner request (2026-09-17): RedeemVerification is now registered read-only
in admin (RedeemVerificationAdmin) as an audit trail for every handover
code ever issued, including who issued a SUPPORT override -- Integration
Ops needs view access to actually reach that page, since Django's default
admin gating (has_view_permission) checks for a real view/change
permission independent of RedeemVerificationAdmin's has_*_permission
overrides, which only block add/change/delete, not the changelist itself.

Uses .add() rather than .set() -- same reason as 0012: replacing wholesale
here would silently wipe out the pamphlets/pamphletorder/adminflagqueue/
notes permissions already granted in 0011/0012.
"""

from django.db import migrations

REDEEM_VERIFICATION_PERMISSIONS = {
    ("pamphlets", "redeemverification"): ("view",),
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
    _add(apps, "Integration Ops", REDEEM_VERIFICATION_PERMISSIONS)


def remove_permissions(apps, schema_editor):
    Group = apps.get_model("auth", "Group")
    Permission = apps.get_model("auth", "Permission")
    ContentType = apps.get_model("contenttypes", "ContentType")

    try:
        group = Group.objects.get(name="Integration Ops")
    except Group.DoesNotExist:
        return
    perms = []
    for (app_label, model), actions in REDEEM_VERIFICATION_PERMISSIONS.items():
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
        ("accounts", "0012_integration_ops_notes_permissions"),
        ("pamphlets", "0012_redeemverification_issued_by_and_more"),
    ]

    operations = [
        migrations.RunPython(add_permissions, remove_permissions),
    ]
