#!/usr/bin/env python3
"""Installs hmm.json dependencies into a local .haxelib repo without hmm.

Used by the Android CI build and for local setup. Git dependencies are shallow
fetched at their pinned ref; haxelib dependencies are downloaded as zips.
"""
import json, os, subprocess, sys, zipfile, io

root = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
repo = os.path.join(root, '.haxelib')
os.makedirs(repo, exist_ok=True)
deps = json.load(open(os.path.join(root, 'hmm.json')))['dependencies']
skip = set(sys.argv[1:])

def run(*cmd, cwd=None):
    subprocess.run(cmd, cwd=cwd, check=True)

for d in deps:
    name = d['name']
    if name in skip: continue
    lib = os.path.join(repo, name.replace('.', ','))
    if d['type'] == 'git':
        dst = os.path.join(lib, 'git')
        ref = d['ref']
        if os.path.isdir(os.path.join(dst, '.git')):
            head = subprocess.run(['git', 'rev-parse', 'HEAD'], cwd=dst, capture_output=True, text=True).stdout.strip()
            if head.startswith(ref) or ref == head: continue
        else:
            os.makedirs(dst, exist_ok=True)
            run('git', 'init', '-q', cwd=dst)
            run('git', 'remote', 'add', 'origin', d['url'], cwd=dst)
        print(f'[git] {name} @ {ref}', flush=True)
        r = subprocess.run(['git', 'fetch', '-q', '--depth', '1', 'origin', ref], cwd=dst)
        if r.returncode != 0:
            run('git', 'fetch', '-q', 'origin', cwd=dst)
        run('git', '-c', 'advice.detachedHead=false', 'checkout', '-q', '-f', 'FETCH_HEAD' if r.returncode == 0 else ref, cwd=dst)
        run('git', 'submodule', 'update', '--init', '--recursive', '--depth', '1', cwd=dst)
        sub = d.get('dir')
        open(os.path.join(lib, '.dev'), 'w').write(os.path.join(dst, sub) if sub else dst)
        open(os.path.join(lib, '.current'), 'w').write('git')
    else:
        ver = d['version']
        dst = os.path.join(lib, ver.replace('.', ','))
        if not os.path.isdir(dst):
            print(f'[haxelib] {name} {ver}', flush=True)
            url = f'https://haxelib-files.haxe.org/files/3.0/{name.replace(".", ",")}-{ver.replace(".", ",")}.zip'
            data = subprocess.run(['curl', '-fsSL', '--retry', '3', url], check=True, capture_output=True).stdout
            z = zipfile.ZipFile(io.BytesIO(data))
            names = z.namelist()
            # Zips may or may not have a top-level folder; find haxelib.json.
            prefix = min((n[:-len('haxelib.json')] for n in names if n.endswith('haxelib.json')), key=len)
            os.makedirs(dst, exist_ok=True)
            for n in names:
                if not n.startswith(prefix) or n.endswith('/'): continue
                out = os.path.join(dst, n[len(prefix):])
                os.makedirs(os.path.dirname(out), exist_ok=True)
                with open(out, 'wb') as f: f.write(z.read(n))
        open(os.path.join(lib, '.current'), 'w').write(ver)
        dev = os.path.join(lib, '.dev')
        if os.path.exists(dev): os.remove(dev)
print('done')
