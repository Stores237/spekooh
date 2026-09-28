from django.db import migrations


class Migration(migrations.Migration):
    dependencies = [
        ("xp", "0001_initial"),
    ]

    operations = [
        migrations.AlterModelOptions(
            name="xpledgerentry",
            options={
                "ordering": ["-created_at"],
                "verbose_name": "points ledger entry",
                "verbose_name_plural": "points ledger entries",
            },
        ),
    ]
