# Serverless Forced Alignment Pipeline with MFA

![Python](https://img.shields.io/badge/Python-3.12-3776AB?style=for-the-badge&logo=python)
![Flask](https://img.shields.io/badge/Flask-000000?style=for-the-badge&logo=flask)
![Conda](https://img.shields.io/badge/Conda-44A833?style=for-the-badge&logo=conda-forge)
![Docker](https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker)
![AWS Lambda](https://img.shields.io/badge/AWS%20Lambda-FF9900?style=for-the-badge&logo=aws-lambda)

## Overview

This project is an engineered solution to the "localization problem" in audio processing: generating hyper-precise, word-level timestamps for an audio file given its transcript. This process, known as forced alignment, is a critical step in automated editing workflows.

The final deliverable is a **containerized, serverless forced alignment service**. It wraps the powerful but complex Montreal Forced Aligner (MFA) toolchain into a simple, on-demand web service deployed on AWS Lambda. The project's development involved a significant engineering challenge: early attempts to parallelize MFA externally led to severe race conditions. The crucial insight was to leverage MFA's own robust, built-in parallelism, which resulted in a complete redesign that was both simpler and perfectly stable.

---

## ⚠️ Portfolio Version Notice

This is a polished, portfolio-ready version of a project developed during a professional internship. The code and architecture are presented as is to showcase the engineering and problem-solving skills involved.

---

## ✨ Key Features

* **Fully Containerized MFA Toolchain**: Packages the entire Conda-based Montreal Forced Aligner (MFA) environment into a portable, self-contained Docker image.
* **Serverless-First Architecture**: Designed for scalable, on-demand, and cost-effective deployment on AWS Lambda.
* **Robust Local Testing**: A complete local testing workflow using the AWS Lambda Runtime Interface Emulator (RIE) included in the base Docker image.
* **Complex Environment Management**: Solves non-trivial `PATH` and `PYTHONPATH` challenges to make a Conda environment function correctly within the standard AWS Lambda runtime.

---

## 🛠️ Tech Stack

* **Core Tool**: Montreal Forced Aligner (MFA)
* **Application**: Python 3.12, Flask
* **Environment & Deployment**: Conda, Docker, AWS Lambda

---

## 🚀 Usage & Local Testing

The service is designed to be tested locally in a manner that perfectly emulates the AWS Lambda environment.

### 1. Build the Docker Image
The `Dockerfile` installs all system dependencies, Conda, MFA, and the required Python packages. The first build can take a significant amount of time (15-20+ minutes).

```bash
docker build -t mfa-lambda-server .
````

### 2\. Run the Local Lambda Emulator

This command runs the container and starts the AWS Lambda Runtime Interface Emulator (RIE), which listens on port 8080 inside the container. We map this to port 9000 on the host machine.

```bash
docker run -p 9000:8080 mfa-lambda-server
```

### 3\. Send a Test Request

In a **new terminal**, you can now invoke the function using `curl`. This request simulates an API Gateway event triggering the Lambda function.

*Note: You must provide a publicly accessible URL to a `.wav` audio file and its exact transcript.*

```bash
curl -X POST "http://localhost:9000/2015-03-31/functions/function/invocations" \
-d '{
  "body": "{\"audio_url\": \"https://storage.example-files.com/public/sample_audio.wav\", \"transcript\": \"The quick brown fox jumps over the lazy dog.\", \"language\": \"en-US\"}"
}'
```

The `docker run` terminal will show the detailed logs from the MFA alignment process, and the `curl` command will return a JSON response containing the word-level timestamps.

-----

## ☁️ Deployment

The container image is designed for deployment to AWS Lambda. The high-level steps are:

1.  Build the Docker image.
2.  Push the image to Amazon Elastic Container Registry (ECR).
3.  Create an AWS Lambda function, selecting "Container image" as the type and providing the ECR image URI.
4.  Configure the function with sufficient memory (\>= 3008 MB) and timeout (e.g., 5 minutes).
5.  Set up a trigger, such as an API Gateway, to invoke the function via HTTP requests.