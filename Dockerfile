# ---------- Stage 1: Build the WAR using Maven ----------
FROM maven:3.8.5-openjdk-8 AS builder

WORKDIR /app

# Copy only pom.xml first for caching dependencies
COPY pom.xml .

# Pre-download dependencies
RUN mvn dependency:go-offline

# Copy the rest of the source code
COPY src ./src

# Package the WAR file
RUN mvn clean package

# ---------- Stage 2: Deploy WAR to Tomcat ----------
FROM tomcat:8.5-jdk8-openjdk

# Remove default webapps
RUN rm -rf /usr/local/tomcat/webapps/*

# Copy built WAR file from builder stage
COPY --from=builder /app/target/*.war /usr/local/tomcat/webapps/ROOT.war

EXPOSE 8080

CMD ["catalina.sh", "run"]

