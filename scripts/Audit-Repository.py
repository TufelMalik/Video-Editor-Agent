#!/usr/bin/env python3
"""Reject private assets and common secrets from every tracked Git-index entry."""
from pathlib import Path, PurePosixPath
import re
import subprocess
import sys

PRIVATE_DIRS = {
    'raw', 'references', 'exports', 'output', 'outputs', 'uploads', 'work',
    'assets', 'media', 'models', 'tools', 'node_modules', '.venv', 'venv',
    'tmp', 'temp', 'transcripts', 'storyboards', '.hyperframes', '.thumbnails',
    '.waveform-cache', '__pycache__', '.pytest_cache', '.git', '.idea', '.vscode',
}
SOURCE_SUFFIXES = {'.md', '.py', '.ps1', '.json', '.txt', '.yml', '.yaml', '.toml'}
SPECIAL_FILES = {'.gitignore', '.gitattributes', 'LICENSE', 'pre-commit'}
SECRET_FILES = {'.env', '.npmrc', '.pypirc', 'credentials', 'id_rsa', 'id_ed25519'}
MAX_BYTES = 1_000_000
SECRET_PATTERNS = [
    re.compile(r'gh[pousr]_[A-Za-z0-9]{30,}'),
    re.compile(r'github_pat_[A-Za-z0-9_]{30,}'),
    re.compile(r'AKIA[A-Z0-9]{16}'),
    re.compile(r'-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----'),
    re.compile(r'(?i)data:(?:image|audio|video)/[^;]+;base64,'),
    re.compile(r'(?i)[a-z]:[\\/]+users[\\/]'),
]


def git(root, *args):
    return subprocess.check_output(['git', '-C', str(root), *args])


def path_problem(name):
    path = PurePosixPath(name)
    parts = [part.casefold() for part in path.parts]
    if any(part in PRIVATE_DIRS for part in parts[:-1]):
        return 'private/generated/runtime directory'
    if len(parts) >= 3 and parts[:2] == ['.agents', 'skills'] and parts[2] != 'video-editor':
        return 'personal or downloaded third-party skill'
    if path.name.casefold() in SECRET_FILES or path.name.casefold().startswith('.env.'):
        return 'credential/environment file'
    if 'cookies' in path.name.casefold():
        return 'cookie file'
    if path.name == 'SETUP-STATUS.md' or path.name.endswith('-style-review.md'):
        return 'private session report'
    if path.name not in SPECIAL_FILES and path.suffix.casefold() not in SOURCE_SUFFIXES:
        return 'not an allowed source/documentation format'
    return None


def audit(root):
    problems = []
    entries = git(root, 'ls-files', '--stage', '-z').split(b'\0')
    for entry in entries:
        if not entry:
            continue
        metadata, encoded_name = entry.split(b'\t', 1)
        mode, object_id, stage = metadata.split()
        name = encoded_name.decode('utf-8', errors='replace')
        problem = path_problem(name)
        if problem:
            problems.append((name, problem))
            continue
        if mode not in {b'100644', b'100755'} or stage != b'0':
            problems.append((name, 'symlink, submodule or unresolved index entry'))
            continue
        # Read the staged blob, not a possibly different working-tree file.
        size = int(git(root, 'cat-file', '-s', object_id.decode()))
        if size > MAX_BYTES:
            problems.append((name, 'larger than the 1 MB source-file limit'))
            continue
        content = git(root, 'cat-file', 'blob', object_id.decode())
        if b'\x00' in content:
            problems.append((name, 'binary data'))
            continue
        try:
            text = content.decode('utf-8-sig')
        except UnicodeDecodeError:
            problems.append((name, 'non-UTF-8 source data'))
            continue
        if any(pattern.search(text) for pattern in SECRET_PATTERNS):
            problems.append((name, 'possible secret, embedded media or personal home path'))
    return problems


def main():
    try:
        root = Path(subprocess.check_output(['git', 'rev-parse', '--show-toplevel'], text=True).strip())
        problems = audit(root)
    except (subprocess.CalledProcessError, ValueError) as exc:
        print(f'Repository audit failed to run: {exc}', file=sys.stderr)
        return 2
    if problems:
        print('Commit/push blocked: remove these files from the Git index before continuing.', file=sys.stderr)
        for name, reason in problems:
            print(f'  {name}: {reason}', file=sys.stderr)
        return 1
    print('Repository audit passed: all tracked index entries are permitted text source files.')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
