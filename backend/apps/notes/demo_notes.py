"""
Demo summary notes for testing, one or two per level, so the Notes page is
populated and every note can actually be opened and read.

Body format (see Note.body): a blank line starts a new paragraph, a line
starting "## " is a heading and a line starting "- " is a bullet point.

The first five notes already exist on every database (seeded by migration
0002 and fixed up by 0004) with no text; the seed command fills their text in
without touching anything an admin has since written.
"""

# (title, subject_title, academic_level, body)
DEMO_NOTES = [
    (
        "Mechanics: Newton’s Laws",
        "Physics",
        "A Level",
        """Newton's three laws describe how forces change the motion of objects.

## The laws
- First law: an object stays at rest, or keeps moving at constant velocity, unless a resultant force acts on it.
- Second law: the resultant force equals mass times acceleration, F = ma. The acceleration is in the direction of the force.
- Third law: when object A exerts a force on object B, B exerts an equal and opposite force on A. The two forces act on different objects.

## Worked example
A 1,200 kg car accelerates at 2.5 m/s². The resultant force is 1,200 × 2.5 = 3,000 N.

## Common mistakes
- Forgetting that F in F = ma is the resultant (net) force.
- Treating the two forces of a third-law pair as if they act on the same object.
- Mixing units: use kilograms, metres and seconds.""",
    ),
    (
        "Cell Structure & Function",
        "Biology",
        "O Level",
        """The cell is the basic unit of life. All living things are made of one or more cells.

## Parts of an animal cell
- Nucleus: holds the DNA and controls the cell.
- Cytoplasm: the jelly where most chemical reactions happen.
- Cell membrane: controls what enters and leaves.
- Mitochondria: release energy from food (respiration).
- Ribosomes: build proteins.

## Extra parts in a plant cell
- Cell wall (made of cellulose): supports and protects the cell.
- Chloroplasts: contain chlorophyll and carry out photosynthesis.
- Large vacuole: stores cell sap and keeps the cell firm.

## Remember
Plant and animal cells share a nucleus, cytoplasm, membrane, mitochondria and ribosomes. Only plant cells have a cell wall, chloroplasts and a large permanent vacuole.""",
    ),
    (
        "La Dissertation Philosophique",
        "Philosophie",
        "Baccalauréat",
        """La dissertation est un exercice de réflexion argumentée : on répond à une question en construisant un raisonnement organisé.

## Les étapes
- Analyser le sujet : définir chaque terme et repérer le problème posé.
- Formuler la problématique : la question centrale qui guide tout le devoir.
- Annoncer un plan : en général deux ou trois parties qui avancent sans se répéter.
- Rédiger avec des exemples précis (auteurs, œuvres, faits) pour appuyer chaque idée.

## La structure
- Introduction : accroche, définition des termes, problématique, annonce du plan.
- Développement : chaque partie contient un argument, une explication, un exemple et une transition.
- Conclusion : une réponse claire à la question, et une ouverture possible.

## À éviter
Réciter un cours sans lien avec le sujet, ou répondre par oui ou par non sans discussion.""",
    ),
    (
        "Acids, Bases & Salts",
        "Chemistry",
        "O Level",
        """Acids and bases are chemical opposites, and when they react they make a salt and water.

## Properties
- Acids: sour taste, pH below 7, turn blue litmus red. Examples: hydrochloric acid, and ethanoic acid in vinegar.
- Bases: pH above 7, turn red litmus blue, feel slippery. Bases that dissolve in water are called alkalis, such as sodium hydroxide.
- Neutral substances, like pure water, have pH 7.

## Neutralisation
acid + base → salt + water

For example: hydrochloric acid + sodium hydroxide → sodium chloride + water.

## Naming the salt
- Hydrochloric acid gives chlorides.
- Sulfuric acid gives sulfates.
- Nitric acid gives nitrates.

## Safety
Never taste chemicals, and wear eye protection when you handle acids or alkalis.""",
    ),
    (
        "Les Nombres Complexes",
        "Mathématiques",
        "Terminale",
        """Un nombre complexe s'écrit z = a + ib, où a et b sont des réels et i est tel que i² = −1.

## Vocabulaire
- a est la partie réelle et b la partie imaginaire de z.
- Le conjugué de z est a − ib.
- Le module de z est |z| = √(a² + b²).

## Calculs
- (a + ib) + (c + id) = (a + c) + i(b + d).
- (a + ib)(c + id) = (ac − bd) + i(ad + bc).
- z multiplié par son conjugué vaut a² + b², un réel : on s'en sert pour diviser.

## Exemple
(2 + 3i)(1 − i) = 2 − 2i + 3i − 3i² = 2 + i + 3 = 5 + i.

## Forme trigonométrique
z = r(cos θ + i sin θ), avec r = |z| et θ un argument de z.""",
    ),
    (
        "Fractions & Decimals Made Simple",
        "Mathematics",
        "Primary",
        """A fraction shows part of a whole. The bottom number (the denominator) says how many equal parts the whole is cut into; the top number (the numerator) says how many parts you have.

## Key ideas
- 1/2 = 2/4 = 3/6: equivalent fractions name the same amount. Multiply or divide the top and the bottom by the same number.
- To add fractions with the same denominator, add the numerators: 2/7 + 3/7 = 5/7.
- To turn a fraction into a decimal, divide the top by the bottom: 3/4 = 3 ÷ 4 = 0.75.
- To turn a decimal into a fraction, read the place value: 0.6 = 6/10 = 3/5.

## Try this
Which is bigger, 3/4 or 2/3? Change both to twelfths: 9/12 and 8/12. So 3/4 is bigger.""",
    ),
    (
        "The Parts of a Plant",
        "Science",
        "Primary",
        """Most plants have four main parts, and each one has a job.

## The parts
- Roots hold the plant in the soil and take in water and minerals.
- The stem holds the plant up and carries water and food between the roots and the leaves.
- Leaves make food for the plant using sunlight, water and air. This is called photosynthesis.
- Flowers make seeds so that new plants can grow. Some flowers become fruits.

## Remember
A plant needs light, water, air and space to grow well. Take one of them away and the plant becomes weak.""",
    ),
    (
        "Le Pluriel des Noms",
        "Français",
        "Primary",
        """Pour mettre un nom au pluriel, on ajoute en général un « s » à la fin : un livre → des livres.

## Les cas à retenir
- Les noms qui finissent par -s, -x ou -z ne changent pas : un pays → des pays ; une voix → des voix ; un nez → des nez.
- Les noms en -au, -eau et -eu prennent un « x » : un bateau → des bateaux ; un jeu → des jeux.
- Les noms en -al font le plus souvent -aux : un animal → des animaux ; un journal → des journaux.
- Sept noms en -ou prennent un « x » : bijou, caillou, chou, genou, hibou, joujou, pou.

## Astuce
Regarde toujours l'article : « les » ou « des » t'indique que le nom est au pluriel.""",
    ),
    (
        "Le Théorème de Pythagore",
        "Mathématiques",
        "BEPC",
        """Dans un triangle rectangle, le carré de l'hypoténuse (le côté opposé à l'angle droit) est égal à la somme des carrés des deux autres côtés.

## La formule
Si le triangle ABC est rectangle en A, alors BC² = AB² + AC².

## Exemple
AB = 3 cm et AC = 4 cm. Alors BC² = 3² + 4² = 9 + 16 = 25, donc BC = 5 cm.

## À retenir
- On calcule d'abord les carrés, puis on prend la racine carrée à la fin.
- La réciproque permet de prouver qu'un triangle est rectangle : si BC² = AB² + AC², alors il est rectangle en A.""",
    ),
    (
        "La Photosynthèse en Bref",
        "SVT",
        "Seconde",
        """La photosynthèse est la réaction par laquelle les plantes vertes fabriquent leur nourriture à partir de la lumière.

## Le bilan
dioxyde de carbone + eau → glucose + dioxygène, en présence de lumière et de chlorophylle.

## Où et comment
- Elle se déroule surtout dans les feuilles, dans les chloroplastes qui contiennent la chlorophylle.
- L'eau est absorbée par les racines ; le dioxyde de carbone entre par les stomates.
- Le glucose fabriqué sert à la croissance ou est stocké sous forme d'amidon.

## Pourquoi c'est important
- Elle produit le dioxygène que respirent les êtres vivants.
- Elle est à la base des chaînes alimentaires : les plantes sont les producteurs.

## À retenir
Sans lumière, la photosynthèse s'arrête ; la respiration, elle, continue jour et nuit.""",
    ),
    (
        "Quadratic Equations Quick Guide",
        "Mathematics",
        "O Level",
        """A quadratic equation has the form ax² + bx + c = 0, where a is not zero. It can have two, one or no real solutions.

## Three ways to solve it
- Factorising: x² − 5x + 6 = 0 becomes (x − 2)(x − 3) = 0, so x = 2 or x = 3.
- The formula: x = (−b ± √(b² − 4ac)) ÷ 2a.
- Completing the square, which is how the formula is built.

## The discriminant
Work out b² − 4ac first:
- positive: two different real solutions
- zero: one repeated solution
- negative: no real solutions

## Check
Always put your answers back into the original equation to make sure both work.""",
    ),
    (
        "Rivers, Relief & Climate of Cameroon",
        "Geography",
        "O Level",
        """Cameroon is often called "Africa in miniature" because it has almost every kind of relief and climate found on the continent.

## Relief
- The coastal plain lies along the Atlantic, with mangrove swamps around the Wouri estuary.
- Mount Cameroon, about 4,040 m high, is an active volcano and the highest peak in West and Central Africa.
- The Western Highlands (the Grassfields) are cool, fertile and densely settled.
- The Adamawa Plateau crosses the middle of the country.
- The northern plains slope towards Lake Chad.

## Rivers
- The Sanaga is the longest river inside Cameroon and is used for hydroelectric power.
- The Wouri reaches the sea at Douala, the main port.
- The Benue crosses the north and joins the Niger system in Nigeria; the Logone drains towards Lake Chad.

## Climate
- South: equatorial, hot and wet, with two rainy seasons.
- Centre: a milder transition zone.
- Far north: Sahelian, hot and dry, with one short rainy season.""",
    ),
    (
        "Organic Chemistry: Functional Groups",
        "Chemistry",
        "A Level",
        """A functional group is the atom or group of atoms that decides how an organic molecule reacts.

## Common groups
- Alkene, C=C: takes part in addition reactions, for example with bromine.
- Alcohol, −OH: can be oxidised; ethanol is an example.
- Aldehyde (−CHO) and ketone (C=O inside the chain): carbonyl compounds made by oxidising alcohols.
- Carboxylic acid, −COOH: weak acids, for example ethanoic acid.
- Ester, −COO−: made from an acid and an alcohol, often with a fruity smell.
- Amine, −NH₂: basic compounds.

## Reactions to know
- Alkene + bromine water → dibromoalkane, and the orange colour disappears. This is the test for C=C.
- Alcohol + carboxylic acid ⇌ ester + water (esterification, with an acid catalyst).

## Tip
Name a compound from its longest carbon chain, then add the ending for the main group: −ol, −al, −one, −oic acid.""",
    ),
    (
        "L'Électricité : la Loi d'Ohm",
        "Physique",
        "Probatoire",
        """La loi d'Ohm relie la tension aux bornes d'un conducteur ohmique au courant qui le traverse.

## La formule
U = R × I
- U : tension, en volts (V)
- R : résistance, en ohms (Ω)
- I : intensité du courant, en ampères (A)

## Exemple
Un conducteur de 20 Ω est parcouru par un courant de 0,5 A. Alors U = 20 × 0,5 = 10 V.

## Associations de résistances
- En série : R = R₁ + R₂ ; le courant est le même partout.
- En dérivation : 1/R = 1/R₁ + 1/R₂ ; la tension est la même aux bornes de chaque branche.

## Attention
La loi d'Ohm ne s'applique qu'aux conducteurs ohmiques : leur caractéristique tension-courant est une droite qui passe par l'origine.""",
    ),
    (
        "Introduction to Algorithms & Complexity",
        "Computer Science",
        "University",
        """An algorithm is a finite, unambiguous list of steps that solves a problem. Complexity measures how the cost of an algorithm grows as the input gets bigger.

## Big-O notation
Big-O describes the worst-case growth rate and ignores constants:
- O(1): constant, for example reading an array element by its index
- O(log n): halving the problem at each step, for example binary search on a sorted list
- O(n): one pass over the data, for example linear search
- O(n log n): efficient sorting, for example merge sort
- O(n²): nested loops, for example a simple bubble sort

## Why it matters
For n = 1,000,000, an O(n log n) sort takes about 20 million steps, while an O(n²) sort needs a trillion. Choosing the right algorithm often matters more than buying a faster computer.

## Also consider
Memory use (space complexity), not only running time.""",
    ),
    (
        "Supply and Demand Basics",
        "Economics",
        "University",
        """Supply and demand explains how prices are set in a market.

## Demand
Demand shows how much buyers want at each price. When the price rises, the quantity demanded usually falls (the law of demand).

## Supply
Supply shows how much sellers offer at each price. When the price rises, the quantity supplied usually rises.

## Equilibrium
The market price settles where the quantity demanded equals the quantity supplied. Above it there is a surplus and sellers cut prices; below it there is a shortage and prices rise.

## What shifts the curves
- Demand: incomes, tastes, the price of substitutes and complements, and the number of buyers.
- Supply: costs of production, technology, taxes and subsidies, and the number of sellers.

## Example
If a poor harvest cuts the supply of tomatoes, the supply curve shifts left: the equilibrium price rises and the quantity traded falls.""",
    ),
    (
        "Double-Entry Bookkeeping Basics",
        "Accounting",
        "HND",
        """In double-entry bookkeeping every transaction is recorded twice: once as a debit and once as a credit, for the same amount.

## The accounting equation
Assets = Liabilities + Equity

## Debit and credit
- A debit increases assets and expenses; a credit decreases them.
- A credit increases liabilities, equity and income; a debit decreases them.

## Example
A business buys goods for 50,000 FCFA in cash:
- Debit Purchases (or Inventory) 50,000
- Credit Cash 50,000

## Checking your work
At the end of the period, add up all the debits and all the credits in a trial balance. The two totals must be equal. Equal totals do not prove there are no mistakes, but unequal totals prove there is one: look for a missing entry or one posted on the wrong side.""",
    ),
]

# The first five exist on every database already (migrations 0002 and 0004).
TITLES_FROM_MIGRATIONS = {title for title, *_ in DEMO_NOTES[:5]}
