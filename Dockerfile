# Dockerfile

# --- Stage 1: Base Environment Setup ---
# Use the official AWS Lambda Python 3.12 base image, which includes the
# Lambda Runtime Interface Emulator (RIE) for local testing.
FROM public.ecr.aws/lambda/python:3.12

# Set the working directory in the container.
WORKDIR /var/task

# Install system-level dependencies required by MFA and its underlying libraries.
RUN dnf update -y && \
    dnf install -y \
    libsndfile \
    bzip2 \
    bash \
    findutils \
    && dnf clean all

# --- Stage 2: Install Mambaforge (a Conda installer) ---
# MFA is best installed via Conda, so we install Mambaforge first.
ARG MAMBAFORGE_VERSION="23.11.0-0"
ARG MAMBAFORGE_FILENAME="Mambaforge-${MAMBAFORGE_VERSION}-Linux-x86_64.sh"
RUN curl -fsSL -o Mambaforge.sh "https://github.com/conda-forge/miniforge/releases/download/${MAMBAFORGE_VERSION}/${MAMBAFORGE_FILENAME}" && \
    bash Mambaforge.sh -b -p /opt/conda && \
    rm Mambaforge.sh 

# Add Conda to the system PATH.
ENV PATH="/opt/conda/bin:${PATH}"

# --- Stage 3: Create and Configure the Conda Environment for MFA ---
# Create a dedicated, isolated Conda environment for MFA and its dependencies.
RUN mamba create -n mfa_env python=3.12 -c conda-forge -y && \
    mamba clean --all -f -y 

# CRITICAL: Activate the Conda environment for all subsequent RUN instructions
# and, most importantly, for the Lambda runtime itself.
ENV PATH="/opt/conda/envs/mfa_env/bin:${PATH}"
# Explicitly add the Conda environment's site-packages to PYTHONPATH so the
# Lambda runtime can import packages installed in this environment (e.g., awsgi2).
ENV PYTHONPATH="/opt/conda/envs/mfa_env/lib/python3.12/site-packages"

# --- Stage 4: Install and Configure MFA ---
# Install Montreal Forced Aligner using Mamba into our dedicated environment.
RUN mamba install -c conda-forge montreal-forced-aligner -y && \
    mfa version && \
    mamba clean --all -f -y 

# Download the required MFA models and move them to a stable /opt location.
RUN mfa model download dictionary english_us_arpa && \
    mfa model download acoustic english_us_arpa && \
    mkdir -p /opt/mfa_models && \
    cp /root/Documents/MFA/pretrained_models/dictionary/english_us_arpa.dict /opt/mfa_models/dictionary.dict && \
    cp /root/Documents/MFA/pretrained_models/acoustic/english_us_arpa.zip /opt/mfa_models/acoustic.zip 

# --- Stage 5: Python Application Setup ---
# Copy and install the Python dependencies for our Flask wrapper application.
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy the application source code into the container.
COPY mfa_server.py .
COPY lambda_function.py .
COPY config.yaml .
COPY src/ ./src/

# Set the entry point for the AWS Lambda runtime.
CMD [ "lambda_function.lambda_handler" ]