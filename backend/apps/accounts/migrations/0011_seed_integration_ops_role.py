"""
Seeds "Integration Ops" as a new Django Group (owner decision, 2026-09-16):
the team that onboards partner bookshops and runs the pamphlet
pickup/escrow operation day to day. Distinct from Reviewer (paper/pamphlet
*content* moderation, see 0008) -- this is the business/partnerships
function, so it gets its own group rather than more permissions bolted
onto Reviewer.

Scope: full CRUD on Pamphlet (create/retire pamphlets, and now
display_order for shop ranking); add/change (no delete) on
PartnerBookshop, same cascade-risk rule Reviewer already follows
(PartnerBookshop.pamphlets is on_delete=CASCADE); view/change on
PamphletOrder for the new "Resolve dispute" admin action; view/change on
AdminFlagQueue so they can work pamphlet dispute/expiry tickets in that
existing screen (see apps.admin_queue.admin).
"""

from django.db import migrations

INTEGRATION_OPS_PERMISSIONS = {
    ("pamphlets", "pamphlet"): ("view", "add", "change", "delete"),
    ("pamphlets", "partnerbookshop"): ("view", "add", "change"),
    ("pamphlets", "pamphletorder"): ("view", "change"),
    ("admin_queue", "adminflagqueue"): ("view", "change"),
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


def seed_role(apps, schema_editor):
    _assign(apps, "Integration Ops", INTEGRATION_OPS_PERMISSIONS)


def remove_role(apps, schema_editor):
    Group = apps.get_model("auth", "Group")
    Group.objects.filter(name="Integration Ops").delete()


class Migration(migrations.Migration):
    dependencies = [
        ("accounts", "0010_user_phone_verified_at"),
        ("pamphlets", "0007_alter_pamphlet_options_pamphlet_display_order"),
        ("admin_queue", "0003_alter_adminflagqueue_category"),
    ]

    operations = [
        migrations.RunPython(seed_role, remove_role),
    ]
