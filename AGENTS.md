# Video Editor Agent

Read `.agents/skills/video-editor/SKILL.md` for video work. Read a privately saved `.agents/skills/my-editing-style/SKILL.md` when present. The `templates/` directory contains starting structures, not an already learned style.

## Workflow
- Inspect `raw/`, the private job brief, and relevant references. Preserve original footage.
- Learn style from references, show evidence with filenames/timecodes, distinguish observations from estimates, and obtain approval before saving a personal style.
- Default to vertical 1080x1920, Roman Hinglish captions, and original voice only. Do not add music, effects or extra voices unless requested. Current user instructions override defaults.
- Transcribe locally, correct names and wording, and review timing. Ask about genuinely unclear speech; do not render invented captions.
- Show a timestamped storyboard with source/output ranges, exact captions, visual actions, reframing and audio treatment. Wait for approval before the final render. Approval of a style is not approval of a storyboard.
- Use varied visuals that explain the narration. Do not turn every sentence into the same static title card. Use actual supplied product footage or clearly identified illustrative diagrams, not fabricated proof.
- Check the actual MP4: decoded frames, duration, aspect ratio, captions, face framing and audio. Distinguish measured audio from a listening review. Save versioned outputs in `exports/`.

## Local tools
Run scripts from this project; they resolve runtime paths relative to the repository. Use `scripts/Setup.ps1`, `scripts/Check-Tools.ps1`, `scripts/Transcribe.ps1`, `scripts/Download-Reference.ps1` and `scripts/HyperFrames.ps1`. Read installed HyperFrames skills before composition changes. Prefer local rendering; publishing, uploads and paid services need user authorization.

## Privacy and repository changes
Keep originals in `raw/`, references in `references/`, final media in `exports/`, and all transcripts, compositions, previews, assets, style breakdowns and session reports in `work/<job>/`. These folders are private and ignored. Learned personal styles are private too.

Never stage media, model weights, downloaded third-party skills, binaries, dependency folders, user uploads, transcripts, screenshots, cookies or credentials. Do not put private session history into tracked documentation. Stage explicit source paths, run `python scripts/Audit-Repository.py`, and inspect the staged diff before a commit or push. Do not bypass the media guard. Respect upstream software and asset licenses; the repository's MIT license does not relicense third-party content.
