# CLAUDE.md

本文件为 Claude Code (claude.ai/code) 在此仓库中工作提供指引。

## 构建、测试、检查

```bash
# 运行所有测试（无需腾讯云连接即可跑核心服务测试）
flutter test

# 运行单个测试文件
flutter test test/services/encryption_service_test.dart

# 静态检查（info 级别也会导致 exit code 1，只有 error 需要关注）
flutter analyze

# 在 macOS 上运行
flutter run -d macos

# 构建发布版本
flutter build macos --release     # macOS .app
flutter build apk --release       # Android .apk
flutter build windows --release   # Windows .exe
```

**Flutter 安装路径：** `/opt/homebrew/bin/flutter`，如直接运行 `flutter` 命令找不到，请使用完整路径。

## 架构

**跨平台剪切板同步工具，端到端加密。** Flutter 前端，腾讯云开发 (CloudBase) 后端，通过云函数 HTTP 端点通信。支持 macOS、Android、Windows，iPad/iOS 通过快捷指令 + Web App 补充。

### 整体架构

```
Flutter App
    ↓ HTTP POST (JSON)
云函数 (Node.js + @cloudbase/node-sdk)
    ↓ cloud.init({ env: process.env.SCF_ENV })
腾讯云数据库 (Firestore)
```

- **云函数地址：** `https://universal-clipboard-d7b1c6cd31bc-1446090713.ap-shanghai.app.tcloudbase.com/api`
- **云函数代码：** 腾讯云开发控制台 → 云函数 → `api` → 函数代码
- **数据库集合：** `devices`、`clipboard`、`history`（需手动创建，权限选 ADMINWRITE）

### 入口与路由

- `lib/main.dart` — 应用入口。用 `MultiProvider` 包裹组件树启动 App。
- `lib/app.dart` — `MaterialApp`，3 个命名路由：`/unlock` → `/home` → `/settings`。

### Provider 状态层

- `AuthProvider` — 生成设备 ID + 设备注册。通过 `LocalStorage` 在本地存储 `deviceId`/`deviceName`。
- `SettingsProvider` — 自动同步开关、历史记录条数限制。底层使用 `SharedPreferences`。
- `ClipboardProvider` — **核心调度器。** 持有 `SyncService`、`ClipboardMonitor`、`HistoryService`、`EncryptionService`。管理同步循环（500ms 轮询）、多选拼接状态、以及所有剪切板读写（含循环防护）。

### 数据流（复制 → 同步 → 粘贴）

```
[设备 A 复制内容]
    ↓ ClipboardMonitor 检测变化（桌面端 500ms 轮询，Android 原生监听）
    ↓ _onClipboardChanged() → 防抖 500ms → _uploadContent()
    ↓ SyncService.uploadContent()：SHA256 哈希 → AES-256-GCM 加密 → 调用云函数写入数据库
    ↓
[其他设备通过 _startSyncLoop() 每 500ms 轮询云函数]
    ↓ SyncService.downloadLatestContent()：跳过自己的上传或过期数据 → 解密 → 返回
    ↓ ClipboardProvider 写入系统剪切板（先暂停监听器防止循环同步）
    ↓ 条目加入 HistoryService
```

### 云函数 API

云函数通过 HTTP POST 接收 JSON 请求，支持以下 action：

| action | 参数 | 说明 |
|--------|------|------|
| `ping` | 无 | 健康检查 |
| `addDocument` | `collection`, `data` | 创建文档，返回 id |
| `setDocument` | `collection`, `docId`, `data` | 覆盖或创建文档 |
| `getDocument` | `collection`, `docId` | 获取单个文档 |
| `queryDocuments` | `collection`, `filter?`, `orderBy?`, `descending?`, `limit?` | 查询文档列表 |
| `updateDocument` | `collection`, `docId`, `data` | 部分更新文档 |
| `deleteDocument` | `collection`, `docId` | 删除文档 |

**注意：** `data` 参数是 JSON 字符串（需 `jsonEncode`），`filter` 也是 JSON 字符串。

### 加密

- `EncryptionService` 在 `lib/services/encryption_service.dart` — AES-256-GCM（基于 pointycastle）。密钥通过 PBKDF2-HMAC-SHA256 派生（10 万次迭代）。`EncryptedData` 将 IV + 密文打包为单个 base64 字符串。
- 主密码在 `UnlockScreen` 输入。Salt 存储在数据库 `clipboard/salt`。所有设备使用相同密码即可派生相同密钥。

### 剪切板监听

- `ClipboardMonitor` 在 `lib/services/clipboard_monitor.dart` — 桌面端：`Timer.periodic` 每 500ms 检查 `Clipboard.getData()`。Android：通过 `MethodChannel` 调用原生 `ClipboardManager.OnPrimaryClipChangedListener`。提供 `pause()`/`resume()` 方法，在将接收到的数据写入剪切板时暂停监听以防止循环同步。

### 腾讯云数据模型

```
devices/{deviceId}        — 设备信息
clipboard/current         — 最新剪切板条目（已加密）
clipboard/salt            — PBKDF2 密钥派生盐值
history/{entryId}         — 剪切板历史记录（已加密）
```

数据库集合需手动在腾讯云控制台创建，权限选 ADMINWRITE（云函数用管理员权限访问）。

### 同步去重

- 上传：明文 SHA256 与 `_lastUploadedHash` 比对 — 相同则跳过。
- 下载：时间戳比对 + 来源设备检查 — 跳过自己的上传和过期数据。

### 多选拼接

- `ClipboardProvider` 维护 `_isMergeMode`、`_selectedIds`（有序集合）、`_mergeSeparator`。
- `MergeBar` 组件显示实时拼接预览和分隔符下拉选择器（换行、逗号、分号、空格）。
- 复制拼接内容：用选定的分隔符将已选条目的内容拼接为一个字符串写入剪切板。

### 测试说明

核心服务测试（加密、历史记录、数据模型）不依赖腾讯云，可直接运行。UI 测试需要网络连接，当前以 smoke test 为主。`test/widget_test.dart` 包含核心模型和服务的基础验证。

### 新建数据库集合

腾讯云控制台 → 云开发 → 数据库 → 新建集合：
1. `devices` — 权限 ADMINWRITE
2. `clipboard` — 权限 ADMINWRITE
3. `history` — 权限 ADMINWRITE
