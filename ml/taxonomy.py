"""
CropCare model taxonomy: the canonical class list, and how each source
dataset's labels map onto it.

This file is the single source of truth. The training notebook builds its label
space from it, the evaluation harness reports against it, and `emit_dart.py`
generates the Dart class list and disease-id map from it. Change a class here
and everything downstream follows.

-----------------------------------------------------------------------------
Why the class list changed
-----------------------------------------------------------------------------
The shipped model is stock PlantVillage: 38 classes, of which 24 are apple,
blueberry, cherry, grape, orange, peach, raspberry, soybean, squash and
strawberry - temperate crops a Sri Lankan smallholder will never photograph.
It has no rice at all, despite rice being the staple crop and despite the app
already seeding `paddy` with disease rows and a translated treatment guideline.
It has exactly one arthropod class, so pests are effectively unsupported.

The taxonomy below drops the temperate fruit entirely and adds rice and
cassava. The count barely changes; the relevance changes completely.

-----------------------------------------------------------------------------
Why the training data changed
-----------------------------------------------------------------------------
PlantVillage is lab photography - detached leaves on uniform backgrounds. A
model scoring 99.35% on its own test split drops to 31.4% on field images, and
a classifier trained on 8 background pixels alone reaches 49% accuracy, which
means the network is substantially reading the backdrop rather than the leaf.

So PlantVillage is kept only as one source among several, and the field
datasets carry the real weight. PlantDoc is held out of training entirely and
used as the field test set - see `HELD_OUT_SOURCES`. A number that is not
measured on unseen field photographs is not worth reporting.
"""

from __future__ import annotations

from dataclasses import dataclass, field


# ---------------------------------------------------------------------------
# Canonical classes
# ---------------------------------------------------------------------------
@dataclass(frozen=True)
class CropClass:
    """One output class of the model."""

    # Matches the app's `disease` table id convention: {crop}_{condition}.
    id: str
    crop_id: str
    name_en: str

    # 'low' | 'moderate' | 'high' | None. Mirrors disease.severity_default.
    severity: str | None = None

    # True for arthropod damage rather than pathogen infection. The app can
    # word these differently: "pest" and "disease" call for different action,
    # and lumping them under one label was part of why pests went unserved.
    is_pest: bool = False

    healthy: bool = False


def _c(**kw) -> CropClass:
    return CropClass(**kw)


# Ordered. The index of each entry IS the model's output index, so appending
# is safe and reordering is not. `emit_dart.py` relies on this.
CLASSES: list[CropClass] = [
    # -- Rice / paddy ------------------------------------------------------
    # The staple crop, and the app's largest gap: `paddy` is a seeded crop
    # with disease rows and a translated guideline, but the current model
    # cannot predict it at all, so a rice photo returns a confident tomato
    # answer.
    _c(id="paddy_bacterial_leaf_blight", crop_id="paddy",
       name_en="Bacterial Leaf Blight", severity="high"),
    _c(id="paddy_bacterial_leaf_streak", crop_id="paddy",
       name_en="Bacterial Leaf Streak", severity="moderate"),
    _c(id="paddy_bacterial_panicle_blight", crop_id="paddy",
       name_en="Bacterial Panicle Blight", severity="high"),
    _c(id="paddy_blast", crop_id="paddy",
       name_en="Rice Blast", severity="high"),
    _c(id="paddy_brown_spot", crop_id="paddy",
       name_en="Brown Spot", severity="moderate"),
    _c(id="paddy_downy_mildew", crop_id="paddy",
       name_en="Downy Mildew", severity="moderate"),
    _c(id="paddy_tungro", crop_id="paddy",
       name_en="Tungro Virus", severity="high"),
    _c(id="paddy_dead_heart", crop_id="paddy",
       name_en="Stem Borer (Dead Heart)", severity="high", is_pest=True),
    _c(id="paddy_hispa", crop_id="paddy",
       name_en="Rice Hispa", severity="moderate", is_pest=True),
    _c(id="paddy_healthy", crop_id="paddy",
       name_en="Healthy", healthy=True),

    # -- Tomato ------------------------------------------------------------
    _c(id="tomato_bacterial_spot", crop_id="tomato",
       name_en="Bacterial Spot", severity="moderate"),
    _c(id="tomato_early_blight", crop_id="tomato",
       name_en="Early Blight", severity="moderate"),
    _c(id="tomato_late_blight", crop_id="tomato",
       name_en="Late Blight", severity="high"),
    _c(id="tomato_leaf_mold", crop_id="tomato",
       name_en="Leaf Mold", severity="moderate"),
    _c(id="tomato_septoria_leaf_spot", crop_id="tomato",
       name_en="Septoria Leaf Spot", severity="moderate"),
    _c(id="tomato_target_spot", crop_id="tomato",
       name_en="Target Spot", severity="moderate"),
    _c(id="tomato_yellow_leaf_curl_virus", crop_id="tomato",
       name_en="Yellow Leaf Curl Virus", severity="high"),
    _c(id="tomato_mosaic_virus", crop_id="tomato",
       name_en="Mosaic Virus", severity="high"),
    _c(id="tomato_spider_mites", crop_id="tomato",
       name_en="Two-Spotted Spider Mite", severity="moderate", is_pest=True),
    _c(id="tomato_healthy", crop_id="tomato", name_en="Healthy", healthy=True),

    # -- Chili / pepper ----------------------------------------------------
    # PlantVillage's "Pepper,_bell" is the closest available proxy. Noted in
    # the app already (TD-006); it stays a proxy, not a claim of equivalence.
    _c(id="chili_bacterial_spot", crop_id="chili",
       name_en="Bacterial Spot", severity="moderate"),
    _c(id="chili_healthy", crop_id="chili", name_en="Healthy", healthy=True),

    # -- Potato ------------------------------------------------------------
    _c(id="potato_early_blight", crop_id="potato",
       name_en="Early Blight", severity="moderate"),
    _c(id="potato_late_blight", crop_id="potato",
       name_en="Late Blight", severity="high"),
    _c(id="potato_healthy", crop_id="potato", name_en="Healthy", healthy=True),

    # -- Cassava / manioc --------------------------------------------------
    # Widely grown by Sri Lankan smallholders, and the dataset is genuine
    # field survey photography rather than lab plates.
    _c(id="cassava_bacterial_blight", crop_id="cassava",
       name_en="Cassava Bacterial Blight", severity="high"),
    _c(id="cassava_brown_streak", crop_id="cassava",
       name_en="Cassava Brown Streak Disease", severity="high"),
    _c(id="cassava_green_mottle", crop_id="cassava",
       name_en="Cassava Green Mottle", severity="moderate"),
    _c(id="cassava_mosaic", crop_id="cassava",
       name_en="Cassava Mosaic Disease", severity="high"),
    _c(id="cassava_healthy", crop_id="cassava",
       name_en="Healthy", healthy=True),

    # -- Maize -------------------------------------------------------------
    _c(id="corn_gray_leaf_spot", crop_id="corn",
       name_en="Gray Leaf Spot", severity="moderate"),
    _c(id="corn_common_rust", crop_id="corn",
       name_en="Common Rust", severity="moderate"),
    _c(id="corn_northern_leaf_blight", crop_id="corn",
       name_en="Northern Leaf Blight", severity="moderate"),
    _c(id="corn_healthy", crop_id="corn", name_en="Healthy", healthy=True),
]

CLASS_IDS: list[str] = [c.id for c in CLASSES]
CLASS_INDEX: dict[str, int] = {c.id: i for i, c in enumerate(CLASSES)}
NUM_CLASSES = len(CLASSES)

CROPS: list[str] = sorted({c.crop_id for c in CLASSES})


# ---------------------------------------------------------------------------
# Source datasets
# ---------------------------------------------------------------------------
@dataclass
class SourceDataset:
    """A dataset to draw training images from."""

    key: str
    name: str

    # Substrings matched (case-insensitively) against directory names under
    # /kaggle/input, so the notebook works regardless of which mirror of a
    # dataset the user attaches. Exact slugs vary between mirrors and go stale;
    # discovery does not.
    dir_hints: list[str]

    # Maps a source label (a folder name, or a value from a CSV) onto a
    # canonical class id. Anything unmapped is REPORTED, never silently
    # dropped - a quietly discarded third of a dataset is the kind of bug that
    # only shows up as unexplained accuracy loss.
    label_map: dict[str, str] = field(default_factory=dict)

    # Some datasets label via a CSV rather than folder names.
    csv_name: str | None = None
    csv_image_col: str | None = None
    csv_label_col: str | None = None

    # Cassava ships integer labels plus a JSON legend.
    csv_label_is_int: bool = False

    notes: str = ""


PADDY_DOCTOR = SourceDataset(
    key="paddy_doctor",
    name="Paddy Doctor (rice, field)",
    dir_hints=["paddy-disease-classification", "paddy_doctor", "paddy-doctor"],
    csv_name="train.csv",
    csv_image_col="image_id",
    csv_label_col="label",
    notes="Field photography of rice. Closes the app's paddy gap. Two of its "
          "classes (dead_heart, hispa) are insect damage, which gives real "
          "pest coverage for the staple crop without needing IP102.",
    label_map={
        "bacterial_leaf_blight": "paddy_bacterial_leaf_blight",
        "bacterial_leaf_streak": "paddy_bacterial_leaf_streak",
        "bacterial_panicle_blight": "paddy_bacterial_panicle_blight",
        "blast": "paddy_blast",
        "brown_spot": "paddy_brown_spot",
        "downy_mildew": "paddy_downy_mildew",
        "tungro": "paddy_tungro",
        "dead_heart": "paddy_dead_heart",
        "hispa": "paddy_hispa",
        "normal": "paddy_healthy",
    },
)

CASSAVA = SourceDataset(
    key="cassava",
    name="Cassava Leaf Disease (field survey)",
    dir_hints=["cassava-leaf-disease-classification", "cassava"],
    csv_name="train.csv",
    csv_image_col="image_id",
    csv_label_col="label",
    csv_label_is_int=True,
    notes="Collected during a field survey in Uganda; genuinely in-the-wild.",
    label_map={
        "0": "cassava_bacterial_blight",
        "1": "cassava_brown_streak",
        "2": "cassava_green_mottle",
        "3": "cassava_mosaic",
        "4": "cassava_healthy",
    },
)

PLANT_VILLAGE = SourceDataset(
    key="plantvillage",
    name="PlantVillage (lab)",
    dir_hints=["plantvillage", "new-plant-diseases", "plant-village",
               "plant_village"],
    notes="Lab plates on uniform backgrounds. Kept ONLY as extra signal for "
          "classes the field datasets cover thinly. Never the sole source for "
          "a class, and never the test set - see the background-bias note at "
          "the top of this file.",
    label_map={
        "Tomato___Bacterial_spot": "tomato_bacterial_spot",
        "Tomato___Early_blight": "tomato_early_blight",
        "Tomato___Late_blight": "tomato_late_blight",
        "Tomato___Leaf_Mold": "tomato_leaf_mold",
        "Tomato___Septoria_leaf_spot": "tomato_septoria_leaf_spot",
        "Tomato___Target_Spot": "tomato_target_spot",
        "Tomato___Tomato_Yellow_Leaf_Curl_Virus":
            "tomato_yellow_leaf_curl_virus",
        "Tomato___Tomato_mosaic_virus": "tomato_mosaic_virus",
        "Tomato___Spider_mites Two-spotted_spider_mite": "tomato_spider_mites",
        "Tomato___healthy": "tomato_healthy",
        "Pepper,_bell___Bacterial_spot": "chili_bacterial_spot",
        "Pepper,_bell___healthy": "chili_healthy",
        "Potato___Early_blight": "potato_early_blight",
        "Potato___Late_blight": "potato_late_blight",
        "Potato___healthy": "potato_healthy",
        "Corn_(maize)___Cercospora_leaf_spot Gray_leaf_spot":
            "corn_gray_leaf_spot",
        "Corn_(maize)___Common_rust_": "corn_common_rust",
        "Corn_(maize)___Northern_Leaf_Blight": "corn_northern_leaf_blight",
        "Corn_(maize)___healthy": "corn_healthy",
        # Everything else in PlantVillage - apple, blueberry, cherry, grape,
        # orange, peach, raspberry, soybean, squash, strawberry - is
        # deliberately absent. Those crops are not grown by the users this app
        # is for, and carrying them costs accuracy on the ones that are.
    },
)

PLANT_DOC = SourceDataset(
    key="plantdoc",
    name="PlantDoc (field, HELD OUT)",
    dir_hints=["plantdoc", "plant-doc", "plant_doc"],
    notes="Small, in-the-wild, scraped from the internet. Held out of "
          "training entirely and used as the field test set. This is the "
          "number that actually predicts how the app behaves in a field.",
    label_map={
        # PlantDoc folder naming differs between mirrors, so several spellings
        # map to the same class. Unmapped folders are reported at load time.
        "Tomato leaf bacterial spot": "tomato_bacterial_spot",
        "Tomato Early blight leaf": "tomato_early_blight",
        "Tomato leaf late blight": "tomato_late_blight",
        "Tomato leaf mosaic virus": "tomato_mosaic_virus",
        "Tomato leaf yellow virus": "tomato_yellow_leaf_curl_virus",
        "Tomato Septoria leaf spot": "tomato_septoria_leaf_spot",
        "Tomato mold leaf": "tomato_leaf_mold",
        "Tomato two spotted spider mites leaf": "tomato_spider_mites",
        "Tomato leaf": "tomato_healthy",
        "Bell_pepper leaf spot": "chili_bacterial_spot",
        "Bell_pepper leaf": "chili_healthy",
        "Potato leaf early blight": "potato_early_blight",
        "Potato leaf late blight": "potato_late_blight",
        "Potato leaf": "potato_healthy",
        "Corn Gray leaf spot": "corn_gray_leaf_spot",
        "Corn rust leaf": "corn_common_rust",
        "Corn leaf blight": "corn_northern_leaf_blight",
    },
)

SOURCES: list[SourceDataset] = [PADDY_DOCTOR, CASSAVA, PLANT_VILLAGE, PLANT_DOC]

# Never trained on. Reported separately as the field generalisation number.
HELD_OUT_SOURCES = {"plantdoc"}

# Sources whose images are lab plates. Tracked so the notebook can report what
# fraction of each class's training data is lab rather than field - a class fed
# only by PlantVillage should be treated as unproven no matter what its
# validation accuracy says.
LAB_SOURCES = {"plantvillage"}


def summary() -> str:
    lines = [
        f"{NUM_CLASSES} classes across {len(CROPS)} crops: {', '.join(CROPS)}",
        f"{sum(1 for c in CLASSES if c.is_pest)} pest classes, "
        f"{sum(1 for c in CLASSES if c.healthy)} healthy classes",
        "",
        "Sources:",
    ]
    for s in SOURCES:
        held = " [HELD OUT - field test set]" if s.key in HELD_OUT_SOURCES else ""
        lines.append(f"  - {s.name}{held}: {len(s.label_map)} mapped labels")
    return "\n".join(lines)


if __name__ == "__main__":
    print(summary())
