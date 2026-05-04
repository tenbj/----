# -*- mode: python ; coding: utf-8 -*-


a = Analysis(
    ['E:\\my_project\\知识研究\\output\\05_工作区初始化工具_202605032303\\src\\init_workspace.py'],
    pathex=[],
    binaries=[],
    datas=[('E:\\my_project\\知识研究\\output\\05_工作区初始化工具_202605032303\\src\\templates', 'templates')],
    hiddenimports=[],
    hookspath=[],
    hooksconfig={},
    runtime_hooks=[],
    excludes=[],
    noarchive=False,
    optimize=0,
)
pyz = PYZ(a.pure)

exe = EXE(
    pyz,
    a.scripts,
    a.binaries,
    a.datas,
    [],
    name='初始化工作区_v1.2.0',
    debug=False,
    bootloader_ignore_signals=False,
    strip=False,
    upx=True,
    upx_exclude=[],
    runtime_tmpdir=None,
    console=False,
    disable_windowed_traceback=False,
    argv_emulation=False,
    target_arch=None,
    codesign_identity=None,
    entitlements_file=None,
)
