# UU Wine macOS Host

在无 Metal 的 Intel Mac 上，通过 Wine 运行官方 Windows 版网易 UU 远程被控端。另一台机器使用官方 UU 客户端连接。项目维护 macOS 桌面采集器和 Wine 兼容补丁，登录、设备注册、身份验证和媒体传输由官方 UU 处理。

## 工作原理

- 采集器用 CoreGraphics 和 IOSurface 发布主屏 BGRA 像素。Wine 的 Mac 显示驱动从私有三缓冲读取，提供给 Windows GDI。
- Wine 将被控进程的 Windows SendInput 请求交给 macOS Core Graphics。用户需在系统设置中授予屏幕录制和辅助功能权限。
- Wine 在缺少事件日志发布者元数据时返回标准 Windows 错误，避免触发未实现函数导致的退出。

## 实测范围

在 2011 Mac mini、Intel HD 3000、macOS Ventura 13.7.8、Wine 11.0 和 Windows UU 4.46.0.4716 上，用另一台 Mac 的官方 UU 验证了动态桌面、鼠标点击和英文输入。实现覆盖主屏幕，适用于用户已登录的图形会话。其他硬件、系统、UU 版本以及完整键盘映射有待验证。

## 构建

使用安装了 Xcode Command Line Tools 的 Intel Mac。准备 Wine 11.0 源码、Bison 3 或更新版本、LLVM MinGW 和独立的 x86_64 Wine 11.0 运行目录。可从 WineHQ 下载源码，Windows UU 安装包从网易官方渠道获取。

从本项目目录编译采集器。

```sh
mkdir -p build
xcrun clang -fobjc-arc -Isrc src/stream.m \\
  -framework Foundation -framework CoreGraphics -framework CoreVideo \\
  -framework IOSurface -o build/uu-capture
```

按文件名顺序在干净的 Wine 11.0 源码树上用 `patch -p1` 应用 `patches/` 中的三个补丁。使用与目标运行时匹配的 Wine 配置构建 `dlls/winemac.drv/winemac.so`、`dlls/user32/x86_64-windows/user32.dll` 和 `dlls/wevtapi/x86_64-windows/wevtapi.dll`。如果 Mac 驱动链接了未解析的同目录库路径，用 `otool -L` 检查，在独立运行时中将对应依赖指向同目录的 `ntdll.so`、`win32u.so`，以该运行时的链接布局为准。

将构建产物放入独立运行时的对应架构目录，保留自己的原文件备份。使用同一运行时初始化全新的 Wine 前缀，再安装官方 Windows UU。对已有前缀，确保 `drive_c/windows/system32` 中的 64 位 `user32.dll` 和 `wevtapi.dll` 也与补丁版一致。

## 启动

先用 Finder 或终端进入自己的图形会话。在独立前缀中按官方流程安装 Windows UU 和内置 WebView2 引导程序。设置 `WINEPREFIX` 为该前缀，设置 `UU_WINE_BIN` 为独立 Wine 的 `bin` 目录，然后运行 `bash run.sh`。在 Windows UU 界面登录自己的账号，再从官方控制端选中这个 Windows 设备。使用 Control-C 结束该前缀的服务和采集器。

## 上游与许可

Wine 衍生补丁适用 Wine 的 LGPL 条款，见 `licenses/Wine-COPYING.LIB`。缓冲布局参考 panxuc/uur 的 MIT 许可实现，许可证和版权声明随源码保留。本仓库为独立兼容性项目，UU 客户端由网易提供。

- [WineHQ 源码](https://gitlab.winehq.org/wine/wine/-/tree/wine-11.0)
- [panxuc/uur 固定版本](https://github.com/panxuc/uur/tree/8d8bff5e0f98f5c195ee58cac043aa6f301a17e7)
- [网易 UU 远程官网](https://uuyc.163.com/)
