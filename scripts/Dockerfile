FROM corpusops/ubuntu-bare:20.04
ADD scripts/apt.txt ./
RUN bash -exc 'set -e \
    && curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
        | gpg --dearmor -o /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) \
        signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
            | tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
    && apt update \
    && apt install -qq $(cat apt.txt) \
    && python3 <(curl -s https://bootstrap.pypa.io/get-pip.py)'
ADD scripts /scripts/
WORKDIR /scripts
RUN python3 -m pip install -r requirements.txt
