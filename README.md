# spring-petclinic-jenkins

## Preparing the Application and Spinning Up Jenkins

**1.** First, make sure you are logged in to GitHub in any web browser. Then fork the [Spring PetClinic](https://github.com/spring-projects/spring-petclinic) repository (the example application we’ll use).

**2.** Clone your fork locally.

```
$ git clone https://github.com/shanemacbride/spring-petclinic.git 
$ cd spring-petclinic
```
**3.** Start up Docker. Our Jenkins container will make use of it. Use [Liatrio’s Alpine-Jenkins image](https://github.com/liatrio/alpine-jenkins), which is specifically configured for using Docker in pipelines. 

````
$ docker run -p 8080:8080 -v 
/var/run/docker.sock:/var/run/docker.sock liatrio/jenkins-alpine
````

**4.** Wait for the image to download and run. 
Jenkins by clicking New Item, naming it, and selecting Pipeline. Creating a new pipeline in Jenkins

**5.** Configure the pipeline to refer to GitHub for source control management by selecting Pipeline script from SCM. Set the repository URL to your fork of Spring PetC the pipeline.

**6.** Save the job.

## Creating a Dockerfile That Runs Our Java Application

**1.**  Create a file named Dockerfile using your favorite text editor. Start with a Java image, so specify Anapsix’s Alpine Java image as our [base image](https://docs.docker.com/engine/reference/builder/#from).

````
FROM [--platform=<platform>] <image> [AS <name>]
FROM anapsix/alpine-java
````
**2.** Specify who the maintainer of this image should be using a [maintainer label](https://docs.docker.com/engine/reference/builder/#maintainer-deprecated).

````
LABEL org.opencontainers.image.authors="SvenDowideit@home.org.au"
LABEL maintainer="shanem@liatrio.com"
````
**3.** Ensure the image has the Spring PetClinic on it so it can be run. When Spring PetClinic is built, the Jar will be placed in a target directory. We simply need to copy that into the image.
````
COPY /target/spring-petclinic-1.5.1.jar /home/spring-petclinic-1.5.1.jar
````
**4.** Run Spring PetClinic when the container starts up.
**5.** Commit this new file. We aren’t pushing any changes yet because we still need to create a Jenkinsfile for the Pipeline job to execute correctly.

````
$ git add Dockerfile 
$ git commit -m 'Created Dockerfile'
````

## Creating a Basic Jenkinsfile

**1.** Create a Jenkinsfile . First, create the file named Jenkinsfile and specify the first stage. In this stage, we are telling Jenkins to use a Maven image, specifically version 3.5.0, to build Spring PetClinic.

````
#!groovy
pipeline {
	agent none
  stages {
  	stage('Maven Install') {
    	agent {
      	docker {
        	image 'maven:3.5.0'
        }
      }
      steps {
      	sh 'mvn clean install'
      }
    }
  }
}
````

**2.** Run our Pipeline job created before. Make sure to push the Jenkinsfile up to GitHub beforehand. You can run the job by clicking on the clock icon to the right. It should successfully install Spring PetClinic using the Maven image.
````
$ git add Jenkinsfile 
$ git commit -m 'Created Jenkinsfile with Maven Install Stage'
$ git push
````

## Adding a Docker Build Stage to the Jenkinsfile

**1.** Confirm Spring PetClinic is successfully installing. Then package our application inside an image using the Dockerfile created previously. 

````
#!groovy

pipeline {
	agent none
  stages {
  	stage('Maven Install') {
    	agent {
      	docker {
        	image 'maven:3.5.0'
        }
      }
      steps {
      	sh 'mvn clean install'
      }
    }
    stage('Docker Build') {
    	agent any
      steps {
      	sh 'docker build -t image:spring-petclinic:latest .' #(from DockerHub)
      }
    }
  }
}
````

**2.** Ensure the image was successfully built (it should be if the updated Jenkinsfile is pushed up to GitHub and the job is run again).

````
$ git add Jenkinsfile$ git commit -m 'Added Docker Build Stage'
$ git push
$ # Run the Jenkins job which will execute this new stage and wait for it to finish...
$ docker images
````

**3.** Verify that our Dockerfile was working as expected now that we’ve built our image by running our new image with port 8080, the port that the Java servlet runs on, forwarded to port 8081. We do this because our Alpine-Jenkins container is already running on port 8080. After it spins up, we should be able to see Spring PetClinic in a web browser at localhost:8081. Awesome!

````
$ docker run -p 8081:8080 shanem/spring-petclinic
````

##  Credentials 

**1.** Add your Docker Hub credentials into Jenkins. First, click on Credentials from the Jenkins home page. Click on Credentials from the Jenkins home page on the left.

**2.** Click Add credentials under the global drop down menu.

**3.** Enter your Docker Hub credentials. Make sure to use only your Docker Hub username and not your email address. These credentials will be referenced in the Jenkinsfile using their ID value. Hit OK.
Enter your Docker Hub credentials.
Finally, the last stage will be added to our Jenkinsfile that pushes our image up to Docker Hub.

## Adding a Docker Push Stage to the Jenkinsfile
**1.** Create this stage using any agent because we don’t need to run our Docker CLI commands in a specific image. 

````
#!groovy

pipeline {
	agent none  stages {
  	stage('Maven Install') {
    	agent {
      	docker {
        	image 'maven:3.5.0'
        }
      }
      steps {
      	sh 'mvn clean install'
      }
    }
    stage('Docker Build') {
    	agent any
      steps {
      	sh 'docker build -t shanem/spring-petclinic:latest .'
      }
    }
    stage('Docker Push') {
    	agent any
      steps {
      	withCredentials([usernamePassword(credentialsId: 'dockerHub', passwordVariable: 'dockerHubPassword', usernameVariable: 'dockerHubUser')]) {
        	sh "docker login -u ${env.dockerHubUser} -p ${env.dockerHubPassword}"
          sh 'docker push shanem/spring-petclinic:latest'
        }
      }
    }
  }
}
````

**2.** Commit these changes, push them up to the GitHub repository, and trigger our Pipeline job to build in Jenkins.$ git add Jenkinsfile

````
$ git add Jenkinsfile
git commit -m 'Added Docker Push Stage'
$ git push
$ # Run the Jenkins job which will execute this new stage and wait for it to finish...
````
