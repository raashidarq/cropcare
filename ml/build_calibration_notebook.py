"""
Generates `cropcare_calibrate.ipynb` — a small, CPU-only notebook that
measures the trained .tflite model's actual confidence distribution on held-out
field images, and prints the table needed to pick `confidenceThreshold` for
real rather than by reasoning about it.

Run after `python ml/build_notebook.py` has already produced a trained model
and you have downloaded the .tflite from that run:

    python ml/build_calibration_notebook.py

No GPU accelerator is needed for this one — it only runs inference on a few
hundred images, which is fast on CPU. Save yourself the GPU queue time.
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
# CropCare — confidence threshold calibration

Answers one question with a measurement instead of a guess: **at what
confidence should the app say "I'm not sure" instead of naming a disease?**

`confidenceThreshold` in `ml_inference_service.dart` is currently **0.70,
reasoned but not measured** — see the comment above it in that file. This
notebook measures it against your actual trained model's actual predictions on
field photographs it never trained on, and prints the number to replace it
with.

## Before you run

1. **Settings → Accelerator → None.** This is CPU-only inference over a few
   hundred images — a GPU buys you nothing here and just costs you queue time.
2. **Internet: On.**
3. **Add Input:**
   - Your trained model. If it isn't already a Kaggle Dataset, create one:
     **Datasets → New Dataset**, upload the `.tflite` file you downloaded from
     the training run, give it any name. Then attach it here like any other
     dataset.
   - `plantdoc` (Datasets tab) — the same held-out field test set the training
     notebook used. Same caveat as there: if you attach a *notebook* instead
     of the *dataset*, this will find nothing — see the training notebook's
     own note on that mistake if you hit it again.

Missing PlantDoc means this notebook has nothing to measure against and will
stop with a clear message rather than fabricating a number.
""")

# ---------------------------------------------------------------------------
md("## 1 · Setup")

code('''
import os, re, collections
from pathlib import Path

import numpy as np
import pandas as pd
import tensorflow as tf

print("TensorFlow", tf.__version__)
print("This notebook is CPU-only by design - no GPU check needed.")
''')

# ---------------------------------------------------------------------------
md("## 2 · Taxonomy (same source of truth as training)")

_tax = TAXONOMY_SRC
_tax = _tax.replace("from __future__ import annotations\n", "")
_tax = _tax.split('if __name__ ==')[0].rstrip() + "\n"
code(_tax + "\nprint(summary())")

# ---------------------------------------------------------------------------
md("## 3 · Find the model and PlantDoc")

code('''
INPUT_ROOT = Path("/kaggle/input")
MAX_DEPTH = 3

def _norm(s):
    return re.sub(r"[^a-z0-9]", "", s.lower())

def _candidate_dirs():
    if not INPUT_ROOT.exists():
        return []
    out = []
    for depth in range(1, MAX_DEPTH + 1):
        out.extend(sorted(p for p in INPUT_ROOT.glob("/".join(["*"] * depth))
                          if p.is_dir()))
    return out

def find_dirs(hints):
    hits = []
    for entry in _candidate_dirs():
        rel = _norm(str(entry.relative_to(INPUT_ROOT)))
        if not any(_norm(h) in rel for h in hints):
            continue
        if any(entry.is_relative_to(h) for h in hits):
            continue
        hits.append(entry)
    return hits

print("Mounted under /kaggle/input:")
if not INPUT_ROOT.exists() or not any(INPUT_ROOT.iterdir()):
    print("   (nothing)")
else:
    for top in sorted(p for p in INPUT_ROOT.iterdir() if p.is_dir()):
        print(f"   {top.name}/")

tflite_candidates = list(INPUT_ROOT.rglob("*.tflite"))
plantdoc_dirs = [d for d in find_dirs(PLANT_DOC.dir_hints)
                 if any(p.suffix.lower() in {".jpg",".jpeg",".png"}
                        for p in d.rglob("*"))]

if not tflite_candidates:
    raise SystemExit(
        "No .tflite file found under /kaggle/input. Upload it as a Kaggle "
        "Dataset (Datasets -> New Dataset -> upload the file) and attach it "
        "to this notebook, then Add Input again."
    )
if not plantdoc_dirs:
    raise SystemExit(
        "PlantDoc not found. Without it there is nothing to measure "
        "confidence against - see the note at the top of this notebook "
        "about attaching the dataset, not a notebook of the same name."
    )

MODEL_PATH = tflite_candidates[0]
PLANTDOC_DIR = plantdoc_dirs[0]
print(f"\\nUsing model: {MODEL_PATH}")
print(f"Using PlantDoc: {PLANTDOC_DIR}")
if len(tflite_candidates) > 1:
    print(f"(found {len(tflite_candidates)} .tflite files, using the first - "
          f"remove the others from Input if this is not the right one)")
''')

# ---------------------------------------------------------------------------
md("## 4 · Load PlantDoc labels, load the model")

code('''
IMG_EXT = {".jpg", ".jpeg", ".png", ".JPG", ".JPEG", ".PNG"}
IMG_SIZE = 224

def load_plantdoc():
    norm = {re.sub(r"[^a-z0-9]", "", k.lower()): v
            for k, v in PLANT_DOC.label_map.items()}
    rows, unmapped = [], collections.Counter()
    for folder in sorted({p.parent for p in PLANTDOC_DIR.rglob("*")
                          if p.suffix in IMG_EXT}):
        key = re.sub(r"[^a-z0-9]", "", folder.name.lower())
        class_id = norm.get(key)
        if class_id is None:
            unmapped[folder.name] += sum(1 for p in folder.iterdir()
                                         if p.suffix in IMG_EXT)
            continue
        for img in folder.iterdir():
            if img.suffix in IMG_EXT:
                rows.append((str(img), class_id))
    if unmapped:
        print(f"{sum(unmapped.values())} images under unmapped labels, skipped "
              f"(expected - PlantDoc covers more crops than this taxonomy):")
        for label, n in unmapped.most_common(5):
            print(f"   {label}: {n}")
    return pd.DataFrame(rows, columns=["path", "class_id"])

df = load_plantdoc()
df["label"] = df["class_id"].map(CLASS_INDEX)
print(f"\\n{len(df)} labelled field images across {df['class_id'].nunique()} classes")

interpreter = tf.lite.Interpreter(model_path=str(MODEL_PATH))
interpreter.allocate_tensors()
inp = interpreter.get_input_details()[0]
out = interpreter.get_output_details()[0]
print(f"\\nmodel input  {inp['shape']} {inp['dtype'].__name__}")
print(f"model output {out['shape']} {out['dtype'].__name__}")
assert int(out["shape"][-1]) == NUM_CLASSES, (
    f"Model has {out['shape'][-1]} output classes but taxonomy.py defines "
    f"{NUM_CLASSES}. Wrong model file attached, or taxonomy has drifted - "
    f"stop and check before trusting anything below."
)
''')

# ---------------------------------------------------------------------------
md("""
## 5 · Run inference over every field image

Reproduces the app's own preprocessing exactly: resize to 224x224, divide by
255. If this notebook's numbers do not match what the app actually shows on a
real photo, this is the first place to check for a mismatch.
""")

code('''
def preprocess(path):
    raw = tf.io.read_file(path)
    img = tf.io.decode_image(raw, channels=3, expand_animations=False)
    img = tf.image.convert_image_dtype(img, tf.float32)
    img = tf.image.resize(img, [IMG_SIZE, IMG_SIZE])
    return img.numpy()[None, ...].astype(inp["dtype"])

def softmax(x):
    e = np.exp(x - np.max(x))
    return e / e.sum()

results = []
for i, row in df.iterrows():
    try:
        batch = preprocess(row["path"])
    except Exception as exc:
        continue
    interpreter.set_tensor(inp["index"], batch)
    interpreter.invoke()
    logits = interpreter.get_tensor(out["index"])[0]
    probs = softmax(logits)
    pred_idx = int(np.argmax(probs))
    results.append({
        "true_class": row["class_id"],
        "true_idx": row["label"],
        "pred_class": CLASS_IDS[pred_idx],
        "pred_idx": pred_idx,
        "confidence": float(probs[pred_idx]),
        "correct": pred_idx == row["label"],
    })
    if (i + 1) % 100 == 0:
        print(f"  {i+1}/{len(df)}")

res = pd.DataFrame(results)
print(f"\\nRan inference on {len(res)} images. Overall top-1 accuracy: "
      f"{res['correct'].mean():.1%}")
''')

# ---------------------------------------------------------------------------
md("""
## 6 · The table that actually matters

For each candidate threshold: if the app only trusted predictions AT OR ABOVE
it, what fraction of those trusted predictions would be correct
(**precision**), and what fraction of all correct diagnoses would still get
shown as confident (**coverage**)?

There is no single "right" answer here - it is a real product tradeoff.
A high threshold means the app says "not sure" more often but is rarely wrong
when it does commit. A low threshold means it commits more often but is wrong
more often too. Pick the row whose tradeoff you're willing to stand behind.
""")

code('''
thresholds = [0.30, 0.35, 0.40, 0.45, 0.50, 0.55, 0.60, 0.65, 0.70, 0.75, 0.80, 0.85, 0.90]

print(f"{'threshold':>9}  {'n trusted':>9}  {'precision':>9}  {'coverage':>9}")
rows = []
for t in thresholds:
    trusted = res[res["confidence"] >= t]
    precision = trusted["correct"].mean() if len(trusted) else float("nan")
    coverage = trusted["correct"].sum() / max(1, res["correct"].sum())
    rows.append((t, len(trusted), precision, coverage))
    print(f"{t:>9.2f}  {len(trusted):>9d}  {precision:>9.1%}  {coverage:>9.1%}")

rows_df = pd.DataFrame(rows, columns=["threshold", "n_trusted", "precision", "coverage"])

# A reasoned starting suggestion, not a mandate: the lowest threshold that
# still keeps precision at or above 85%. Below 0.30 or when nothing clears
# 85% precision at all, this intentionally does not guess - look at the full
# table above instead.
candidates = rows_df[rows_df["precision"] >= 0.85]
if len(candidates):
    suggested = candidates["threshold"].min()
    print(f"\\nSuggested confidenceThreshold: {suggested:.2f}")
    print("(lowest threshold that keeps precision at or above 85% on this "
          "field test set - reasoning, not a mandate; use the table above "
          "to pick a different tradeoff if 85% is not the bar you want)")
else:
    print("\\nNo threshold in the tested range reaches 85% precision on this "
          "field test set. Do not round up to a number that sounds safe - "
          "this is telling you the model needs more work before the app "
          "should lean on confidence alone. Report this rather than picking "
          "a threshold that hides it.")
''')

# ---------------------------------------------------------------------------
md("""
## 7 · Where it's actually going wrong

The threshold is a blunt instrument if one or two classes are dragging the
whole number down. Worth knowing which ones before you finalize anything.
""")

code('''
per_class = (res.groupby("true_class")
             .agg(n=("correct", "size"), acc=("correct", "mean"),
                  avg_confidence=("confidence", "mean"))
             .sort_values("acc"))
print(f"{'class':<38} {'n':>4} {'acc':>6} {'avg conf':>9}")
for cls, row in per_class.iterrows():
    flag = "  <-- weak" if row["acc"] < 0.5 else ""
    print(f"{cls:<38} {row['n']:>4.0f} {row['acc']:>6.2f} {row['avg_confidence']:>9.2f}{flag}")
''')

# ---------------------------------------------------------------------------
md("""
## 8 · Apply it

Open `lib/data/local/ml/ml_inference_service.dart` and replace the value of
`confidenceThreshold` with the number from section 6 (or whichever row from
the table you decided fits the tradeoff you want).

Update the comment above it too — replace "PROVISIONAL" with what this
notebook measured, the date, and the precision/coverage at that value, so the
next person (including future you) does not have to re-derive it. Something
like:

```
// Calibrated 2026-XX-XX against N field images (PlantDoc, held out from
// training). At this threshold: XX% precision, XX% coverage.
// See ml/build_calibration_notebook.py.
static const double confidenceThreshold = 0.XX;
```

No other file needs to change. `entropyThreshold` was a separate, deliberate
decision (see the comment above it) and this notebook does not touch it.
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
            "accelerator": "None",
        },
        "nbformat": 4,
        "nbformat_minor": 5,
    }


if __name__ == "__main__":
    nb = build()
    path = os.path.join(HERE, "cropcare_calibrate.ipynb")
    with io.open(path, "w", encoding="utf-8") as f:
        json.dump(nb, f, indent=1, ensure_ascii=False)
    print(f"wrote {path} ({len(nb['cells'])} cells)")
