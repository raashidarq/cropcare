# CropCare — demo video script

Written to be *spoken*, not read aloud verbatim. The sentences are a guide for
what to say and how to pace it — say it in your own words once you've read
through it twice. Total runtime target: **~18 minutes**, leaving margin under
the 20-minute cap. Timings are approximate; the demo section is allowed to run
long if it's going well — that's genuinely the part judges weight most.

Slides referenced below are the ones in the pitch deck. Switch to the actual
running app for the demo section — don't try to demo from a slide.

---

## 1. Introduction — ~30 seconds

*(Slide 1 — title)*

> Hi, I'm **[your name]**, and this is **CropCare** — a crop disease diagnosis
> app for smallholder farmers in Sri Lanka that works fully offline, in three
> languages, and treats AI as an upgrade rather than something the app depends
> on to function.

That's it for the intro. Don't linger — the guidelines want a one-liner here,
and a confident one-liner is a stronger opening than a long wind-up.

---

## 2. Problem and solution — ~2.5 minutes

*(Slides 2–5)*

> Farmers growing tomato, rice, chili, potato, cassava and maize in Sri Lanka
> face crop diseases that spread fast, and by the time damage is visible to
> the eye, it's often already too late to save the crop cheaply. The obvious
> fix — a phone app that photographs a leaf and tells you what's wrong — runs
> into a problem almost every existing tool ignores: **rural connectivity is
> unreliable.** An app that needs the cloud to give you an answer is an app
> that, right when you're standing in the field needing it most, often just
> doesn't answer.

> I know this isn't a marginal problem because of two specific facts.
> [**Pause here and add your own grounding if you have it** — a conversation
> with a farmer, an extension officer, personal experience. If you don't have
> that, the next two points stand on their own.] First, models trained on the
> standard lab-photo datasets score around 99% on their own test data and
> collapse to roughly 31% on real field photographs — that's not a rounding
> error, that's a different app in practice. Second, rice is Sri Lanka's
> staple crop, and the dataset almost every plant-disease app is built on
> contains zero rice classes. The tools that exist weren't built for this
> user or this crop.

> So CropCare's answer is: put the model **on the device**. A photo becomes a
> diagnosis with the radio off. Treatment guidance for every disease the model
> can name is already written and stored on the phone, so the answer doesn't
> wait for a network call. When there *is* a connection, an AI-written version
> of that guidance quietly replaces the local one — better, but never
> required. And when the model genuinely isn't sure, one tap sends the photo
> and result to WhatsApp, to an actual person.

---

## 3. AI-assisted development — ~2.5 minutes

*(Slide 7)*

> This whole project — the Flutter app, the FastAPI backend, and the machine
> learning training pipeline — was built working with **Claude Code** as an
> AI pair-engineer across the entire stack, not just for boilerplate.

> But I want to be specific about *how*, because "I used AI" doesn't tell you
> anything about whether the output can be trusted. Three things:

> First, nothing landed without passing the project's own tests. There are
> **227 automated tests on the Flutter side and 144 on the backend**, and
> both are green right now, at submission time.

> Second, non-obvious decisions are written down, not just made silently.
> There's a file in the repo — `DECISIONS.md` — with **26 recorded
> engineering decisions**, each with the reasoning behind it. That's not
> documentation added after the fact for this submission — it's how the
> project was actually built, and it means I can point at *why* something is
> the way it is, not just *that* it is.

> Third — and this is the one I'm most sure judges will ask about — the AI
> prompts themselves are validated by automated tests, not just read once and
> trusted. There's a test suite that asserts the Gemini prompt actually
> hedges harder when the model's confidence is low, actually refuses
> off-topic questions in chat, actually caps how long each treatment step can
> be. If someone edits that prompt in a way that weakens one of those
> guarantees, the test suite catches it before it ships.

> One concrete example of the process actually working: partway through
> building the model training pipeline, an early field-accuracy evaluation
> looked like it measured something real — a number, a percentage — but on
> inspection it turned out the test set and the training set covered
> completely disjoint disease classes. The "accuracy" number was structurally
> guaranteed to be near zero regardless of how good the model was. That got
> caught and the evaluation was rebuilt before it was ever reported as a real
> result. That's the kind of mistake AI-assisted development can make quickly
> — and also the kind it can catch quickly, if you're actually checking.

---

## 4. Project demonstration — ~9–10 minutes (the main part)

### 4a. System walkthrough — ~5–6 minutes

*(Switch to the live app now — screen recording or a connected device.)*

Walk through it as it actually behaves. Suggested order, but let the app's
own flow guide you more than this list:

1. **Capture a leaf.** Open the camera, show the framing guide. If you have
   a bad photo handy (a desk, a blank wall), show the content gate rejecting
   it — say out loud *why* that matters: the model is a closed-set classifier
   that can't say "I don't know," so this check exists precisely to stop it
   confidently diagnosing a desk.
2. **Diagnosis appears.** Point out it happened with the radio off if you can
   — flight mode is a strong visual if you're comfortable demoing it live.
3. **Treatment guidance is already there.** Say plainly that this came from
   the phone, not the network — then show it get quietly replaced by the
   AI-written version a moment later. This is the single best "look, this
   isn't fake offline-first, watch it happen" moment in the whole demo.
4. **"Not what you see?"** — show the alternative predictions. Frame this
   honestly: the model always has to name *something*, so showing what else
   it considered, and how close it was, is the honest way to present a guess.
5. **Ask a follow-up in chat.** Ask something a farmer would actually ask —
   "can I still eat the fruit?" is a good one. Point out it's scoped to this
   one diagnosis, not a general chatbot.
6. **Escalate via WhatsApp.** Show the message that gets prepared — note that
   it carries the same "this is a guess" framing into the message, because
   the person receiving it on WhatsApp never saw the app's own caveats.
7. **History.** Swipe to delete a scan — mention this is local-only and the
   dialog says so honestly when a synced copy exists elsewhere.
8. **Settings.** Language switch (show Sinhala or Tamil rendering correctly),
   Wi-Fi-only sync toggle, and the guided tutorial replay.

### 4b. Technical implementation — ~1.5 minutes

*(Slide 8 — or narrate over the app if you'd rather not cut away)*

> Under the hood: Flutter for the app, FastAPI on Render for the backend,
> Supabase for accounts and cloud storage, and Gemini for the two things that
> benefit from a real language model — writing treatment guidance and
> answering follow-up questions. The diagnosis itself never touches Gemini —
> that's a TFLite model, MobileNetV3, about six megabytes, running entirely
> on the phone. It covers 34 disease and pest classes across six crops
> actually grown in Sri Lanka, trained on field photography rather than lab
> plates, and it measures roughly 61% top-1 accuracy and 86% top-3 on a
> held-out field test set — which is why the "other possibilities" screen
> exists: the right answer is very often in that list even when it isn't the
> top guess.

> On cost: the app is fully functional at zero API spend, because every
> diagnosable disease already has offline guidance seeded on the device.
> Gemini calls have automatic fallback across models and across API keys, so
> a retired model name or an exhausted free-tier quota degrades gracefully
> instead of taking the feature down.

### 4c. Testing and validation — ~1 minute

> Beyond the 227 and 144 automated tests, I did two things worth mentioning
> specifically. I smoke-tested every release build on a physical Android
> device — installed it, launched it, checked the logs for the kind of silent
> failures that code shrinking can cause. And I verified the live backend by
> calling the deployed API directly over HTTPS, not just trusting local
> tests — which is actually how I found that account creation was returning a
> 404 in production before any other signal caught it.

### 4d. Challenges and current limitations — ~1 minute

> Being direct about what isn't finished: the Sinhala and Tamil translations
> haven't been reviewed by a native speaker yet. The confidence threshold for
> the field-trained model is a reasoned starting value, not yet calibrated
> against measured predictions. And this has been validated technically —
> tested, smoke-tested, verified against the live backend — but it hasn't
> been field-tested with real farmers yet. That's an honest gap, not an
> oversight I'm hoping nobody notices.

---

## 5. Future roadmap — ~1.5 minutes

*(Slide 11)*

> Before this is ready for real-world use, three things come first:
> calibrating that confidence threshold on real measured data, getting a
> native speaker to review the Sinhala and Tamil content, and running an
> actual pilot with farmers rather than relying on automated tests alone.
> After that: broader pest coverage, treatment-reminder notifications so a
> farmer gets nudged to recheck a plant on the day the guidance suggests, and
> the packaging work — a signed release build and a Play Store submission.

*(Slide 12 — close)*

> That's CropCare. Thanks for watching — links to both repositories, the live
> backend, and a downloadable build are in the submission materials.

---

## Delivery notes

- **Don't read this verbatim on camera.** Read it twice beforehand, then talk
  it through in your own words with this open as a guide, not a teleprompter.
  It'll sound more confident than a script read aloud, which is exactly what
  was asked for.
- **The demo section is allowed to run long.** If walking through the app
  well takes 11 minutes instead of 9, that's fine — trim the roadmap section
  instead, not the demo.
- **Say numbers plainly, don't over-hedge them on camera.** The nuance behind
  the 61%/86% field-accuracy figures (how the test set was built, what it
  does and doesn't prove) belongs in a written answer if a judge asks a
  follow-up question, not narrated live — stating it confidently once is
  stronger than qualifying it three times in the same breath.
- **If something breaks live** (a slow cold-start on the backend, a flaky
  connection), don't scramble to hide it — it's a genuine demonstration of
  the offline-first design if the on-device diagnosis keeps working while the
  AI upgrade visibly waits or fails gracefully. That's not a bug to cut
  around, it's the thesis of the project happening in real time.
