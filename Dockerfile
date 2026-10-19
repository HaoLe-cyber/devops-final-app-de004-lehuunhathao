# syntax=docker/dockerfile:1
# =============================================================================
#  Dockerfile - multi-stage build cho Spring Boot 4 / Java 21 / Gradle
# =============================================================================

# ---------- Stage 1: build - biên dịch & đóng gói bằng Gradle + JDK 21 ----------
FROM gradle:8.14-jdk21-alpine AS build
WORKDIR /workspace

# Copy build files trước để tận dụng cache layer cho dependency
COPY build.gradle settings.gradle ./
RUN gradle --no-daemon dependencies

# Copy mã nguồn rồi đóng gói file JAR (bỏ qua test)
COPY src ./src
RUN gradle --no-daemon bootJar -x test

# ---------- Stage 2: runtime - chỉ chứa JRE 21 + file JAR ----------
FROM eclipse-temurin:21-jre-alpine AS runtime

# Phiên bản ứng dụng truyền vào lúc build (docker compose: build-arg APP_VERSION)
ARG APP_VERSION=dev
ENV APP_VERSION=${APP_VERSION} \
    JAVA_TOOL_OPTIONS="-XX:MaxRAMPercentage=75"

WORKDIR /app

# Chạy ứng dụng bằng user thường, không dùng root
RUN addgroup -S spring && adduser -S spring -G spring
COPY --from=build /workspace/build/libs/app.jar /app/app.jar
USER spring

EXPOSE 8080

# ENTRYPOINT dạng exec (mảng JSON)
ENTRYPOINT ["java", "-jar", "/app/app.jar"]
