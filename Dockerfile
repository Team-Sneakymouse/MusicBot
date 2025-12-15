# Build stage
FROM eclipse-temurin:11-jdk as builder

WORKDIR /build

# Copy pom.xml first (for better layer caching)
COPY pom.xml .

# Download dependencies (this layer will be cached unless pom.xml changes)
RUN apt-get update && apt-get install -y maven && \
    mvn dependency:go-offline -B

# Copy source code
COPY src ./src

# Build the application
RUN mvn --batch-mode --update-snapshots verify && \
    mv target/*-All.jar /build/JMusicBot-Snapshot-All.jar

# Runtime stage
FROM eclipse-temurin:11-jre-alpine
RUN apk add --no-cache libstdc++

WORKDIR /musicbot

VOLUME ["/musicbot"]

# Copy the built JAR from the builder stage
COPY --from=builder /build/JMusicBot-Snapshot-All.jar /JMusicBot-Snapshot-All.jar

CMD ["sh", "-c", "cp -f /JMusicBot-Snapshot-All.jar /musicbot/ && /opt/java/openjdk/bin/java -Dconfig=/musicbot/config/config.txt -Dnogui=true -jar /musicbot/JMusicBot-Snapshot-All.jar"]
