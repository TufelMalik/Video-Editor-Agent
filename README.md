# Video Editor Agent

A local, agent-assisted workflow for turning footage into captioned vertical videos. Bring an AI coding agent with access to the project folder, learn an editing style from your references, review a storyboard, and render locally with FFmpeg and HyperFrames.

**Your footage stays outside the published repository.** Raw clips, references, exports, uploaded assets, transcripts, models, dependencies, and session history are ignored by Git and rejected by the repository audit.

This repository provides setup scripts, media helpers, reusable agent instructions, and templates. It is not a standalone editing application or a one-command guarantee of a finished edit. An AI agent performs the creative analysis, transcription review, composition authoring, and quality checks.

## What is included

- **FFmpeg / ffprobe integration:** extract audio, inspect orientation and frame rate, cut footage, and validate exports.
- **Whisper.cpp:** local multilingual transcription with timestamped JSON and SRT output. Hindi/English mixed speech needs review.
- **yt-dlp:** download reference videos when the source permits it; local reference files also work.
- **HyperFrames:** editable HTML compositions, captions, motion graphics, previews, and local MP4 rendering.
- **Agent instructions:** `AGENTS.md` and a project-local `video-editor` skill, usable by agents that can read files and run commands.
- **Media protection:** `.gitignore`, an optional pre-commit hook, and an audit of the actual Git index before publication.

Defaults are 1080x1920 vertical video, Roman Hinglish captions, and voice-only audio. Change these in your project brief. Length follows the footage; do not pad a short recording to a preset duration.

## Requirements

The supplied installer targets **Windows x64 with PowerShell 7+**. The instructions and media workflow can be adapted to other systems; the Windows installer itself does not support them.

| Requirement | Purpose |
|---|---|
| [PowerShell 7](https://github.com/PowerShell/PowerShell) | Run the helper scripts |
| [Node.js 22+](https://nodejs.org/) and npm | HyperFrames; installer uses the pinned npm lockfile |
| [Python 3.10+](https://www.python.org/) with `venv` | Isolated yt-dlp installation and repository checks |
| [Git](https://git-scm.com/) | Clone and manage the source |
| [FFmpeg and ffprobe](https://ffmpeg.org/download.html) on PATH | Media processing and validation |
| Chrome or Chromium | Local HyperFrames preview and rendering |
| An AI coding agent with local folder and command access | Review footage, plan edits, and operate the toolkit |

Existing installations can be reused. If needed, install the prerequisites with Windows Package Manager:

```powershell
winget install --id Microsoft.PowerShell --exact
winget install --id OpenJS.NodeJS.LTS --exact
winget install --id Python.Python.3.12 --exact
winget install --id Git.Git --exact
winget install --id Gyan.FFmpeg --exact
```

Open a fresh PowerShell 7 terminal afterward so the new PATH is visible. Verify `node --version`, `python --version`, `git --version`, `ffmpeg -version`, and `ffprobe -version`.

## Quick start

Clone into an **empty** directory. If `C:\Video Editor Agent` already contains your footage or an earlier setup, choose a new empty folder; do not delete your existing project.

```powershell
git clone https://github.com/TufelMalik/Video-Editor-Agent.git "C:\Video Editor Agent"
Set-Location "C:\Video Editor Agent"
pwsh -File .\scripts\Setup.ps1
pwsh -File .\scripts\Check-Tools.ps1
```

`Setup.ps1`:

1. Checks prerequisites without installing system-wide software.
2. Creates the private working directories without deleting existing content.
3. Creates `.venv` and installs the pinned yt-dlp package there.
4. Runs `npm ci` for the pinned HyperFrames version.
5. Downloads the official Windows Whisper.cpp archive and multilingual model, verifying SHA-256 checksums before use.
6. Installs project-local HyperFrames core skills from the pinned package and pinned upstream registry-skill source.
7. Enables this repository's pre-commit media guard and runs the tool checks.

The default `small` multilingual model is about 488 MB. The optional `medium-q5_0` model is about 539 MB and may be more accurate, but it is slower. Models run locally after download.

```powershell
# Choose the larger model during setup:
pwsh -File .\scripts\Setup.ps1 -Model medium-q5_0

# Reuse matching downloads from an existing installation on this computer:
pwsh -File .\scripts\Setup.ps1 -RuntimeSource "C:\My Existing Video Project"
```

The reuse option copies only the pinned Whisper archive and selected model after checking hashes. It does not copy footage, references, transcripts, or old edits. Runtime downloads and installed third-party skills remain untracked.

For an already downloaded dependency, rerunning setup reuses validated Whisper files. npm and pip still check their pinned dependencies. Internet access is needed for missing packages and upstream skill files.

## Project layout

```text
Video-Editor-Agent/
  AGENTS.md                    Reusable workflow and project defaults
  LICENSE                      MIT license for this repository's original code
  THIRD_PARTY_NOTICES.md        Upstream tools and license boundaries
  package.json / package-lock.json
  requirements.txt             Pinned Python dependency
  scripts/                     Setup, transcription, download, audit, render wrapper
  templates/                   Brief, storyboard, and editing-style templates
  .agents/skills/video-editor/  Reusable agent workflow
  .githooks/pre-commit          Optional media/secret guard; enabled by setup
  raw/                         PRIVATE: original footage
  references/                  PRIVATE: style examples and other reference assets
  exports/                     PRIVATE: final videos and subtitle files
  work/                        PRIVATE: transcripts, compositions, drafts, reports
  uploads/                     PRIVATE: other user uploads
  models/ / tools/             LOCAL: downloaded models and Whisper binaries
  node_modules/ / .venv/        LOCAL: installed dependencies
```

The private and runtime folders are created locally. They are not committed as placeholders. Keep composition assets, fonts, screenshots, and intermediate images inside a job folder under `work/`.

## Start with any local AI agent

Open the cloned folder as the agent's project/workspace. Give it this prompt:

```text
Read AGENTS.md and .agents/skills/video-editor/SKILL.md.
Reuse the installed local tools. Inspect the latest brief and approved style.
Preserve my originals and keep all private assets in ignored folders.
Use voice-only audio unless I explicitly ask otherwise.
Show me a timestamped storyboard and wait for my approval before rendering.
```

An agent's own account, permissions, supported tools, and usage limits still apply. A web-only chat without local file access cannot directly operate this folder. No separate paid media service or transcription API key is required for the local tools in this repository; AI-agent access itself may require a subscription.

### 1. Learn your editing style

Put your reference videos in `references/`, or use the download helper:

```powershell
pwsh -File .\scripts\Download-Reference.ps1 -Url "https://example.com/your-reference-video"
```

Then ask your agent:

```text
Learn the style from references/. Compare the first 3 seconds, pacing,
pause removal, punch-ins, captions, graphics, B-roll, color and audio.
Distinguish observed facts from estimates; cite filenames and timecodes.
Show me a short breakdown. After I approve it, save the reusable style
to .agents/skills/my-editing-style/SKILL.md and use it on future edits.
```

Only create an approved style after review. `templates/my-editing-style.md` is a starting structure, not a pre-learned style. Your learned style and reference-analysis files are intentionally ignored by Git. A new clone will not contain them; transfer them privately if you want another machine or agent to reuse them.

If a site requires login or blocks downloading, provide a local copy you are allowed to use. The helper does not export browser cookies or bypass access controls.

### 2. Add and transcribe footage

Place the original in `raw/`, then run:

```powershell
pwsh -File .\scripts\Transcribe.ps1 -InputVideo ".\raw\your-video.mp4" -Language hi

# For a larger model that has been installed with Setup.ps1:
pwsh -File .\scripts\Transcribe.ps1 -InputVideo ".\raw\your-video.mp4" -Model medium-q5_0 -Language hi
```

Each run creates a unique job under `work/`, with 16 kHz mono audio, full transcription JSON, and a word-segment SRT. You can pass `auto` for language detection or a supported language code.

Machine transcription is a draft. Correct technical names, mixed-language wording and timestamps. Hindi may initially appear in Devanagari; convert captions to Roman Hinglish while preserving the speaker's meaning. Do not translate Hindi into English unless requested. Drop hallucinated text in silence, check timing against the media duration, and ask the user about genuinely unclear words.

### 3. Review the storyboard

```text
Edit raw/your-video.mp4 using my approved editing style.
Use my spoken voice only, Roman Hinglish captions, and 1080x1920 output.
Remove retakes and dead air without changing meaning.
Make the opening strong and use visuals that explain the speech.
Show source ranges, output timestamps, exact caption phrases,
reframing, graphics, B-roll and audio treatment in a storyboard.
Wait for my OK before the final render. Save the final MP4 in exports/.
```

Use `templates/BRIEF.md` and `templates/STORYBOARD.md` inside the private job folder. Storyboard approval is separate from style approval. Any edit that reorders narration must preserve context and avoid repeated or dangling phrases.

### 4. Build, preview and render

The wrapper points HyperFrames at the local Whisper executable without changing the system PATH:

```powershell
.\scripts\HyperFrames.ps1 --help
.\scripts\HyperFrames.ps1 init work/my-edit/composition --resolution portrait --skip-skills
.\scripts\HyperFrames.ps1 check work/my-edit/composition --json
.\scripts\HyperFrames.ps1 snapshot work/my-edit/composition --review
.\scripts\HyperFrames.ps1 preview work/my-edit/composition --background

# After storyboard approval and review:
.\scripts\HyperFrames.ps1 render work/my-edit/composition `
  --quality delivery --workers 1 --output exports/my-edit-v1.mp4
```

Read the installed HyperFrames skills before authoring compositions. Keep timelines seekable and deterministic. Use real supplied assets for product demonstrations; label explanatory diagrams instead of presenting them as real product footage. Do not activate cloud rendering, publishing, paid media generation or uploads without the user's request.

### 5. Check the actual MP4

Inspect decoded frames at scene boundaries, verify captions and face framing, and listen to the rendered audio. A successful render alone is not a quality check.

```powershell
ffprobe -v error -show_entries format=duration:stream=codec_type,codec_name,width,height,avg_frame_rate -of json .\exports\my-edit-v1.mp4
ffmpeg -v error -i .\exports\my-edit-v1.mp4 -f null -
ffmpeg -hide_banner -i .\exports\my-edit-v1.mp4 -vn -af "loudnorm=I=-14:TP=-1.5:LRA=7:print_format=json" -f null -
```

Around -14 LUFS and a true-peak ceiling near -1.5 dBTP are starting points, not universal requirements. Measure the exported track: a renderer or channel conversion can change gain. Preserve final words, avoid abrupt audio cuts, and keep music/effects absent in voice-only projects. If an agent cannot hear audio, it must distinguish measured audio checks from an actual listening review.

## Keep your videos off GitHub

`.gitignore` excludes private folders at any depth and common video, audio, image, font, subtitle, PDF, archive and model extensions. It also excludes installed tools, downloaded third-party skills, credentials, logs and generated session data.

Setup enables a local pre-commit hook. You can enable it manually in this clone:

```powershell
git config core.hooksPath .githooks
```

Before every push, stage only intended source files, then run:

```powershell
python .\scripts\Audit-Repository.py
git diff --cached --name-status
git diff --cached --stat
git status --short
```

The audit examines **every tracked entry in the Git index**, including existing tracked files. It rejects private paths, media/runtime formats, unexpected file types, binary data, files larger than 1 MB, common credential files and recognizable secret patterns. Do not use `git add -f` on private content or bypass the hook.

Gitignore and hooks are guardrails, not a complete secret-scanning or privacy system. Hooks are local to the clone and can be bypassed; do the final staged review. If a private file has already been pushed, adding it to `.gitignore` does not remove it from Git history. Stop pushing and address the exposed content and history separately.

This public source repository contains no raw/reference/export videos, no uploaded media, no learned personal editing style, no session transcripts/storyboards, no model weights, and no bundled tool binaries. Reusability comes from the code, instructions and templates; personal media and learned preferences must be transferred privately.

## Troubleshooting

| Problem | Action |
|---|---|
| A command is missing after installation | Open a fresh terminal; check PATH and `Check-Tools.ps1`. |
| Scripts will not run | Use `pwsh -File ...`. Follow your organization's execution policy; do not disable protection globally. |
| A model fails its hash check | Rerun setup. Only checksum-verified files are installed from the temporary download. |
| Transcription repeats nonsense or extends beyond the video | Review the audio, force the correct language, try the larger multilingual model, and correct the script. Do not render guessed captions. |
| Video appears sideways | Inspect rotation metadata and a decoded frame. Make a corrected working copy only after visually confirming the intended orientation. Preserve the raw file. |
| HyperFrames cannot find Whisper | Use `scripts/HyperFrames.ps1`; it sets the executable path for that process. |
| Rendering is slow or runs out of memory | Start with `--workers 1` and a draft render; close other heavy apps. |
| Optional voice/music/Docker checks fail in `doctor` | They are not required for the default local, voice-only workflow. Check FFmpeg and Chrome separately. |
| A reference cannot be downloaded | Supply a permitted local file in `references/`. |
| Another AI does not discover the skill automatically | Explicitly ask it to read `AGENTS.md`, `.agents/skills/video-editor/SKILL.md`, and your privately saved style. |

## Development

```powershell
python -m unittest discover -s tests -v
python scripts/Audit-Repository.py
```

Tool versions and checksums are recorded in `config/toolchain.json`, `package-lock.json`, and `requirements.txt`. Update those deliberately and recheck the workflow when upgrading dependencies. Do not commit the resulting downloaded packages or models.

## License and credits

Original source code, templates and documentation in this repository are licensed under the **[MIT License](LICENSE)**, copyright **2026 Tufel Malik**. You may use, modify and redistribute that material under the license's terms, including retaining its notice.

Upstream software is separately licensed: HyperFrames, FFmpeg, Whisper.cpp, Whisper models, yt-dlp and their dependencies do **not** become MIT-licensed through this project. See [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) and each upstream distribution's license. This repository does not redistribute those binaries or model weights.

Your footage, reference creators' videos, music, fonts, logos, private uploads and generated assets are not relicensed by this repository. Use assets you own or have permission to use. The workflow was adapted from a user-supplied AI video editor guide; the original PDF and its media are not distributed here.
