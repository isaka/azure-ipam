ARG BUILD_IMAGE=node:18-slim
ARG SERVE_IMAGE=python:3.9-slim

ARG PORT=8080

FROM $BUILD_IMAGE AS builder

# Disable NPM Update Notifications
ENV NPM_CONFIG_UPDATE_NOTIFIER=false

# Set the Working Directory
WORKDIR /tmp

# Add `/app/node_modules/.bin` to $PATH
ENV PATH /tmp/node_modules/.bin:$PATH

# Install UI Dependencies
COPY ./ui/package.json ./
COPY ./ui/package-lock.json ./

RUN npm install
RUN chmod 777 node_modules

# Copy UI Code
COPY ./ui/. ./

# Build IPAM UI
RUN npm run build

FROM $SERVE_IMAGE

ARG PORT

# Set Environment Variable
ENV PORT=${PORT}

# Disable PIP Root Warnings
ENV PIP_ROOT_USER_ACTION=ignore

# Set Working Directory
WORKDIR /tmp

# Install OpenSSH and set the password for root to "Docker!"
RUN apt-get update
RUN apt-get install -qq openssh-server -y \
      && echo "root:Docker!" | chpasswd 

# Enable SSH root login with Password Authentication
# RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/g' /etc/ssh/sshd_config

# Copy 'sshd_config File' to /etc/ssh/
COPY sshd_config /etc/ssh/

RUN ssh-keygen -A
RUN mkdir /var/run/sshd

# Set Working Directory
WORKDIR /ipam

# Install Engine Dependencies
COPY ./engine/requirements.txt /code/requirements.txt

# Upgrade PIP
RUN pip install --upgrade pip --progress-bar off

# Install Dependencies
RUN pip install --no-cache-dir --upgrade -r /code/requirements.txt --progress-bar off

# Copy Engine Code
COPY ./engine/app ./app
COPY --from=builder /tmp/dist ./dist

# Copy Init Script
COPY ./init.sh .

# Set Script Execute Permissions
RUN chmod +x init.sh

# Expose Ports
EXPOSE $PORT 2222

# Execute Startup Script
ENTRYPOINT ./init.sh ${PORT}
