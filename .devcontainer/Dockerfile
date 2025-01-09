# Retrieve the Terraform version
ARG TERRAFORM_VERSION

# Utilise une image officielle Terraform
FROM hashicorp/terraform:${TERRAFORM_VERSION}

# Met à jour le système et installe les dépendances nécessaires
RUN apk update && apk add --no-cache git zsh curl wget unzip nano

# Installation of OhMyZsh (cause it's cool)
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Create vscode user
RUN adduser -D vscode

# Create the home for the user vscode, and adjust the permissions
RUN mkdir -p /home/vscode && \
    chown vscode:vscode /home/vscode

# Configure the OhMyZsh (cause it's cool)
USER root
RUN cp -r /root/.oh-my-zsh /home/vscode/ && \
    cp /root/.zshrc /home/vscode/.zshrc && \
    chown -R vscode:vscode /home/vscode/.oh-my-zsh /home/vscode/.zshrc

# Configure the Aussiegeek theme for OhMyZsh (cause it's nice)
RUN sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="aussiegeek"/g' /home/vscode/.zshrc

# Change the default shell
RUN sed -i 's#/bin/sh#/bin/zsh#g' /etc/passwd

# Back to user vscode
USER vscode

# Start the ZSH shell
CMD ["zsh"]