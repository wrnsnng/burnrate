"""Setup script for py2app packaging."""

from setuptools import setup

APP = ["run.py"]
DATA_FILES = []
OPTIONS = {
    "argv_emulation": False,
    "plist": {
        "LSUIElement": True,  # Hide from dock
        "CFBundleName": "Claude Usage",
        "CFBundleIdentifier": "com.claude-usage.app",
        "CFBundleVersion": "1.0.0",
        "CFBundleShortVersionString": "1.0.0",
    },
    "packages": ["rumps", "requests"],
}

setup(
    name="Claude Usage",
    app=APP,
    data_files=DATA_FILES,
    options={"py2app": OPTIONS},
    setup_requires=["py2app"],
)
