# Use a Node.js image as the base
FROM node:18-alpine

WORKDIR /app

# Install necessary packages for building oracledb and for instant client
RUN apk add --no-cache \
    curl \
    unzip \
    libaio-dev \
    build-base \
    python3 \
    git # git might be needed for some npm install processes if dependencies point to git repos

# Download and install Oracle Instant Client Basic and SDK
ARG ORACLE_CLIENT_VERSION=21.14.0.0.0
ARG ORACLE_CLIENT_HOME=/opt/oracle/instantclient_${ORACLE_CLIENT_VERSION}

RUN mkdir -p ${ORACLE_CLIENT_HOME} && \
    curl -o instantclient-basic.zip https://download.oracle.com/otn_software/linux/instantclient/2114000/instantclient-basic-linux.x64-21.14.0.0.0dbru.zip && \
    curl -o instantclient-sdk.zip https://download.oracle.com/otn_software/linux/instantclient/2114000/instantclient-sdk-linux.x64-21.14.0.0.0dbru.zip && \
    unzip instantclient-basic.zip -d ${ORACLE_CLIENT_HOME} && \
    unzip instantclient-sdk.zip -d ${ORACLE_CLIENT_HOME} && \
    rm instantclient-basic.zip instantclient-sdk.zip && \
    mv ${ORACLE_CLIENT_HOME}/instantclient_*/* ${ORACLE_CLIENT_HOME}/ && \
    rmdir ${ORACLE_CLIENT_HOME}/instantclient_*

# Set environment variables for Oracle Instant Client
ENV LD_LIBRARY_PATH=${ORACLE_CLIENT_HOME}:${LD_LIBRARY_PATH}
ENV PATH=${ORACLE_CLIENT_HOME}:${PATH}
ENV OCI_LIB_DIR=${ORACLE_CLIENT_HOME}
ENV OCI_INC_DIR=${ORACLE_CLIENT_HOME}/sdk/include

# Copy package.json and package-lock.json
COPY backend/package*.json ./

# Install Node.js dependencies, including oracledb
RUN npm install

# Copy the rest of the application
COPY backend/ .

# Copy the .env file
COPY backend/.env ./.env

EXPOSE 5000

CMD ["node", "server.js"]