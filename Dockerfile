# --- 第一阶段：构建 ---
FROM maven:3.9.6-eclipse-temurin-17 AS builder
WORKDIR /app

# 优化 1：利用 Docker 层缓存
COPY pom.xml .
RUN mvn dependency:go-offline -B

COPY src ./src
# 优化 2：不需要在 Docker 内部跑 clean，加速构建
RUN mvn package -DskipTests -B

# --- 第二阶段：运行时 ---
# 优化 3：使用更精简的基础镜像（jre 已经足够，jammy 是 Ubuntu 22.04）
FROM eclipse-temurin:17-jre-jammy AS runtime

# 安全最佳实践
RUN apt-get update && apt-get upgrade -y && \
    apt-get install -y --no-install-recommends ca-certificates curl && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN groupadd -r appgroup && useradd -r -g appgroup appuser
WORKDIR /app

# 优化 4：直接拷贝，避免通配符匹配到多个 jar（如果 Maven 配置了 build name）
COPY --from=builder /app/target/*.jar app.jar

RUN chown -R appuser:appgroup /app && \
    chmod -R 550 /app

USER appuser
EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
    CMD curl -f http://localhost:8080/health || exit 1

# 优化 5：Java 17 参数优化，MaxRAMPercentage 建议设为 70-75%
ENTRYPOINT ["java", \
            "-XX:+UseContainerSupport", \
            "-XX:MaxRAMPercentage=75.0", \
            "-XX:+ExitOnOutOfMemoryError", \
            "-Djava.security.egd=file:/dev/./urandom", \
            "-jar", "app.jar"]