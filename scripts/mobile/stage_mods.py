#!/usr/bin/env python3
"""Stages the mods that get packed into the Android build.

Mirrors Hex's own `build-mobile.ps1`: source-only folders are dropped, and the
PNGs of the `hex` mod are converted to ASTC (except the ones the engine needs as
PNG), which keeps texture memory low enough for phones.

Usage: stage_mods.py <out-dir> <mod-dir> [<mod-dir> ...] [--astcenc <path>] [--stamp <text>] [--add <rel>=<file>]

Every <mod-dir> is copied to <out-dir>/<basename>. A `manifest.txt` is written
next to them for `BundledModUtil.java`: first line is the stamp, then one
`<size>\t<path>` line per file.
"""
import argparse, os, shutil, subprocess, sys
from concurrent.futures import ThreadPoolExecutor

SKIP_DIRS = {'.git', '.github', 'cppia-src', 'cppia-charts', 'concept-or-unused'}
SKIP_FILES = {'build.ps1', 'build-mobile.ps1', 'build.sh', 'build.log', '.gitignore', '.gitattributes', 'README.md'}
COMPRESS_MODS = {'hex'}
KEEP_PNG = ['gameplay/looks/', 'gameplay/notestyles/', 'gameplay/songs/', 'ui/fonts/', '_polymod_icon.png']


def keep_png(rel):
    if os.path.basename(rel).startswith('icon-') and rel.endswith('.png'): return True
    for k in KEEP_PNG:
        if (k.endswith('/') and rel.startswith(k)) or rel == k: return True
    return False


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('out')
    ap.add_argument('mods', nargs='+')
    ap.add_argument('--astcenc')
    ap.add_argument('--blocksize', default='8x8')
    ap.add_argument('--quality', default='medium')
    ap.add_argument('--stamp', default='dev')
    ap.add_argument('--jobs', type=int, default=os.cpu_count() or 2)
    ap.add_argument('--add', action='append', default=[], help='<staged path>=<source file>, extra files to put in the bundle')
    args = ap.parse_args()

    if os.path.exists(args.out): shutil.rmtree(args.out)
    os.makedirs(args.out)

    jobs = []
    for mod_dir in args.mods:
        mod = os.path.basename(os.path.normpath(mod_dir))
        for dirpath, dirnames, filenames in os.walk(mod_dir):
            dirnames[:] = sorted(d for d in dirnames if d not in SKIP_DIRS)
            rel_dir = os.path.relpath(dirpath, mod_dir)
            for f in sorted(filenames):
                rel = f if rel_dir == '.' else os.path.join(rel_dir, f).replace(os.sep, '/')
                if rel_dir == '.' and f in SKIP_FILES: continue
                src = os.path.join(dirpath, f)
                dst = os.path.join(args.out, mod, rel)
                os.makedirs(os.path.dirname(dst), exist_ok=True)
                if args.astcenc and f.lower().endswith('.png') and mod in COMPRESS_MODS and not keep_png(rel):
                    jobs.append((src, dst[:-4] + '.astc'))
                else:
                    shutil.copy2(src, dst)

    def encode(job):
        src, dst = job
        r = subprocess.run([args.astcenc, '-cl', src, dst, args.blocksize, '-' + args.quality, '-silent'], capture_output=True, text=True)
        if r.returncode != 0 or not os.path.exists(dst):
            # Fall back to the PNG rather than failing the whole build.
            print(f'astcenc failed on {src}: {r.stderr.strip()}', file=sys.stderr)
            shutil.copy2(src, dst[:-5] + '.png')
        return src

    if jobs:
        print(f'Compressing {len(jobs)} textures to ASTC {args.blocksize}...', flush=True)
        with ThreadPoolExecutor(args.jobs) as pool:
            for i, _ in enumerate(pool.map(encode, jobs), 1):
                if i % 50 == 0 or i == len(jobs): print(f'  {i}/{len(jobs)}', flush=True)

    for item in args.add:
        rel, src = item.split('=', 1)
        dst = os.path.join(args.out, rel)
        os.makedirs(os.path.dirname(dst), exist_ok=True)
        shutil.copy2(src, dst)

    lines = [args.stamp]
    total = 0
    for dirpath, _, filenames in os.walk(args.out):
        for f in sorted(filenames):
            p = os.path.join(dirpath, f)
            rel = os.path.relpath(p, args.out).replace(os.sep, '/')
            if rel == 'manifest.txt': continue
            size = os.path.getsize(p)
            total += size
            lines.append(f'{size}\t{rel}')
    with open(os.path.join(args.out, 'manifest.txt'), 'w', encoding='utf-8') as fh:
        fh.write('\n'.join(lines) + '\n')
    print(f'Staged {len(lines) - 1} files, {total / 1048576:.1f} MB, into {args.out}')


if __name__ == '__main__':
    main()
