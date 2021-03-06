FROM microblinkdev/centos-ninja:1.9.0 as ninja
FROM microblinkdev/centos-ccache:3.7.5 as ccache
FROM microblinkdev/centos-git:2.24.0 as git
FROM microblinkdev/centos-python:3.8.0 as python
FROM microblinkdev/centos-clang:9.0.0

COPY --from=ninja /usr/local/bin/ninja /usr/local/bin/
COPY --from=python /usr/local /usr/local/
COPY --from=git /usr/local /usr/local/
COPY --from=ccache /usr/local /usr/local/

RUN yum -y install zlib-devel zlib-static make && \
    echo "bind '\"\\e[A\": history-search-backward'" >> ~/.bashrc && \
    echo "bind '\"\\e[B\": history-search-forward'" >> ~/.bashrc && \
    echo "bind \"set completion-ignore-case on\"" >> ~/.bashrc

ENV NINJA_STATUS="[%f/%t %c/sec] "

# create gcc/g++ symlinks in /usr/bin (compatibility with legacy clang conan profile)
# and also replace binutils tools with LLVM version
RUN ln -s /usr/local/bin/clang /usr/bin/clang && \
    ln -s /usr/local/bin/clang++ /usr/bin/clang++ && \
    rm /usr/bin/nm /usr/bin/ranlib /usr/bin/ar && \
    ln /usr/local/bin/llvm-ar /usr/bin/ar && \
    ln /usr/local/bin/llvm-nm /usr/bin/nm && \
    ln /usr/local/bin/llvm-ranlib /usr/bin/ranlib && \
    ln -s /usr/local/bin/ccache /usr/bin/ccache

ARG CMAKE_VERSION=3.15.5

# download and install CMake
RUN cd /home && \
    curl -o cmake.tar.gz -L https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}-Linux-x86_64.tar.gz && \
    tar xf cmake.tar.gz && \
    cd cmake-${CMAKE_VERSION}-Linux-x86_64 && \
    find . -type d -exec mkdir -p /usr/local/\{} \; && \
    find . -type f -exec mv \{} /usr/local/\{} \; && \
    cd .. && \
    rm -rf *

ARG CONAN_VERSION=1.18.5

# download and install conan and LFS and set global .gitignore
RUN python3 -m pip install conan==${CONAN_VERSION}
