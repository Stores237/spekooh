# Spekooh — Exam Paper Taxonomy (Draft v1)

This is the foundational taxonomy for "Type of Exam Paper" across both the Anglophone and
Francophone systems, plus technical/vocational and competitive-entrance tracks. This is the
piece that generalizes beyond Kawlo's GCE-only structure.

---

## 1. Primary Exams

| Anglophone | Francophone |
|---|---|
| First School Leaving Certificate (FSLC) | Certificat d'Études Primaires (CEP) |
| Common Entrance (into Form 1 / Secondary) | Concours d'Entrée en 6ème |

- **Decided:** official only — no mock/blanc variant for Primary exams.
- No track/section split (general only).

---

## 2. Secondary Exams

### 2a. Francophone track
| Exam | Mock variant | Sections |
|---|---|---|
| BEPC | BEPC Blanc | Général / Technique |
| Probatoire | Probatoire Blanc | Général / Technique |
| Baccalauréat (Bac) | Bac Blanc | Général / Technique |

### 2b. Anglophone track
| Exam | Mock variant | Sections |
|---|---|---|
| GCE Ordinary Level (O Level) | O Level Mock | General only |
| GCE Advanced Level (A Level) | A Level Mock | Science / Arts / Commercial / Technical |

**Note:** Francophone Bac and Anglophone A Level are both split by Général/Technique or
Science/Arts/Commercial/Technical — worth normalizing these into one shared `track` field
in the data model (see Section 6) rather than treating them as separate schemas per system.

---

## 3. University / Tertiary Exams

### 3a. In-course university exams (per semester, not a "final national" exam)
| French-system naming | Notes |
|---|---|
| CA (Contrôle Continu) | Continuous assessment |
| CC | Francophone term for continuous assessment |
| Harmonisé CA | Standardized CA used by some schools across departments |
| Semestre 1 (S1) exam | |
| Semestre 2 (S2) exam | |

- **Out of v1 scope.** These are institution/course-level, not centrally set/verified like
  national exams, so they're excluded for now.

### 3b. National official tertiary exams (technical/vocational, degree-granting)
| Anglophone | Francophone |
|---|---|
| HND (Higher National Diploma) | BTS (Brevet de Technicien Supérieur) |

### 3c. National official vocational-training-center exams
| Level | Full name |
|---|---|
| AQP | Attestation de Qualification Professionnelle |
| CQP | Certificat de Qualification Professionnelle |
| DQP | Diplôme de Qualification Professionnelle |

---

## 4. Concours des Grandes Écoles (competitive entrance exams)

Your list, cleaned up and expanded with commonly-referenced Cameroonian grandes écoles.
Confirmed: UCCAC → UCAC.

| Acronym | Full name |
|---|---|
| ENSP (ENSPY / ENSPB) | École Nationale Supérieure Polytechnique (Yaoundé / Bamenda — NAHPI) |
| ENAM | École Nationale d'Administration et de Magistrature |
| ESSEC | École Supérieure des Sciences Économiques et Commerciales (Douala / Garoua) |
| IUT | Institut Universitaire de Technologie (Douala, Ngaoundéré, Bandjoun, etc. — multiple campuses) |
| UCAC | Université Catholique d'Afrique Centrale |
| IUC | Institut Universitaire de la Côte |
| IUG | Institut Universitaire du Golfe de Guinée |
| Saint Jérôme | Institut Catholique Saint Jérôme, Douala |
| ENS | École Normale Supérieure (Yaoundé / Bambili / Maroua) |
| ENSET | École Normale Supérieure d'Enseignement Technique |
| ENSTP | École Nationale Supérieure des Travaux Publics |
| ENSPT | École Nationale Supérieure des Postes et Télécommunications |
| IRIC | Institut des Relations Internationales du Cameroun |
| IFORD | Institut de Formation et de Recherche Démographiques |
| FMSB (and equivalents) | Faculté de Médecine et des Sciences Biomédicales (Medicine/Pharmacy/Dentistry/Nursing entrance) |
| EGCIM / FGI | École de Génie Chimique et des Industries Minérales |
| EAMAU | École Africaine et Malgache d'Architecture et d'Urbanisme |
| ESSTIC | École Supérieure des Sciences et Techniques de l'Information et de la Communication |
| EMIA | École Militaire Interarmées (military officer entrance) |
| NASPW | National Advanced School of Public Works (Buea) |
| IAI | Institut Africain d'Informatique (inter-state school, Cameroon representation) |
| ENIEG | École Normale d'Instituteurs de l'Enseignement Général |
| ENIET | École Normale d'Instituteurs de l'Enseignement Technique |
| INJS | Institut National de la Jeunesse et des Sports |
| EAMAC / ASECNA | École Africaine et Malgache de l'Aviation Civile |
| IPD-AC | Institut Panafricain pour le Développement en Afrique Centrale (Douala) |
| Siantou | Institut Siantou Supérieur (Yaoundé) |

**Decided:** curated set for v1 — the list above (ENSP, ENAM, ESSEC, IUT, FMSB, IAI, etc.) —
with coverage growing over time via crowdsourced contributions rather than needing full national
pre-population at launch.

---

## 5. Summary Tree

```
Exam Category
├── Primary
│   ├── FSLC (Anglophone)
│   ├── Common Entrance (Anglophone)
│   ├── CEP (Francophone)
│   └── Concours d'Entrée en 6ème (Francophone)
├── Secondary
│   ├── Francophone
│   │   ├── BEPC (+ Blanc) — Général / Technique
│   │   ├── Probatoire (+ Blanc) — Général / Technique
│   │   └── Bac (+ Blanc) — Général / Technique
│   └── Anglophone
│       ├── O Level (+ Mock)
│       └── A Level (+ Mock) — Science / Arts / Commercial / Technical
├── University / Tertiary
│   ├── In-course (CA/CC/Harmonisé CA, S1/S2) — [scope TBD]
│   ├── HND (Anglophone) / BTS (Francophone)
│   └── Vocational: AQP / CQP / DQP
└── Concours des Grandes Écoles
    └── [curated list — see Section 4]
```

---

## 6. Proposed Data Model

Rather than hardcoding this tree as fixed screens (Kawlo's approach), model it as composable fields
so new exam types/schools can be added without a schema migration:

```
ExamCategory   : enum        # primary | secondary | tertiary | concours
System         : enum        # anglophone | francophone | na (concours often cuts across both)
ExamType       : string      # "BEPC", "O Level", "HND", "ENAM", etc. — reference table, extensible
Track          : enum|null   # general | technical | science | arts | commercial | null
Variant        : enum        # official | mock/blanc
Level/Cycle    : string|null # e.g. "1er cycle" / "2ème cycle" for concours; "S1"/"S2" for university
Subject        : FK          # existing subject entity
Year           : int
```

This lets the Papers UI compose filters (System → Category → ExamType → Track → Variant → Year →
Subject) instead of needing a bespoke screen per exam type, and lets a new grande école or vocational
exam type be added as a data row rather than a code change.

---

All open questions from the initial draft are now resolved — this taxonomy is locked in for v1.
