# CropCare — model training

Everything needed to replace the shipped PlantVillage model with one trained on
field data, covering rice and pests.

```
ml/
  taxonomy.py          the class list + per-dataset label mappings — edit this
  build_notebook.py    regenerates the notebook from taxonomy.py + its cells
  cropcare_train.ipynb the Kaggle notebook — upload and run this
```

---

## Why replace the model

The shipped model is stock PlantVillage. Three problems, in order of severity.

**1. It cannot see rice.** The app seeds `paddy` as a crop, with `paddy_blast`
and `paddy_healthy` disease rows and a fully translated treatment guideline —
but the model has no rice class at all. Photograph a rice leaf today and the app
confidently reports a tomato or corn disease. Rice is the staple crop of the
audience this app is for.

**2. It was trained on lab photography.** PlantVillage is detached leaves on
uniform backgrounds under controlled light. The measured cost: models scoring
**99.35%** on PlantVillage's own test split drop to **31.4%** on field images.
Worse, a classifier trained on *8 background pixels alone* reaches **49%**
accuracy — 19× better than chance — which means the network is substantially
reading the backdrop rather than the leaf. Your users photograph leaves attached
to plants, in soil, in sun.

**3. It has one pest class.** `Tomato spider mites` is the entire arthropod
coverage. Pest detection is effectively unsupported.

Changing the architecture does not address any of this. For scale: MobileNetV2
(shipped) scores 88.5%, MobileNetV3 92.4%, MobileViT 93.6% — about four points,
against a 68-point field collapse. **The data is the problem, not the network.**

---

## What the new taxonomy does

34 classes across 6 crops, all of them grown by Sri Lankan smallholders:

| Crop | Classes | Source |
|---|---|---|
| Rice / paddy | 10 (incl. 2 pest) | Paddy Doctor — field |
| Tomato | 10 (incl. 1 pest) | PlantVillage + PlantDoc |
| Cassava | 5 | Cassava — field survey |
| Corn | 4 | PlantVillage + PlantDoc |
| Potato | 3 | PlantVillage + PlantDoc |
| Chili | 2 | PlantVillage + PlantDoc |

Dropped entirely: apple, blueberry, cherry, grape, orange, peach, raspberry,
soybean, squash, strawberry — 24 of the old 38 classes, none of them relevant,
all of them costing accuracy on the crops that matter.

Pest coverage goes from 1 class to 3, and two of those (`dead_heart` — stem
borer, and `hispa`) are on rice, the staple. That comes free with Paddy Doctor;
IP102 is not needed for a first useful version.

---

## Running it

1. **Kaggle → Create → Notebook → File → Import Notebook**, upload
   `cropcare_train.ipynb`.
2. **Settings → Accelerator → GPU T4 x2**, and **Internet: On**.
3. **Add Input**, and attach:

   | Search Kaggle for | Role |
   |---|---|
   | `paddy-disease-classification` | rice, field — closes the paddy gap |
   | `cassava-leaf-disease-classification` | field survey |
   | `plantvillage` or `new-plant-diseases-dataset` | lab, supporting only |
   | `plantdoc` | **held out** field test set |

   The two competition datasets need their rules accepted on the competition
   page first, or the files will not mount. Datasets are discovered by
   directory name, not slug, so any reasonable mirror works.

4. **Run All.** Expect roughly 1–2 hours on a T4.

Missing a dataset is not fatal — the notebook reports what it found and trains
on what is there. Missing PlantDoc costs you the field number, which is the only
one worth having.

---

## Reading the results

The notebook prints two accuracies. They are not equally meaningful.

- **Validation accuracy** is measured on the same distribution the model trained
  on. It will look good regardless. Do not ship on it.
- **PlantDoc accuracy** is measured on field photographs the model never saw.
  This is the number that predicts app behaviour.

The notebook prints the gap between them and grades it. A gap above 40 points is
the PlantVillage failure mode reproducing itself — the fix is more field data or
a lower `MAX_LAB_IMAGES_PER_CLASS`, never more epochs.

It also prints **per-class training composition**. Any class marked *"lab only —
treat as unproven"* has no field images behind it; its validation accuracy is
meaningless no matter how high.

---

## Wiring the result into the app

The notebook writes three artefacts to `/kaggle/working`:

| File | Goes to |
|---|---|
| `cropcare_field_mobilenetv3_fp16.tflite` | `assets/models/` |
| `ml_class_list.dart.txt` | paste into `lib/data/local/ml/ml_inference_service.dart` |
| `seed_diseases.dart.txt` | new rows for `disease_repository_impl.dart` |

Then:

1. Update `_modelAsset` and the `assets:` entry in `pubspec.yaml`.
2. Replace `_classNames` and `_classIndexToDiseaseId` with the generated block.
3. Seed the new `cassava` crop row and the new disease rows.
4. **Re-tune `confidenceThreshold` and `entropyThreshold`.** They were fitted to
   the old model's output distribution and do not carry over.
5. **Re-check `ValidateImageUseCase`'s vegetation-hue gate against rice** — a
   narrower, greyer leaf than the broadleaf crops it was tuned on. A content
   gate that rejects rice leaves would replace one bug with a worse one.

Two deliberate compatibility choices mean the app needs no preprocessing change:

- The model takes **`[0,1]` input** — the `[-1,1]` rescale MobileNetV3 wants
  happens inside the graph, so the app keeps its existing `/255`.
- The model outputs **raw logits, not softmax**. `MlInferenceService` applies
  softmax itself and derives entropy from it; a pre-softmaxed model would be
  double-softmaxed and every confidence score would quietly flatten.

---

## Known gaps this does not close

- **`name_si` / `name_ta` are empty for every disease.** The columns exist on
  the `disease` table and no seeder populates them, so disease names render in
  English in all three languages — the single most important string on the
  result screen. Adding 34 more classes makes this worse, not better. Needs a
  native speaker, not a script.
- **Treatment guidance for the rice and cassava diseases does not exist.** The
  notebook deliberately does not generate it. Fabricated agronomic advice for a
  real disease is worse than an empty section.
- **The OOD content gate is still tuned on synthetic fixtures**, and now has to
  cope with a new leaf morphology.
- **IP102** (102 pest classes) is gated behind an author request form. Worth
  starting that request now if broad pest coverage matters; rice pests are
  already covered without it.
