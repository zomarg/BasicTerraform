FROM mcr.microsoft.com/azure-cli:2.34.1

LABEL maintainer="Gramoz Krasniqi"

# https://github.com/hashicorp/terraform/releases
ARG TERRAFORM_VERSION=1.2.9
ENV TF_DATA_DIR "/.terraform"
#https://github.com/nodejs/node/releases
ARG NODEJS_VERSION=16.14.0
#https://github.com/bridgecrewio/checkov/releases
ARG CHECKOV_VERSION=2.0.925

#https://github.com/terraform-linters/tflint/releases
ARG TFLINT_VERSION=v0.34.1

RUN apk add --no-cache --update sudo && apk add --no-cache ca-certificates bash unzip

# install terraform
WORKDIR /usr/downloads
RUN curl -L https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip --output terraform.zip \
&& unzip terraform.zip \
&& mv terraform /usr/local/bin

#install nodejs
#RUN apk add --update nodejs=${NODEJS_VERSION} npm
RUN apk add --no-cache --update nodejs npm

#install checkov
RUN pip3 install --no-cache-dir --upgrade --ignore-installed pip && pip3 install --no-cache-dir --upgrade setuptools
RUN pip3 install --no-cache-dir checkov==${CHECKOV_VERSION}

#install tflint
RUN curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash

#install powershell https://docs.microsoft.com/en-us/powershell/scripting/install/install-alpine?view=powershell-7.2
RUN apk -X https://dl-cdn.alpinelinux.org/alpine/edge/main add --no-cache lttng-ust

##Download the powershell '.tar.gz' archive
RUN curl -L https://github.com/PowerShell/PowerShell/releases/download/v7.2.6/powershell-7.2.6-linux-alpine-x64.tar.gz -o /tmp/powershell.tar.gz

##Create the target folder where powershell will be placed && Expand powershell to the target folder
RUN mkdir -p /opt/microsoft/powershell/7 && tar zxf /tmp/powershell.tar.gz -C /opt/microsoft/powershell/7

##Set execute permissions && Create the symbolic link that points to pwsh
RUN chmod +x /opt/microsoft/powershell/7/pwsh && ln -s /opt/microsoft/powershell/7/pwsh /usr/bin/pwsh

WORKDIR /usr/src

COPY . .
