FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    python3-venv \
    git \
    pkg-config \
    clang-format \
    cppcheck \
    gcovr

RUN python3 -m venv /opt/venv

ENV PATH="/opt/venv/bin:$PATH"

RUN pip install --upgrade pip

RUN pip install \
    conan

RUN conan profile detect --force

WORKDIR /workspace

COPY . .

RUN conan install . --output-folder=build/conan --build=missing

CMD ["/bin/bash"]
