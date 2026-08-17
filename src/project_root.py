from pathlib import Path


def get_project_root():
    """
    Find project root by looking for a marker file.
    """
    current_path = Path.cwd()

    markers = ["setup.py", "README.md", ".git"]

    while current_path != current_path.parent:
        if any((current_path / marker).exists() for marker in markers):
            return current_path

        current_path = current_path.parent

    raise FileNotFoundError("Project root not found")