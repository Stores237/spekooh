"""
Seeds the exam-taxonomy lookup tables, ported 1:1 from the Flutter mock
taxonomy at app/lib/data/mock/mock_taxonomy.dart so the backend and the
already-built frontend agree on the same categories/exam types/subjects.
"""

from django.db import migrations

CATEGORIES = [
    dict(key="primary", title="Primary", subtitle="FSLC · CEP · Common Entrance",
         icon_name="child_care_outlined", tint="blue", requires_system=False, sort_order=0),
    dict(key="secondary", title="Secondary", subtitle="BEPC · Probatoire · Bac · O/A Level",
         icon_name="school_outlined", tint="amber", requires_system=True, sort_order=1),
    dict(key="university", title="University", subtitle="Semester exams · Resits — State & Private",
         icon_name="account_balance_outlined", tint="blue", requires_system=True, sort_order=2),
    dict(key="tertiary", title="Tertiary", subtitle="HND · BTS · AQP/CQP/DQP",
         icon_name="business_outlined", tint="green", requires_system=False, sort_order=3),
    dict(key="concours", title="Concours", subtitle="ENAM · ENSP · UCAC · ESSEC & more",
         icon_name="emoji_events_outlined", tint="purple", requires_system=False, sort_order=4),
    dict(key="reports", title="Academic Reports", subtitle="Internship · Mémoire · Thèse — no marking guide",
         icon_name="menu_book_outlined", tint="red", requires_system=False, sort_order=5),
]

# (category_key, system_or_None, name, subtitle, mock_variant_label, tracks, subject_language, badge_tone)
EXAM_TYPES = [
    ("primary", None, "FSLC", "Anglophone", "", [], "en", "neutral"),
    ("primary", None, "Common Entrance", "Anglophone", "", [], "en", "neutral"),
    ("primary", None, "CEP", "Francophone", "", [], "fr", "amber"),
    ("primary", None, "Concours d’Entrée en 6ème", "Francophone", "", [], "fr", "amber"),

    ("secondary", "francophone", "BEPC", "+ BEPC Blanc · Général/Technique", "BEPC Blanc",
     ["Général", "Technique"], "fr", "amber"),
    ("secondary", "francophone", "Probatoire", "+ Probatoire Blanc · Général/Technique", "Probatoire Blanc",
     ["Général", "Technique"], "fr", "amber"),
    ("secondary", "francophone", "Baccalauréat", "+ Bac Blanc · Général/Technique", "Bac Blanc",
     ["Général", "Technique"], "fr", "amber"),
    ("secondary", "anglophone", "O Level", "+ O Level Mock · General only", "O Level Mock", [], "en", "blue"),
    ("secondary", "anglophone", "A Level", "+ A Level Mock · Sci/Arts/Comm/Tech", "A Level Mock",
     ["Science", "Arts", "Commercial", "Technical"], "en", "blue"),

    ("university", "francophone", "Examen Semestre 1", "1er semestre, tous niveaux",
     "", ["L1", "L2", "L3", "M1", "M2"], "fr", "amber"),
    ("university", "francophone", "Examen Semestre 2", "2nd semestre, tous niveaux",
     "", ["L1", "L2", "L3", "M1", "M2"], "fr", "amber"),
    ("university", "francophone", "Rattrapage", "Session de rattrapage",
     "", ["L1", "L2", "L3", "M1", "M2"], "fr", "amber"),
    ("university", "anglophone", "Semester 1 Exam", "1st semester, all levels",
     "", ["L1", "L2", "L3", "M1", "M2"], "en", "blue"),
    ("university", "anglophone", "Semester 2 Exam", "2nd semester, all levels",
     "", ["L1", "L2", "L3", "M1", "M2"], "en", "blue"),
    ("university", "anglophone", "Resit / Makeup", "Resit sittings",
     "", ["L1", "L2", "L3", "M1", "M2"], "en", "blue"),

    ("tertiary", None, "HND", "Anglophone", "", [], "en", "blue"),
    ("tertiary", None, "BTS", "Francophone", "", [], "fr", "amber"),
    ("tertiary", None, "AQP", "Vocational training center", "", [], "en", "green"),
    ("tertiary", None, "CQP", "Vocational training center", "", [], "en", "green"),
    ("tertiary", None, "DQP", "Vocational training center", "", [], "en", "green"),

    ("concours", None, "ENAM", "École Nat. d’Administration", "", [], "en", "neutral"),
    ("concours", None, "ENSP", "Polytechnique Yaoundé/Bamenda", "", [], "en", "neutral"),
    ("concours", None, "ESSEC", "Douala / Garoua", "", [], "en", "neutral"),
    ("concours", None, "UCAC", "Univ. Catholique d’Afrique Centrale", "", [], "en", "neutral"),
    ("concours", None, "IUT", "Douala, Ngaoundéré & more", "", [], "en", "neutral"),
    ("concours", None, "FMSB", "Médecine / Pharmacie", "", [], "en", "neutral"),
    ("concours", None, "ENS", "Yaoundé / Bambili / Maroua", "", [], "en", "neutral"),
    ("concours", None, "IAI", "Institut Africain d’Informatique", "", [], "en", "neutral"),
    ("concours", None, "ESSTIC", "Info & Communication", "", [], "en", "neutral"),
    ("concours", None, "EMIA", "Officer entrance", "", [], "en", "neutral"),
]

SUBJECTS_EN = [
    ("accounting", "Accounting", "amber", "description_outlined", "0505"),
    ("biology", "Biology", "green", "eco_outlined", "0510"),
    ("chemistry", "Chemistry", "purple", "science_outlined", "0515"),
    ("computer_science", "Computer science", "blue", "memory_outlined", "0595"),
    ("economics", "Economics", "amber", "trending_up_outlined", "0525"),
    ("physics", "Physics", "blue", "bolt_outlined", "0580"),
]

SUBJECTS_FR = [
    ("maths", "Mathématiques", "blue", "functions", "MAT"),
    ("philo", "Philosophie", "purple", "menu_book_outlined", "PHI"),
    ("hist_geo", "Histoire-Géo", "amber", "public_outlined", "HGE"),
    ("svt", "SVT", "green", "eco_outlined", "SVT"),
    ("physique_chimie", "Physique-Chimie", "blue", "bolt_outlined", "PC"),
    ("anglais", "Anglais", "amber", "language_outlined", "ANG"),
]


def seed(apps, schema_editor):
    ExamCategory = apps.get_model("papers", "ExamCategory")
    ExamType = apps.get_model("papers", "ExamType")
    Subject = apps.get_model("papers", "Subject")

    categories_by_key = {}
    for data in CATEGORIES:
        categories_by_key[data["key"]] = ExamCategory.objects.create(**data)

    for i, (cat_key, system, name, subtitle, mock_variant, tracks, lang, badge_tone) in enumerate(EXAM_TYPES):
        ExamType.objects.create(
            category=categories_by_key[cat_key],
            system=system,
            name=name,
            subtitle=subtitle,
            mock_variant_label=mock_variant,
            tracks=tracks,
            subject_language=lang,
            badge_tone=badge_tone,
            sort_order=i,
        )

    for key, title, tint, icon_name, code in SUBJECTS_EN:
        Subject.objects.create(key=key, title=title, tint=tint, icon_name=icon_name, code=code, language="en")

    for key, title, tint, icon_name, code in SUBJECTS_FR:
        Subject.objects.create(key=key, title=title, tint=tint, icon_name=icon_name, code=code, language="fr")


def unseed(apps, schema_editor):
    apps.get_model("papers", "ExamType").objects.all().delete()
    apps.get_model("papers", "ExamCategory").objects.all().delete()
    apps.get_model("papers", "Subject").objects.all().delete()


class Migration(migrations.Migration):
    dependencies = [("papers", "0001_initial")]
    operations = [migrations.RunPython(seed, unseed)]
