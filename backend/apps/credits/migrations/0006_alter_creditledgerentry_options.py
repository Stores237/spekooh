from django.db import migrations


class Migration(migrations.Migration):
    dependencies = [
        ("credits", "0005_referralbonusconfig"),
    ]

    operations = [
        migrations.AlterModelOptions(
            name="creditledgerentry",
            options={
                "ordering": ["-created_at"],
                "verbose_name_plural": "credit ledger entries (retired)",
            },
        ),
    ]
