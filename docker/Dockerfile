FROM ubuntu:latest

LABEL type_env="ansible"
RUN apt-get update && apt-get install -y openssh-server sudo

# Configurando SSH
RUN mkdir /var/run/sshd
RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config
RUN sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config
RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd

# Adicionando usuário e grupo
RUN groupadd admin
RUN useradd -m -s /bin/bash -G admin ansible
RUN echo 'ansible:ansible' | chpasswd
RUN echo '%admin ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

EXPOSE 22

CMD ["/usr/sbin/sshd", "-D"]