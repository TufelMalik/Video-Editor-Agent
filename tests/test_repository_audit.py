import importlib.util
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('audit', ROOT / 'scripts/Audit-Repository.py')
audit = importlib.util.module_from_spec(spec)
spec.loader.exec_module(audit)


class AuditTests(unittest.TestCase):
    def setUp(self):
        self.scratch = ROOT / 'work' / 'audit-tests'
        self.scratch.mkdir(parents=True, exist_ok=True)
        self.temp = tempfile.TemporaryDirectory(dir=self.scratch)
        self.root = Path(self.temp.name)
        subprocess.run(['git', 'init', '-q', str(self.root)], check=True)
        subprocess.run(['git', '-C', str(self.root), 'config', 'core.autocrlf', 'false'], check=True)

    def tearDown(self):
        self.root.resolve().relative_to(self.scratch.resolve())
        self.temp.cleanup()

    def stage(self, name, content=b'example text\n'):
        target = self.root / name
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(content)
        subprocess.run(['git', '-C', str(self.root), 'add', '-f', '--', name], check=True)

    def test_accepts_source_and_reads_index_not_worktree(self):
        self.stage('README.md')
        self.stage('scripts/example.ps1')
        (self.root / 'README.md').write_bytes(b'\0not staged')
        self.assertEqual(audit.audit(self.root), [])

    def test_rejects_private_paths_even_text_and_forced_add(self):
        for name in ['raw/notes.md', 'nested/References/notes.md', 'outputs/report.json',
                     'work/transcript.json', '.agents/skills/my-editing-style/SKILL.md']:
            self.stage(name)
        self.assertEqual(len(audit.audit(self.root)), 5)

    def test_rejects_media_outside_private_folders(self):
        for name in ['clip.Mp4', 'recording.MOV', 'voice.wav', 'caption.srt', 'guide.pdf', 'image.png']:
            self.stage(name)
        self.assertEqual(len(audit.audit(self.root)), 6)

    def test_rejects_binary_and_oversized_text(self):
        self.stage('bad.json', b'{\0}')
        self.stage('huge.md', b'a' * (audit.MAX_BYTES + 1))
        self.assertEqual(len(audit.audit(self.root)), 2)

    def test_rejects_credentials_and_token_content(self):
        self.stage('.env', b'DEMO=value')
        self.stage('settings.json', ('{"token":"' + 'gh' + 'p_' + 'a' * 40 + '"}').encode())
        self.assertEqual(len(audit.audit(self.root)), 2)

    def test_gitignore_blocks_nested_and_mixed_case_media(self):
        shutil.copyfile(ROOT / '.gitignore', self.root / '.gitignore')
        names = ['raw/a.md', 'other/References/a.json', 'anywhere/movie.Mp4',
                 'voice.WAV', 'outputs/data.json', 'uploads/doc.txt',
                 '.agents/skills/my-editing-style/SKILL.md', 'models/model.bin']
        for name in names:
            result = subprocess.run(['git', '-C', str(self.root), 'check-ignore', '--no-index', name], capture_output=True)
            self.assertEqual(result.returncode, 0, name)
        allowed = subprocess.run(['git', '-C', str(self.root), 'check-ignore', '--no-index', '.agents/skills/video-editor/SKILL.md'], capture_output=True)
        self.assertEqual(allowed.returncode, 1)


if __name__ == '__main__':
    unittest.main()
