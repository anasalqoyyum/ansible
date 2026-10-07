#!/usr/bin/env python3

import argparse
import os
import shutil
from pathlib import Path


def exists(path):
    return os.path.lexists(path)


def is_directory(path):
    return path.is_dir() and not path.is_symlink()


def find_local_state(source, staged, target, local_paths):
    # Keep dependencies beside managed code so imports through symlinks resolve.
    if staged.name == "node_modules":
        return []
    if staged in local_paths or not exists(source):
        return [(staged, target)]
    if not is_directory(source) or not is_directory(staged):
        return []
    result = []
    for child in sorted(staged.iterdir()):
        result.extend(
            find_local_state(
                source / child.name, child, target / child.name, local_paths
            )
        )
    return result


def find_folded_state(source, staged, target, local_paths):
    if not is_directory(staged):
        return []
    if target.is_symlink():
        if target.resolve() == staged.resolve():
            return find_local_state(source, staged, target, local_paths)
        return []
    if not is_directory(target):
        return []
    result = []
    for child in sorted(staged.iterdir()):
        result.extend(
            find_folded_state(
                source / child.name, child, target / child.name, local_paths
            )
        )
    return result


def validate_parent(target, staged, home):
    if target == home:
        return
    validate_parent(target.parent, staged.parent, home)
    if target.is_symlink():
        if target.resolve() != staged.resolve() or not is_directory(staged):
            raise ValueError(f"Refusing to replace unrelated directory link: {target}")
    elif exists(target) and not is_directory(target):
        raise ValueError(f"Not a directory: {target}")


def unfold_parent(target, staged, home):
    if target == home:
        return
    unfold_parent(target.parent, staged.parent, home)
    if target.is_symlink():
        children = list(staged.iterdir())
        target.unlink()
        target.mkdir(mode=staged.stat().st_mode & 0o777)
        for child in children:
            (target / child.name).symlink_to(os.path.relpath(child, target))
    elif not target.exists():
        target.mkdir(mode=staged.stat().st_mode & 0o777)


def normalize_absolute_links(staged, target, dry_run):
    if staged.name == "node_modules":
        return
    if target.is_symlink():
        if os.readlink(target) == str(staged):
            if not dry_run:
                target.unlink()
                target.symlink_to(os.path.relpath(staged, target.parent))
            print(f"{'Would make relative' if dry_run else 'Made relative'} {target}")
        return
    if is_directory(staged) and is_directory(target):
        for child in sorted(staged.iterdir()):
            normalize_absolute_links(child, target / child.name, dry_run)


def preserve(source, dotfiles, home, dry_run=False):
    moves = []
    if not dotfiles.exists():
        return
    local_paths = {
        dotfiles / pattern.strip("/")
        for pattern in (source / ".sync-exclude").read_text().splitlines()
        if pattern.startswith("/")
    }
    packages = [
        package
        for package in sorted(dotfiles.iterdir())
        if is_directory(package) and not package.name.startswith(".")
    ]
    for package in packages:
        for child in sorted(package.iterdir()):
            moves.extend(
                find_folded_state(
                    source / package.name / child.name,
                    child,
                    home / child.name,
                    local_paths,
                )
            )

    # Validate every destination before changing any links or moving local files.
    for staged, target in moves:
        validate_parent(target.parent, staged.parent, home)
        if exists(target) and target.resolve() != staged.resolve():
            raise ValueError(f"Refusing to overwrite local state: {target}")

    for staged, target in moves:
        if not dry_run:
            unfold_parent(target.parent, staged.parent, home)
            if target.is_symlink():
                target.unlink()
            shutil.move(str(staged), str(target))
        print(f"{'Would preserve' if dry_run else 'Preserved'} {target}")

    for package in packages:
        for child in sorted(package.iterdir()):
            normalize_absolute_links(child, home / child.name, dry_run)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--source", required=True, type=Path)
    parser.add_argument("--dotfiles", required=True, type=Path)
    parser.add_argument("--target", required=True, type=Path)
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()
    source = args.source.resolve()
    dotfiles = args.dotfiles.resolve()
    home = args.target.resolve()
    if not source.is_dir() or dotfiles.parent != home or dotfiles == source:
        parser.error(
            "Expected a source directory and a separate dotfiles directory directly under the target home"
        )
    try:
        preserve(source, dotfiles, home, args.dry_run)
    except ValueError as error:
        parser.exit(1, f"{error}\n")


if __name__ == "__main__":
    main()
