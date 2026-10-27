---
name: video-editor
description: "Operate this project's local video editing workflow: learn reference style, review transcription, propose a storyboard, and produce captioned edits after approval. Use for footage and editing tasks in this repository."
---

# Local Video Editor

Read the project's `AGENTS.md` and current private job brief. Use the installed local tools; a new clone does not include the user's media or personal style. Look for `.agents/skills/my-editing-style/SKILL.md`; otherwise analyze references and propose a style before claiming one has been learned.

Keep source footage in `raw/`, references in `references/`, final media in `exports/`, and all job assets, compositions, transcripts and reports in `work/<job>/`. Do not overwrite originals or publish those folders.

## Plan from evidence

- Inspect duration, frame rate, orientation and audio before editing. Confirm orientation with actual frames, not metadata alone.
- Study reference openings, caption grouping and placement, shot length, presenter framing, graphics, color and audio. Separate measurements from estimates and cite source timecodes. Exact fonts, LUTs and isolated audio levels usually cannot be recovered from a rendered reference.
- Default to 1080x1920 and Roman Hinglish while preserving meaning. Original spoken voice only unless the user asks for music, effects or other voices.
- Treat local transcription as a draft. Correct names and technical terms, reject hallucinations and out-of-range times, and ask about genuinely unclear speech. Word timing may need manual adjustment or forced alignment.
- Lead with a strong, truthful hook. Remove dead air and retakes; do not make a reordering that changes meaning, repeats phrases or leaves a dangling clause. Length follows the material.
- Build visuals around the argument. Alternate presenter framing with relevant demonstrations or explanatory graphics where useful. Avoid repeating one static title-and-presenter composition through the entire video.

Show a timestamped storyboard with source ranges, output ranges, exact captions, graphics, reframing and audio treatment. Obtain approval before the final render. A style approval alone does not authorize a new storyboard.

## Build and check

Use `scripts/HyperFrames.ps1` for the pinned local CLI. Read the installed HyperFrames skills before authoring. Put assets inside the private composition; local renders should not depend on runtime asset fetches. Use real supplied product footage or label illustrations honestly. Do not upload assets or activate paid/cloud services without the user's request.

Run composition checks and inspect scene, caption and transition snapshots. Render after approval, then inspect decoded MP4 frames and confirm resolution, aspect ratio, duration and audio. Measure the final audio track rather than assuming the renderer preserved gain. Listen where possible; explicitly distinguish signal measurements from listening if audio audition is unavailable. Save a versioned export and a private review note describing known limits.

For repository work, stage explicit source files and run `python scripts/Audit-Repository.py` before a commit or push. Never include media, learned personal styles, transcripts, uploaded files, binaries or model weights.
