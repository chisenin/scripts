# TS → MP4 批量转换工具（Windows）

拖入 .ts 文件或文件夹 → 自动并行转换为 .mp4 → 转换成功后**自动删除原 .ts 文件**

## 主要功能

- 支持**拖放**单个 .ts 文件 或 整个文件夹
- 递归处理文件夹内所有 .ts 文件
- 使用 **ffmpeg** 进行无损流复制转换（极快）
- 自动修复常见 AAC 音频问题（`-bsf:a aac_adtstoasc`）
- **并行处理**：根据 CPU 核心数智能分配任务（通常占用 25%–50% 线程）
- 转换成功后**自动删除**原始 .ts 文件
- 显示实时进度、成功/失败统计、整体耗时与处理速率

## 系统要求

- Windows 10 / 11（64位推荐）
- 已安装 **ffmpeg** 并添加到系统环境变量 PATH  
  （可从 https://www.gyan.dev/ffmpeg/builds/ 下载 git master builds 的 `ffmpeg-release-full.7z`）
- PowerShell 5.1 或更高版本（Windows 10/11 自带）

## 使用方法

### 方法一：拖放（推荐）

1. 把 `ts2mp4.bat` 和 `ts2mp4.ps1` 放在同一个文件夹
2. 选中一个或多个 `.ts` 文件 或 文件夹
3. 拖放到 `ts2mp4.bat` 图标上松开
4. 等待处理完成（黑色命令行窗口）

### 方法二：命令行

```bash
ts2mp4.bat  "C:\Videos\录像1.ts"
ts2mp4.bat  "D:\录播"
ts2mp4.bat  file1.ts file2.ts folderA folderB
```

## 输出说明

转换后文件会出现在**原文件相同位置**，扩展名变为 `.mp4`。

示例：

```
video_2025-02-10_19-30.ts    →    video_2025-02-10_19-30.mp4
```

成功转换的文件会被**自动删除**，失败的文件会保留。

## 运行结束后显示示例

```
==============================
处理完成
成功: 124
失败: 1
耗时: 387.4 秒
速率: 0.32 文件 / 秒
==============================
```

## 常见问题

**Q：没有反应 / 闪退？**  
A：确认 ffmpeg 是否正确安装并加入 PATH。可以在命令提示符输入 `ffmpeg -version` 测试。

**Q：转换后的 mp4 没有声音？**  
A：极少数情况下原始 ts 文件音频格式有严重问题，可尝试去掉 `-bsf:a aac_adtstoasc` 参数再试。

**Q：想保留原始 .ts 文件？**  
A：把脚本里的 `Remove-Item "$inputFile" -Force` 这一行注释掉即可。

**Q：想转换其他格式（如 mkv）？**  
A：修改 `$outputFile = [System.IO.Path]::ChangeExtension($inputFile, ".mp4")` 中的后缀，以及 ffmpeg 参数即可。

## 推荐 ffmpeg 参数进阶用法（自行修改脚本）

# 只复制视频 + 中文音频 + 中文字幕（示例）
```powershell
& ffmpeg -i "$inputFile" -map 0:v -map 0:a:m:language:chi? -map 0:s? -c copy -bsf:a aac_adtstoasc "$outputFile" -y -loglevel error
```

祝使用愉快～  
有问题欢迎 issue 或直接留言。

最后更新：2026/2/13
