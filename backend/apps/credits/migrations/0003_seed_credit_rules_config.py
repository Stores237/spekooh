"""Seeds the illustrative starting numbers from spec §5.1/§5.2 — ops-editable via admin thereafter."""

from django.db import migrations

QUESTION_TYPE_RATES = [
    ("SHORT_ANSWER", 200),
    ("CALCULATION", 275),
    ("ESSAY", 400),
]

LEVEL_MULTIPLIERS = [
    ("BASIC", "1.0"),
    ("O_LEVEL", "1.2"),
    ("A_LEVEL", "1.5"),
    ("UNIVERSITY", "1.8"),
]

# (min_submissions, value_percent, expiry_days)
REDEEM_CODE_TIERS = [
    (0, 5, 7),
    (5, 10, 14),
    (15, 15, 21),
    (24, 20, 30),
]


def seed(apps, schema_editor):
    QuestionTypeRate = apps.get_model("credits", "QuestionTypeRate")
    LevelComplexityMultiplier = apps.get_model("credits", "LevelComplexityMultiplier")
    RedeemCodeTierConfig = apps.get_model("credits", "RedeemCodeTierConfig")
    ContributorBonusConfig = apps.get_model("credits", "ContributorBonusConfig")

    for question_type, rate in QUESTION_TYPE_RATES:
        QuestionTypeRate.objects.create(question_type=question_type, base_rate_xaf=rate)

    for level, multiplier in LEVEL_MULTIPLIERS:
        LevelComplexityMultiplier.objects.create(level=level, multiplier=multiplier)

    for min_submissions, value_percent, expiry_days in REDEEM_CODE_TIERS:
        RedeemCodeTierConfig.objects.create(
            min_submissions=min_submissions, value_percent=value_percent, expiry_days=expiry_days
        )

    ContributorBonusConfig.objects.create(amount=50)


def unseed(apps, schema_editor):
    apps.get_model("credits", "QuestionTypeRate").objects.all().delete()
    apps.get_model("credits", "LevelComplexityMultiplier").objects.all().delete()
    apps.get_model("credits", "RedeemCodeTierConfig").objects.all().delete()
    apps.get_model("credits", "ContributorBonusConfig").objects.all().delete()


class Migration(migrations.Migration):
    dependencies = [("credits", "0002_contributorbonusconfig_levelcomplexitymultiplier_and_more")]
    operations = [migrations.RunPython(seed, unseed)]
