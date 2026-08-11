"""Seeds quizzes matching the Flutter mock data, plus real questions for two of them."""

from django.db import migrations

QUIZZES = [
    # (title, subtitle, suggested_time_seconds, is_daily_challenge, played_count)
    ("Group VII the Halogens Quiz", "Daily challenge", 480, True, 1308),
    ("Biology quiz", "18 topics", 480, False, 5564),
    ("Chemistry quizzes", "22 topics", 480, False, 5564),
    ("Geography quizzes", "2 topics", 480, False, 5564),
    ("Computer science", "1 topics", 480, False, 5564),
]

BIOLOGY_QUESTIONS = [
    ("Which organelle is the site of aerobic respiration?", ["Nucleus", "Mitochondrion", "Ribosome", "Golgi apparatus"], 1),
    ("Enzymes are primarily made of:", ["Lipids", "Carbohydrates", "Proteins", "Nucleic acids"], 2),
    ("What is the term for an enzyme's preferred substrate temperature range?", ["Optimum temperature", "Denaturation point", "Activation energy", "pH range"], 0),
]


def seed(apps, schema_editor):
    Quiz = apps.get_model("quizzes", "Quiz")
    QuizQuestion = apps.get_model("quizzes", "QuizQuestion")

    quizzes_by_title = {}
    for title, subtitle, suggested_time, is_daily, played_count in QUIZZES:
        quizzes_by_title[title] = Quiz.objects.create(
            title=title,
            subtitle=subtitle,
            suggested_time_seconds=suggested_time,
            is_daily_challenge=is_daily,
            played_count=played_count,
        )

    biology_quiz = quizzes_by_title["Biology quiz"]
    for i, (text, choices, correct_index) in enumerate(BIOLOGY_QUESTIONS):
        QuizQuestion.objects.create(
            quiz=biology_quiz, text=text, choices=choices, correct_choice_index=correct_index, order=i
        )


def unseed(apps, schema_editor):
    apps.get_model("quizzes", "Quiz").objects.all().delete()


class Migration(migrations.Migration):
    dependencies = [("quizzes", "0001_initial")]
    operations = [migrations.RunPython(seed, unseed)]
