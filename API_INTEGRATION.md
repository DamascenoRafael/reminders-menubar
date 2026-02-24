# API Integration Guide

这个指南说明如何在 reminders-menubar 项目中添加 REST API 功能。

## 已添加的文件

以下文件已添加到项目中：

```
reminders-menubar/
└── reminders-menubar/Services/API/
    ├── APIResponse.swift              # API 响应模型
    ├── APIServer.swift                # 简单的 HTTP 服务器
    ├── APIServer+Swifter.swift        # 完整的 Swifter 版本（推荐）
    └── APIServer+AppDelegate.swift     # AppDelegate 集成代码
```

## 集成步骤

### 1. 添加 Swifter 依赖（推荐）

在 Xcode 中：

1. 打开项目：`reminders-menubar.xcodeproj`
2. 选择项目导航器中的项目
3. 选择 "reminders-menubar" 目标
4. 点击 "Package Dependencies" 标签
5. 点击 "+" 添加包
6. 输入：`https://github.com/httpswift/swifter.git`
7. 选择版本，添加到 "reminders-menubar" 目标

### 2. 使用简单版本（无需额外依赖）

如果你不想添加外部依赖，可以使用 `APIServer.swift` 中的简单实现。

### 3. 修改 AppDelegate.swift

在 `AppDelegate.swift` 中添加以下代码：

```swift
// 在文件顶部添加
private var apiServer: APIServer?

// 在 applicationDidFinishLaunching 中添加
// 在 configureDidCloseNotification() 之后添加：

// Start API Server
apiServer = APIServer.shared
apiServer?.start(port: 3000)

// 在 applicationWillTerminate 中添加（如果没有，创建这个方法）
func applicationWillTerminate(_ aNotification: Notification) {
    apiServer?.stop()
}
```

### 4. 添加 API 文件到 Xcode 项目

1. 在 Xcode 项目导航器中，右键点击 `Services` 文件夹
2. 选择 "Add Files to reminders-menubar..."
3. 选择 `Services/API` 文件夹下的所有 `.swift` 文件
4. 确保勾选 "Copy items if needed" 和 "Add to targets: reminders-menubar"

## 使用 Swifter 完整版本（推荐）

要使用完整的 API 功能，请：

1. 重命名或删除 `APIServer.swift`
2. 将 `APIServer+Swifter.swift` 重命名为 `APIServer.swift`
3. 取消注释文件中的所有代码

## API 端点

启动应用后，API 将在 `http://localhost:3000` 可用：

| 方法 | 端点 | 描述 |
|------|------|------|
| GET | `/` | API 信息 |
| GET | `/health` | 健康检查 |
| GET | `/api/v1/status` | 授权状态 |
| GET | `/api/v1/lists` | 获取所有列表 |
| GET | `/api/v1/reminders` | 获取提醒（支持 filter 参数） |
| POST | `/api/v1/reminders` | 创建提醒 |
| POST | `/api/v1/reminders/:id/complete` | 完成提醒 |
| DELETE | `/api/v1/reminders/:id` | 删除提醒 |

## 测试

```bash
# 测试 API
curl http://localhost:3000/
curl http://localhost:3000/health
curl http://localhost:3000/api/v1/status
curl http://localhost:3000/api/v1/lists
```

## 注意事项

1. **权限**：应用需要提醒事项权限才能正常工作
2. **端口**：默认使用 3000 端口，确保端口未被占用
3. **沙盒**：如果应用使用 App Sandbox，需要确保网络权限已开启

## 故障排除

如果 API 服务器无法启动：

1. 检查端口 3000 是否被占用：`lsof -i :3000`
2. 查看 Xcode 控制台日志
3. 确保所有 Swift 文件已正确添加到目标
