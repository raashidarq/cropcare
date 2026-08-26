"""
Generates `cropcare_train.ipynb` from the cells defined below.

Written as a generator rather than a hand-edited .ipynb for two reasons: the
notebook JSON stays valid by construction, and `taxonomy.py` is embedded from
disk at build time so there is exactly one source of truth for the class list.

Run after changing taxonomy.py or any cell:

    python ml/build_notebook.py
"""

from __future__ import annotations

import io
import json
import os

HERE = os.path.dirname(os.path.abspath(__file__))
TAXONOMY_SRC = io.open(os.path.join(HERE, "taxonomy.py"), encoding="utf-8").read()

cells: list[tuple[str, str]] = []


def md(text: str) -> None:
    cells.append(("markdown", text.strip("\n")))


def code(text: str) -> None:
    cells.append(("code", text.strip("\n")))


# ---------------------------------------------------------------------------
md(r"""
# CropCare — field-realistic crop disease & pest model

Trains the on-device model that replaces the shipped PlantVillage one.

## Why this exists

The shipped model is stock PlantVillage: 38 classes, 24 of them temperate fruit
a Sri Lankan smallholder will never photograph, **no rice at all**, and exactly
one pest class.

Two measured facts drive everything below:

- A model scoring **99.35%** on PlantVillage's own test split drops to **31.4%**
  on field images.
- A classifier trained on **8 background pixels alone** reaches **49%** accuracy
  on PlantVillage — 19× better than chance. The network is substantially
  reading the *backdrop*, not the leaf.

So PlantVillage is demoted to one source among several, the field datasets carry
the weight, and **PlantDoc is held out of training entirely** as the field test
set. The PlantDoc number at the end is the one that predicts how the app behaves
in an actual field. The validation number is not.

## Before you run

**Settings → Accelerator → GPU T4 x2** (or P100), and **Internet: On**.

Then **Add Input** and attach these. Exact dataset slugs vary between mirrors —
the notebook discovers them by directory name, so any reasonable mirror works:

| Dataset | Role | Search Kaggle for |
|---|---|---|
| Paddy Doctor | rice, field — **closes the paddy gap** | `paddy-disease-classification` |
| Cassava Leaf Disease | field survey | `cassava-leaf-disease-classification` |
| PlantVillage | lab, supporting only | `plantvillage` or `new-plant-diseases-dataset` |
| PlantDoc | **held out** field test set | `plantdoc` |

For the two competition datasets you must accept the rules on the competition
page first, or the files will not mount.

Missing any of them is fine — the notebook reports what it found and trains on
what is there. Missing PlantDoc means you lose the field number, which is the
one worth having.
""")

# ---------------------------------------------------------------------------
md("## 1 · Setup")

code('''
import os, sys, json, math, re, random, shutil, collections
from pathlib import Path

import numpy as np
import pandas as pd
import tensorflow as tf

SEED = 42
random.seed(SEED)
np.random.seed(SEED)
tf.random.set_seed(SEED)

print("TensorFlow", tf.__version__)
gpus = tf.config.list_physical_devices("GPU")
print("GPUs:", [g.name for g in gpus] or "NONE — turn on the GPU accelerator")
for g in gpus:
    tf.config.experimental.set_memory_growth(g, True)
''')

# ---------------------------------------------------------------------------
md("""
## 2 · Taxonomy

Embedded from `ml/taxonomy.py` in the CropCare repo so this notebook is
self-contained. Edit it there and re-run `python ml/build_notebook.py`, not
here — a class list that has drifted from the app's disease ids is a silent
mismapping, not an error.
""")

# Embedded as executable code rather than as a quoted string. The taxonomy has
# docstrings of its own, which would terminate any wrapper literal, and it is
# the one part of this notebook a reader is most likely to want to read and
# edit in place.
_tax = TAXONOMY_SRC
# `from __future__` is only legal at the top of a module, and Python 3.11+
# understands `str | None` natively, so it is not needed here.
_tax = _tax.replace("from __future__ import annotations\n", "")
# Drop the CLI block; the cell prints the summary itself.
_tax = _tax.split('if __name__ ==')[0].rstrip() + "\n"
code(_tax + "\nprint(summary())")

# ---------------------------------------------------------------------------
md("## 3 · Config")

code('''
IMG_SIZE      = 224          # matches the app's existing preprocessing
BATCH_SIZE    = 64
EPOCHS_HEAD   = 4            # frozen backbone, train the classifier head
EPOCHS_FINE   = 16           # unfreeze the top of the backbone
LR_HEAD       = 1e-3
LR_FINE       = 1e-4
FINE_TUNE_AT  = 100          # unfreeze layers from this index up
VAL_FRACTION  = 0.15
LABEL_SMOOTH  = 0.05         # the labels are not perfectly clean; do not let
                             # the model become certain about them
DROPOUT       = 0.3

# Caps the lab dataset's contribution. Without this, PlantVillage's sheer
# volume drowns the field data and the model happily relearns the background
# shortcut that makes it useless outdoors.
MAX_LAB_IMAGES_PER_CLASS = 400

OUT_DIR = Path("/kaggle/working")
MODEL_NAME = "cropcare_field_mobilenetv3"
''')

# ---------------------------------------------------------------------------
md("""
## 4 · Find the attached datasets

Matched by directory name rather than dataset slug, because slugs differ
between mirrors and go stale. Whatever is attached gets used.
""")

code('''
INPUT_ROOT = Path("/kaggle/input")

def find_source_dirs(source):
    """All attached directories plausibly belonging to `source`."""
    hits = []
    if not INPUT_ROOT.exists():
        return hits
    for entry in sorted(INPUT_ROOT.iterdir()):
        if not entry.is_dir():
            continue
        name = entry.name.lower().replace("_", "-")
        for hint in source.dir_hints:
            if hint.lower().replace("_", "-") in name:
                hits.append(entry)
                break
    return hits

print("Attached inputs:")
for e in sorted(INPUT_ROOT.iterdir()) if INPUT_ROOT.exists() else []:
    print("   ", e.name)

print()
FOUND = {}
for src in SOURCES:
    dirs = find_source_dirs(src)
    FOUND[src.key] = dirs
    mark = "OK   " if dirs else "MISS "
    held = "  [held out]" if src.key in HELD_OUT_SOURCES else ""
    print(f"{mark} {src.name}{held}")
    for d in dirs:
        print(f"        {d}")

if not any(FOUND[s.key] for s in SOURCES if s.key not in HELD_OUT_SOURCES):
    raise SystemExit(
        "No trainable dataset attached. Use 'Add Input' — see the table at the "
        "top of this notebook."
    )
if not FOUND.get("plantdoc"):
    print("\\nWARNING: PlantDoc is not attached, so there will be no field "
          "generalisation number at the end. The validation accuracy alone "
          "will look good and mean very little.")
''')

# ---------------------------------------------------------------------------
md("""
## 5 · Build one index over every source

Each source is walked into the same shape: `(filepath, class_id, source)`.

Labels that do not map onto the taxonomy are **counted and printed**, never
silently dropped. A quietly discarded third of a dataset shows up later only as
unexplained accuracy loss, which is a miserable thing to debug.
""")

code('''
IMG_EXT = {".jpg", ".jpeg", ".png", ".JPG", ".JPEG", ".PNG"}

def _iter_images(folder):
    for p in Path(folder).rglob("*"):
        if p.suffix in IMG_EXT:
            yield p

def load_folder_source(src, roots):
    """Datasets labelled by directory name (PlantVillage, PlantDoc)."""
    rows, unmapped = [], collections.Counter()
    # Normalise once so mirrors that differ only in punctuation still match.
    norm = {re.sub(r"[^a-z0-9]", "", k.lower()): v
            for k, v in src.label_map.items()}
    for root in roots:
        for folder in sorted({p.parent for p in _iter_images(root)}):
            key = re.sub(r"[^a-z0-9]", "", folder.name.lower())
            class_id = norm.get(key)
            if class_id is None:
                unmapped[folder.name] += sum(1 for _ in _iter_images(folder))
                continue
            for img in _iter_images(folder):
                rows.append((str(img), class_id, src.key))
    return rows, unmapped

def load_csv_source(src, roots):
    """Datasets labelled by a CSV (Paddy Doctor, Cassava)."""
    rows, unmapped = [], collections.Counter()
    for root in roots:
        csvs = list(Path(root).rglob(src.csv_name or "train.csv"))
        if not csvs:
            continue
        df = pd.read_csv(csvs[0])
        base = csvs[0].parent
        # Index every image once so we can resolve ids without guessing the
        # directory layout, which differs between competition and mirror.
        by_name = {}
        for p in _iter_images(base):
            by_name.setdefault(p.name, p)
        for _, r in df.iterrows():
            raw = str(r[src.csv_label_col])
            class_id = src.label_map.get(raw)
            if class_id is None:
                unmapped[raw] += 1
                continue
            img_name = str(r[src.csv_image_col])
            p = by_name.get(img_name)
            if p is None:
                continue
            rows.append((str(p), class_id, src.key))
    return rows, unmapped

all_rows = []
for src in SOURCES:
    roots = FOUND[src.key]
    if not roots:
        continue
    if src.csv_name:
        rows, unmapped = load_csv_source(src, roots)
    else:
        rows, unmapped = load_folder_source(src, roots)
    all_rows.extend(rows)
    print(f"{src.name}: {len(rows):,} images")
    if unmapped:
        total = sum(unmapped.values())
        print(f"    {total:,} images under {len(unmapped)} unmapped labels "
              f"(expected for crops outside the taxonomy):")
        for label, n in unmapped.most_common(8):
            print(f"      - {label}: {n:,}")
        if len(unmapped) > 8:
            print(f"      ... and {len(unmapped) - 8} more")

df = pd.DataFrame(all_rows, columns=["path", "class_id", "source"])
if df.empty:
    raise SystemExit("No images matched the taxonomy. Check the attached datasets.")
df["label"] = df["class_id"].map(CLASS_INDEX)
print(f"\\nTotal usable: {len(df):,} images across "
      f"{df['class_id'].nunique()} of {NUM_CLASSES} classes")
''')

# ---------------------------------------------------------------------------
md("""
## 6 · Cap the lab data, then split

Two things happen here and both matter more than they look.

**The lab cap.** PlantVillage has thousands of images per class against Paddy
Doctor's hundreds. Left alone it dominates the gradient and the model relearns
the background shortcut. Capped, it contributes signal without setting the
agenda.

**The split.** Validation comes from the same distribution as training, so it
will look good regardless. PlantDoc is a *different* distribution and never
appears in training, which is why it is the only honest measure here.
""")

code('''
# --- cap the lab source ---------------------------------------------------
capped = []
for (cls, srckey), g in df.groupby(["class_id", "source"]):
    if srckey in LAB_SOURCES and len(g) > MAX_LAB_IMAGES_PER_CLASS:
        g = g.sample(MAX_LAB_IMAGES_PER_CLASS, random_state=SEED)
    capped.append(g)
df = pd.concat(capped, ignore_index=True)

# --- hold PlantDoc out entirely -------------------------------------------
test_df  = df[df["source"].isin(HELD_OUT_SOURCES)].reset_index(drop=True)
train_pool = df[~df["source"].isin(HELD_OUT_SOURCES)].reset_index(drop=True)

# --- stratified train/val -------------------------------------------------
train_parts, val_parts = [], []
for cls, g in train_pool.groupby("class_id"):
    g = g.sample(frac=1.0, random_state=SEED)
    n_val = max(1, int(len(g) * VAL_FRACTION)) if len(g) > 1 else 0
    val_parts.append(g.iloc[:n_val])
    train_parts.append(g.iloc[n_val:])
train_df = pd.concat(train_parts, ignore_index=True).sample(frac=1.0, random_state=SEED)
val_df   = pd.concat(val_parts, ignore_index=True)

print(f"train {len(train_df):,}   val {len(val_df):,}   "
      f"field test (held out) {len(test_df):,}")

# --- composition report ---------------------------------------------------
# A class fed only by lab plates is unproven no matter what validation says.
print("\\nPer-class training composition:")
print(f"{'class':<38} {'n':>6}  {'% lab':>6}   note")
lab_only = []
for cls in CLASS_IDS:
    g = train_df[train_df["class_id"] == cls]
    if len(g) == 0:
        print(f"{cls:<38} {0:>6}          NO TRAINING DATA")
        continue
    lab_pct = 100.0 * g["source"].isin(LAB_SOURCES).mean()
    note = ""
    if lab_pct == 100.0:
        note = "lab only — treat as unproven"
        lab_only.append(cls)
    elif len(g) < 100:
        note = "few samples"
    print(f"{cls:<38} {len(g):>6}  {lab_pct:>5.0f}%   {note}")

if lab_only:
    print(f"\\n{len(lab_only)} classes have lab-only training data. Their "
          f"validation accuracy will look excellent and should not be believed "
          f"until field images exist for them.")
''')

# ---------------------------------------------------------------------------
md("""
## 7 · Input pipeline

Augmentation is aimed squarely at the background-bias finding. Aggressive random
cropping and geometric jitter stop the network settling on a fixed leaf position
and a clean backdrop; brightness and contrast jitter stand in for sun, shade and
a cheap phone camera.
""")

code('''
AUTOTUNE = tf.data.AUTOTUNE

def decode(path, label, training):
    img = tf.io.read_file(path)
    img = tf.io.decode_image(img, channels=3, expand_animations=False)
    img = tf.image.convert_image_dtype(img, tf.float32)   # -> [0, 1]
    if training:
        # Crop before resize: varies scale and framing, which is most of what
        # separates a lab plate from a photo taken over a plant.
        img = tf.image.resize(img, [int(IMG_SIZE * 1.25)] * 2)
        img = tf.image.random_crop(img, [IMG_SIZE, IMG_SIZE, 3])
        img = tf.image.random_flip_left_right(img)
        img = tf.image.random_flip_up_down(img)
        img = tf.image.random_brightness(img, 0.25)
        img = tf.image.random_contrast(img, 0.75, 1.35)
        img = tf.image.random_saturation(img, 0.7, 1.4)
        img = tf.image.random_hue(img, 0.03)
        img = tf.clip_by_value(img, 0.0, 1.0)
    else:
        img = tf.image.resize(img, [IMG_SIZE, IMG_SIZE])
    img.set_shape([IMG_SIZE, IMG_SIZE, 3])
    return img, label

def make_ds(frame, training):
    ds = tf.data.Dataset.from_tensor_slices(
        (frame["path"].values, frame["label"].values.astype("int32"))
    )
    if training:
        ds = ds.shuffle(min(len(frame), 8192), seed=SEED, reshuffle_each_iteration=True)
    ds = ds.map(lambda p, l: decode(p, l, training), num_parallel_calls=AUTOTUNE)
    ds = ds.batch(BATCH_SIZE).prefetch(AUTOTUNE)
    return ds

train_ds = make_ds(train_df, True)
val_ds   = make_ds(val_df,   False)
test_ds  = make_ds(test_df,  False) if len(test_df) else None

# Class weights: the sources are very unbalanced and the rare classes are not
# the unimportant ones.
counts = train_df["label"].value_counts().to_dict()
total  = sum(counts.values())
class_weight = {
    i: total / (len(counts) * counts[i]) for i in counts
}
print(f"{len(counts)} classes weighted; heaviest "
      f"{max(class_weight.values()):.2f}x, lightest {min(class_weight.values()):.2f}x")
''')

# ---------------------------------------------------------------------------
md("""
## 8 · Model

`MobileNetV3Large`, chosen for CPU inference on budget hardware — it beats
EfficientNet-Lite on both accuracy and latency, and beats MobileViT on latency
without a GPU delegate.

Two details exist purely so the Flutter app needs no preprocessing changes:

- **Input is `[0,1]`**, and the `[-1,1]` rescale MobileNetV3 expects happens
  *inside* the graph. The app already divides by 255.
- **Output is raw logits, no softmax.** `MlInferenceService` applies softmax
  itself and computes entropy from the distribution; a model that pre-softmaxed
  would double-apply it and quietly flatten every confidence score.
""")

code('''
def build_model():
    inputs = tf.keras.Input(shape=(IMG_SIZE, IMG_SIZE, 3), name="input_image")
    # [0,1] -> [-1,1], baked in so the app keeps its existing /255.
    x = tf.keras.layers.Rescaling(scale=2.0, offset=-1.0)(inputs)

    base = tf.keras.applications.MobileNetV3Large(
        input_shape=(IMG_SIZE, IMG_SIZE, 3),
        include_top=False,
        weights="imagenet",
        include_preprocessing=False,   # we did it above, explicitly
    )
    base.trainable = False

    x = base(x, training=False)
    x = tf.keras.layers.GlobalAveragePooling2D()(x)
    x = tf.keras.layers.Dropout(DROPOUT)(x)
    # No activation: raw logits, as the app expects.
    outputs = tf.keras.layers.Dense(NUM_CLASSES, activation=None, name="logits")(x)

    return tf.keras.Model(inputs, outputs, name=MODEL_NAME), base

model, base = build_model()

loss = tf.keras.losses.SparseCategoricalCrossentropy(
    from_logits=True, label_smoothing=0.0
)

def compile_model(lr):
    model.compile(
        optimizer=tf.keras.optimizers.Adam(lr),
        loss=loss,
        metrics=[
            tf.keras.metrics.SparseCategoricalAccuracy(name="acc"),
            tf.keras.metrics.SparseTopKCategoricalAccuracy(k=3, name="top3"),
        ],
    )

compile_model(LR_HEAD)
print(f"{model.count_params():,} parameters "
      f"({sum(tf.size(w).numpy() for w in model.trainable_weights):,} trainable)")
''')

# ---------------------------------------------------------------------------
md("## 9 · Train — head first, then fine-tune")

code('''
ckpt = OUT_DIR / f"{MODEL_NAME}.keras"
callbacks = [
    tf.keras.callbacks.ModelCheckpoint(
        str(ckpt), monitor="val_acc", mode="max",
        save_best_only=True, verbose=1),
    tf.keras.callbacks.EarlyStopping(
        monitor="val_acc", mode="max", patience=5,
        restore_best_weights=True, verbose=1),
    tf.keras.callbacks.ReduceLROnPlateau(
        monitor="val_loss", factor=0.3, patience=2, min_lr=1e-6, verbose=1),
]

print("Phase 1 — classifier head, backbone frozen")
hist_head = model.fit(
    train_ds, validation_data=val_ds, epochs=EPOCHS_HEAD,
    class_weight=class_weight, callbacks=callbacks, verbose=1,
)

print("\\nPhase 2 — fine-tuning the top of the backbone")
base.trainable = True
for layer in base.layers[:FINE_TUNE_AT]:
    layer.trainable = False
# BatchNorm stays frozen: fine-tuning with small batches otherwise wrecks the
# running statistics the pretrained weights depend on.
for layer in base.layers:
    if isinstance(layer, tf.keras.layers.BatchNormalization):
        layer.trainable = False

compile_model(LR_FINE)
hist_fine = model.fit(
    train_ds, validation_data=val_ds, epochs=EPOCHS_FINE,
    class_weight=class_weight, callbacks=callbacks, verbose=1,
)
''')

# ---------------------------------------------------------------------------
md("""
## 10 · Evaluate — and the only number that matters

`val_acc` is measured on the same distribution the model trained on, so it will
look good whatever happens. **PlantDoc accuracy is the field number.**

For reference on what a lab-only model does here: PlantVillage-trained networks
report ~99% on their own split and **31.4%** on field images. If the gap below
is anywhere near that wide, the model is not ready and adding field data is the
fix — not more epochs.
""")

code('''
print("Validation (same distribution as training — the flattering number):")
val_metrics = model.evaluate(val_ds, verbose=0)
for name, v in zip(model.metrics_names, val_metrics):
    print(f"   {name}: {v:.4f}")

if test_ds is not None:
    print("\\nPlantDoc — unseen field photographs (the honest number):")
    test_metrics = model.evaluate(test_ds, verbose=0)
    for name, v in zip(model.metrics_names, test_metrics):
        print(f"   {name}: {v:.4f}")

    val_acc  = val_metrics[model.metrics_names.index("acc")]
    test_acc = test_metrics[model.metrics_names.index("acc")]
    gap = (val_acc - test_acc) * 100
    print(f"\\nLab-to-field gap: {gap:.1f} points")
    if gap > 40:
        print("   SEVERE — this is the PlantVillage failure mode. The model is "
              "reading backgrounds. More epochs will not help; more field data will.")
    elif gap > 20:
        print("   Large but workable. Consider raising augmentation strength or "
              "lowering MAX_LAB_IMAGES_PER_CLASS.")
    else:
        print("   Reasonable generalisation.")

    # Per-class field accuracy: an average hides a class that never works, and
    # a disease that is always wrong is worse than one the app refuses to name.
    print("\\nPer-class accuracy on field images:")
    y_true, y_pred = [], []
    for xb, yb in test_ds:
        y_true.extend(yb.numpy())
        y_pred.extend(np.argmax(model.predict(xb, verbose=0), axis=1))
    y_true, y_pred = np.array(y_true), np.array(y_pred)
    for i, cls in enumerate(CLASS_IDS):
        m = y_true == i
        if m.sum() == 0:
            continue
        acc = (y_pred[m] == i).mean()
        flag = "   <-- weak" if acc < 0.5 else ""
        print(f"   {cls:<38} {m.sum():>4} imgs   {acc:.2f}{flag}")
else:
    print("\\nNo held-out field set attached, so there is no generalisation "
          "number. Do not ship on the validation figure alone.")
''')

# ---------------------------------------------------------------------------
md("""
## 11 · Export TFLite, and verify it still agrees with Keras

Float16 post-training quantisation: roughly half the size, negligible accuracy
cost, and no need for a representative dataset the way int8 would.

The parity check is not ceremony. Conversion silently changing behaviour is the
single most common way one of these projects ships a broken model.
""")

code('''
converter = tf.lite.TFLiteConverter.from_keras_model(model)
converter.optimizations = [tf.lite.Optimize.DEFAULT]
converter.target_spec.supported_types = [tf.float16]
tflite_model = converter.convert()

tflite_path = OUT_DIR / f"{MODEL_NAME}_fp16.tflite"
tflite_path.write_bytes(tflite_model)
size_mb = len(tflite_model) / 1e6
print(f"Wrote {tflite_path.name} — {size_mb:.2f} MB "
      f"(the shipped PlantVillage model is 9.06 MB)")

# --- parity check ---------------------------------------------------------
interp = tf.lite.Interpreter(model_content=tflite_model)
interp.allocate_tensors()
inp, out = interp.get_input_details()[0], interp.get_output_details()[0]
print(f"\\ninput  {inp['shape']} {inp['dtype'].__name__}")
print(f"output {out['shape']} {out['dtype'].__name__}")
assert tuple(inp["shape"][1:]) == (IMG_SIZE, IMG_SIZE, 3), "unexpected input shape"
assert int(out["shape"][-1]) == NUM_CLASSES, "output width != class count"

check = val_df.sample(min(64, len(val_df)), random_state=SEED)
agree = 0
for _, row in check.iterrows():
    img, _ = decode(tf.constant(row["path"]), tf.constant(0), False)
    batch = tf.expand_dims(img, 0)
    keras_pred = int(np.argmax(model.predict(batch, verbose=0)[0]))
    interp.set_tensor(inp["index"], batch.numpy().astype(inp["dtype"]))
    interp.invoke()
    tfl_pred = int(np.argmax(interp.get_tensor(out["index"])[0]))
    agree += (keras_pred == tfl_pred)

pct = 100.0 * agree / len(check)
print(f"\\nKeras/TFLite top-1 agreement on {len(check)} images: {pct:.1f}%")
if pct < 95:
    print("   Below 95% — investigate before shipping. Quantisation should not "
          "change predictions this often.")
else:
    print("   Conversion is faithful.")
''')

# ---------------------------------------------------------------------------
md("""
## 12 · Generate the Dart the app needs

Emits the class list and the class-index → disease-id map, both ordered to match
the model's output exactly. Copy the printed block into
`lib/data/local/ml/ml_inference_service.dart`.

Also writes `seed_diseases.dart.txt` for the crops and diseases the app does not
yet carry — rice and cassava rows. **Treatment guidance is deliberately not
generated**: fabricated agronomic advice for a real disease is worse than an
empty section, and the repo rules say so.
""")

code('''
lines = []
lines.append("  static const List<String> _classNames = [")
for i, c in enumerate(CLASSES):
    lines.append(f"    '{c.id}',{' ' * max(1, 44 - len(c.id))}// {i}")
lines.append("  ];")
lines.append("")
lines.append("  static const Map<int, String> _classIndexToDiseaseId = {")
for i, c in enumerate(CLASSES):
    lines.append(f"    {i}: '{c.id}',")
lines.append("  };")
lines.append("")
lines.append("  /// Classes that are insect damage rather than infection.")
lines.append("  static const Set<int> _pestClassIndices = {")
pest_idx = [str(i) for i, c in enumerate(CLASSES) if c.is_pest]
lines.append("    " + ", ".join(pest_idx) + ",")
lines.append("  };")

dart = "\\n".join(lines)
(OUT_DIR / "ml_class_list.dart.txt").write_text(dart, encoding="utf-8")
print(dart)

# --- rows the app does not have yet --------------------------------------
existing_crops = {"tomato", "chili", "potato", "corn", "paddy"}
seed = []
for crop in sorted({c.crop_id for c in CLASSES}):
    if crop not in existing_crops:
        seed.append(f"// NEW CROP: {crop} - add a CropTableCompanion row")
for c in CLASSES:
    sev = f"const Value('{c.severity}')" if c.severity else "const Value(null)"
    seed.append(
        f"DiseaseTableCompanion.insert(id: '{c.id}', cropId: '{c.crop_id}', "
        f"nameEn: '{c.name_en}', severityDefault: {sev}),"
    )
(OUT_DIR / "seed_diseases.dart.txt").write_text("\\n".join(seed), encoding="utf-8")
print(f"\\n\\nWrote seed_diseases.dart.txt ({len(CLASSES)} disease rows).")
print("name_si / name_ta are NOT generated - those need a native speaker.")
''')

# ---------------------------------------------------------------------------
md("""
## 13 · Download and wire up

From the **Output** panel, download:

- `cropcare_field_mobilenetv3_fp16.tflite` → `assets/models/`
- `ml_class_list.dart.txt` → paste into `ml_inference_service.dart`
- `seed_diseases.dart.txt` → the new disease rows for `disease_repository_impl.dart`

Then in the app:

1. Update `_modelAsset` and the `assets:` entry in `pubspec.yaml`.
2. Replace `_classNames` and `_classIndexToDiseaseId` with the generated block.
3. Seed the new crops (`cassava`) and disease rows — `crop_repository_impl.dart`
   and `disease_repository_impl.dart`.
4. Re-tune `confidenceThreshold` and `entropyThreshold`. They were fitted to the
   old model's output distribution and do **not** carry over.
5. Re-check `ValidateImageUseCase`'s vegetation-hue gate against rice, which is
   a narrower, greyer leaf than the broadleaf crops it was tuned on.

Still outstanding after this, and neither is a code problem:

- **`name_si` / `name_ta` are empty** for every disease. The columns exist and
  nothing populates them, so disease names render in English in all three
  languages — the single most important string on the result screen.
- **Treatment guidance** for the rice and cassava diseases. Do not invent it.
""")


# ---------------------------------------------------------------------------
def build() -> dict:
    out = []
    for kind, text in cells:
        src = text.splitlines(keepends=True)
        if kind == "markdown":
            out.append({"cell_type": "markdown", "metadata": {}, "source": src})
        else:
            out.append({
                "cell_type": "code",
                "execution_count": None,
                "metadata": {},
                "outputs": [],
                "source": src,
            })
    return {
        "cells": out,
        "metadata": {
            "kernelspec": {
                "display_name": "Python 3",
                "language": "python",
                "name": "python3",
            },
            "language_info": {"name": "python", "version": "3.11"},
            "accelerator": "GPU",
        },
        "nbformat": 4,
        "nbformat_minor": 5,
    }


if __name__ == "__main__":
    nb = build()
    path = os.path.join(HERE, "cropcare_train.ipynb")
    with io.open(path, "w", encoding="utf-8") as f:
        json.dump(nb, f, indent=1, ensure_ascii=False)
    print(f"wrote {path} ({len(nb['cells'])} cells)")
