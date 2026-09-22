"""
Seeds "IT Helpdesk" as a new Django Group (owner request, 2026-09-22): the
team that creates and manages staff logins day to day, via
apps.accounts.admin.StaffAccountAdmin — distinct from Reviewer/Support/
Integration Ops, which are content/ops roles this group never touches.

Unlike Reviewer/Support/Integration Ops (0004/0011), this group carries no
Django Permission objects at all: StaffAccountAdmin gates every action with
a hardcoded superuser-or-this-group check
(apps.accounts.admin.StaffAccountAdmin._is_authorized), the same
defense-in-depth pattern already used for the pamphlet support-override
action, rather than the generic permission system. The group only needs to
exist so membership in it means something.
"""

from django.db import migrations

GROUP_NAME = "IT Helpdesk"


def seed_role(apps, schema_editor):
    Group = apps.get_model("auth", "Group")
    Group.objects.get_or_create(name=GROUP_NAME)


def remove_role(apps, schema_editor):
    Group = apps.get_model("auth", "Group")
    Group.objects.filter(name=GROUP_NAME).delete()


class Migration(migrations.Migration):
    dependencies = [
        ("accounts", "0014_staff_account_proxy"),
    ]

    operations = [
        migrations.RunPython(seed_role, remove_role),
    ]
