# Stage 1: Build with Maven
FROM maven:3.9.6-eclipse-temurin-21-alpine AS builder
WORKDIR /app
# Copy pom.xml first for dependency caching
COPY pom.xml .
RUN mvn dependency:go-offline -q
# Copy source and build
COPY src ./src
RUN mvn clean package -DskipTests -q

# Stage 2: Run with slim JRE
FROM eclipse-temurin:21-jre-alpine
WORKDIR /app
RUN mkdir -p /tmp/uploads
COPY --from=builder /app/target/*.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", \
  "-Djava.security.egd=file:/dev/./urandom", \
  "-jar", "app.jar"]
