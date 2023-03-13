FROM openjdk:17-jdk-slim-buster

WORKDIR /app
COPY .mvn/ .mvn
COPY mvnw pom.xml ./
RUN ./mvnw dependency:resolve
COPY src ./src

ARG JAR_FILE=target/*.jar
COPY ./target/spring-petclinic-3.0.0-SNAPSHOT.jar app.jar

EXPOSE 8080
ENTRYPOINT ["java","-jar","./app.jar"]
