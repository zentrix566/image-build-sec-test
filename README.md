# Java 容器镜像构建与安全测试项目

这个项目用于测试Docker镜像分阶段构建和容器安全扫描最佳实践。

## 项目结构

```
├── src/
│   └── main/
│       ├── java/com/example/demoapp/
│       │   └── DemoAppApplication.java   # 主应用类
│       └── resources/
│           └── application.properties    # 配置文件
├── .github/workflows/
│   └── build.yml                         # GitHub Actions 流水线
├── .gitlab-ci.yml                        # GitLab CI 流水线
├── Dockerfile                            # 多阶段构建Dockerfile
├── pom.xml                               # Maven配置
└── README.md                             # 说明文档
```

## 应用功能

这是一个简单的Spring Boot Web应用，包含以下接口：
- `GET /` - 首页，返回欢迎信息
- `GET /health` - 健康检查接口
- `GET /info` - 应用信息接口

## Docker 构建特性

### 多阶段构建
1. **构建阶段**：使用Maven完整镜像进行代码编译和打包
2. **运行阶段**：使用精简的JRE镜像作为运行时，显著减小镜像体积

### 安全最佳实践
- ✅ 基于官方Eclipse Temurin镜像，安全可靠
- ✅ 系统包定期更新，修复已知OS漏洞
- ✅ 使用非root用户运行应用，最小权限原则
- ✅ 文件权限严格控制，防止未授权访问
- ✅ 包含健康检查，便于容器编排平台监控
- ✅ Java安全启动参数，优化容器环境运行

### 构建命令
```bash
# 构建镜像
docker build -t demo-app:latest .

# 运行容器
docker run -p 8080:8080 demo-app:latest

# 访问测试
curl http://localhost:8080
```

## 安全扫描集成

流水线中集成了多种安全扫描工具：

1. **Trivy 镜像扫描** - 扫描OS包和应用依赖的漏洞
2. **Trivy 文件系统扫描** - 扫描源代码中的漏洞和敏感信息
3. **Hadolint Dockerfile 扫描** - 检查Dockerfile最佳实践合规性

## CI/CD 流水线

提供两种流水线配置：

### GitHub Actions (.github/workflows/build.yml)
- 自动构建Java应用
- 构建并推送Docker镜像到GitHub Container Registry
- 自动执行安全扫描，发现高危漏洞时阻断流水线

### GitLab CI (.gitlab-ci.yml)
- 多阶段流水线：构建 → 扫描 → 推送
- 集成相同的安全扫描规则
- 支持GitLab容器镜像仓库

## 安全测试场景

你可以使用这个项目测试以下安全场景：
1. 基础镜像漏洞测试
2. 应用依赖漏洞扫描
3. Dockerfile最佳实践检查
4. 镜像签名验证
5. 运行时安全防护（如Seccomp、AppArmor等）
6. 镜像最小化测试

## 本地安全扫描

### 扫描本地镜像
```bash
# 安装Trivy
brew install aquasecurity/trivy/trivy  # macOS
# 或参考官方文档安装：https://aquasecurity.github.io/trivy/

# 扫描镜像
trivy image demo-app:latest

# 扫描本地文件系统
trivy fs .

# 扫描Dockerfile
docker run --rm -i hadolint/hadolint < Dockerfile
```

## 预期结果

- 正常构建后的镜像大小约为300MB左右
- 安全扫描应该只有少量或没有高危漏洞
- 应用可以正常启动和响应请求
