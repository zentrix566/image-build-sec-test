# 多阶段构建 - 第一阶段：构建
FROM maven:3.9.6-eclipse-temurin-17 AS builder

# 设置工作目录
WORKDIR /app

# 复制pom.xml，缓存依赖
COPY pom.xml .
RUN mvn dependency:go-offline -B

# 复制源代码并构建
COPY src ./src
RUN mvn package -DskipTests -Dmaven.test.skip=true

# 多阶段构建 - 第二阶段：运行时
FROM eclipse-temurin:17-jre-jammy AS runtime

# 安全最佳实践：更新系统包，修复已知漏洞
RUN apt-get update && apt-get upgrade -y && \
    apt-get install -y --no-install-recommends ca-certificates && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# 安全最佳实践：创建非root用户运行应用
RUN groupadd -r appgroup && useradd -r -g appgroup appuser

# 设置工作目录
WORKDIR /app

# 从构建阶段复制jar包
COPY --from=builder /app/target/*.jar app.jar

# 安全最佳实践：修改文件权限，让非root用户可以访问
RUN chown -R appuser:appgroup /app && \
    chmod -R 550 /app

# 切换到非root用户
USER appuser

# 暴露端口
EXPOSE 8080

# 健康检查
HEALTHCHECK --interval=30s --timeout=3s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8080/health || exit 1

# 运行应用，添加安全启动参数
ENTRYPOINT ["java", \
            "-Djava.security.egd=file:/dev/./urandom", \
            "-XX:+UseContainerSupport", \
            "-XX:MaxRAMPercentage=75.0", \
            "-Dnetworkaddress.cache.ttl=60", \
            "-jar", \
            "app.jar"]