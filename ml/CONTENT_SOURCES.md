# Treatment guidance — sources and provenance

Where the on-device guidance in `disease_repository_impl.dart` comes from, and
how much to trust each part of it.

This file exists because the app's rules forbid fabricating agronomic advice:
wrong treatment for a real disease is worse than an empty section. If guidance
is going to ship, its provenance should be checkable.

---

## The 12 entries added for the field model

Added alongside the rice and cassava classes in `ml/taxonomy.py`. English is
drawn from the references below. Nothing was invented; where a source is thin,
the guidance is correspondingly short rather than padded out.

### Rice — IRRI Rice Knowledge Bank

The standard international reference for rice diseases and pests.

| Class | Key guidance taken |
|---|---|
| `paddy_bacterial_leaf_blight` | Resistant varieties are the cheapest control; balanced nitrogen; drain the field; remove weed hosts and plough in stubble, ratoons and volunteers |
| `paddy_bacterial_leaf_streak` | Clean seed; balanced nitrogen; drainage; remove weed hosts |
| `paddy_bacterial_panicle_blight` | Pathogen-free seed, resistant cultivars, spacing. Worst in hot years |
| `paddy_brown_spot` | **Soil fertility is the first step** — this is a disease of poor soil, not primarily a spray problem. Seed treatment; avoid water stress |
| `paddy_downy_mildew` | Occurs only in waterlogged patches, near ditches and lowland. Drainage is the control |
| `paddy_tungro` | Resistant varieties; synchronous planting with neighbours; rogue infected plants. **Insecticide is explicitly ineffective** — leafhoppers reinfect from surrounding fields faster than spraying can stop them |
| `paddy_dead_heart` (stem borer) | Remove deadhearts and kill the larvae; harvest at ground level; plough in stubble; avoid overlapping crops. Use Bt/spinosad, **not** broad-spectrum insecticide |
| `paddy_hispa` | Clipping damaged leaf tips removes **75–90% of grubs** — the single most effective smallholder action. Cut surrounding grasses; avoid high nitrogen; delay spraying so parasitoid wasps survive |

Sources:
- [IRRI Rice Knowledge Bank — Bacterial blight](http://www.knowledgebank.irri.org/decision-tools/rice-doctor/rice-doctor-fact-sheets/item/bacterial-blight)
- [IRRI — Bacterial leaf streak](http://www.knowledgebank.irri.org/training/fact-sheets/pest-management/diseases/item/bacterial-leaf-streak)
- [IRRI — Brown spot](http://www.knowledgebank.irri.org/training/fact-sheets/pest-management/diseases/item/brown-spot)
- [IRRI — Tungro](http://www.knowledgebank.irri.org/training/fact-sheets/pest-management/diseases/item/tungro)
- [IRRI — Green leafhopper](http://www.knowledgebank.irri.org/training/fact-sheets/pest-management/insects/item/green-leafhopper)
- [IRRI — Stem borer](http://www.knowledgebank.irri.org/training/fact-sheets/pest-management/insects/item/stem-borer)
- [IRRI — Rice hispa](http://www.knowledgebank.irri.org/training/fact-sheets/pest-management/insects/item/rice-hispa)
- [Rice yellow stem borer — Pacific Pests & Pathogens](https://apps.lucidcentral.org/pppw_v11/text/web_mini/entities/rice_yellow_stem_borer_533.htm)
- [Management of Rice Hispa — Plantwise Knowledge Bank](https://plantwiseplusknowledgebank.org/doi/full/10.1079/pwkb.20157800050)
- [Sustainable Strategies for Managing Bacterial Panicle Blight in Rice — IntechOpen](https://www.intechopen.com/chapters/65866)

### Cassava — Pacific Pests & Pathogens, CABI, published IPM work

| Class | Key guidance taken |
|---|---|
| `cassava_bacterial_blight` | Cuttings from healthy plants only; do not plant beside old plots; 1–2 year rotation; clean tools with bleach; burn trash. **No chemical control exists.** Removing symptomatic leaves cut disease severity by **71%** in trials |
| `cassava_brown_streak` | Spread by whitefly and by cuttings; roots rot internally while looking sound outside. Clean planting material; rogue and burn |
| `cassava_green_mottle` | Spread through cuttings; symptom-free cuttings and roguing. **Chemical control is not recommended** |
| `cassava_mosaic` | Whitefly plus infected cuttings; resistant varieties; clean cuttings; rogue early |

Sources:
- [Cassava bacterial blight — Pacific Pests & Pathogens](https://apps.lucidcentral.org/pppw_v10/text/web_full/entities/cassava_bacterial_blight_173.htm)
- [Cassava green mottle — Pacific Pests & Pathogens](https://apps.lucidcentral.org/pppw_v10/text/web_full/entities/cassava_green_mottle_068.htm)
- [Cassava brown streak viruses — CABI Compendium](https://www.cabidigitallibrary.org/doi/full/10.1079/cabicompendium.17107)
- [Community phytosanitation to manage cassava brown streak disease](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC5669585/)
- [Removal of symptomatic cassava leaves as a cultural practice to control cassava bacterial blight](https://www.researchgate.net/publication/317345152_Removal_of_Symptomatic_Cassava_Leaves_as_Cultural_Practice_to_Control_Cassava_Bacterial_Blight)
- [Bacterial blight of cassava](https://en.wikipedia.org/wiki/Bacterial_blight_of_cassava)

---

## Why the guidance is written in short sentences

The app splits on-device guidance into steps at sentence boundaries, so each
sentence becomes one numbered step on the result screen. Writing "Drain the
field for a few days. Remove weeds from the bunds." produces two steps; writing
one long paragraph produces one unreadable step.

Each sentence is therefore **one action, at most about 14 words** — the same
constraint the backend prompt puts on the LLM, so both paths render alike.

A test enforces that every class in the taxonomy has guidance and that it
splits into usable steps: `test/data/repositories/treatment_guideline_coverage_test.dart`.

---

## What still needs a human

**Sinhala and Tamil have not been reviewed by a native speaker.** They are
grounded in the vocabulary already present in `disease_repository_impl.dart`,
which is not the same as being correct or natural. This is the same caveat the
original 27 guidelines carry, and it now covers 39.

**A local agronomist should review the English too**, specifically for
Sri Lankan applicability. Two known points:

- The chemical names come from international sources. Product availability and
  registration in Sri Lanka differ, and the app tells farmers to buy things.
  The **Department of Agriculture** and **RRDI Batalagoda** publish the
  locally-correct recommendations.
- **`cassava_green_mottle` may not occur in Sri Lanka at all.** The Pacific
  Pests factsheet records it only from the Solomon Islands. It is in the model
  because the Kaggle cassava dataset labels it, not because it is a local
  threat. Cassava *mosaic* is the locally important one — the Sri Lankan
  cassava mosaic virus (SLCMV) is named for the country. Consider whether the
  class is worth keeping at all.

---

## Orphaned entries

Eleven guidelines remain for crops the new taxonomy drops: apple (3), grape (3),
cherry, orange, peach, squash, strawberry.

They are **deliberately left in place for now**. The shipped PlantVillage model
still predicts those classes, so deleting their rows would break the app until
the new model lands. Remove them in the same change that swaps the model — see
the checklist in `ml/README.md`.
