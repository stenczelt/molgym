FROM python:3.9.12-bullseye

RUN apt-get update --yes && \
    apt-get install --yes \
      cmake \
      libeigen3-dev \
      libboost-all-dev \
--

# install Sparrow # RUN cd /opt
WORKDIR /opt
RUN git clone https://github.com/qcscine/sparrow.git --branch=2.0.1 --single-branch --depth 1

WORKDIR /opt/sparrow
RUN git submodule init && git submodule update
RUN mkdir build install

WORKDIR /opt/sparrow
RUN cmake -B build \
        -DCMAKE_BUILD_TYPE=Release  \
        -DCMAKE_INSTALL_PREFIX=install \
        -DSCINE_BUILD_PYTHON_BINDINGS=ON

RUN cmake --build ./build
RUN cmake --install ./build

ENV PATH="/opt/sparrow/install/bin:$PATH"

# install python dependencies
WORKDIR /work
COPY requirements.txt .
# for some reason torch-scatter is not installing correctly from the
# requirements file, it needs torch to be separately installed before
RUN pip install torch
RUN pip install torch-scatter
RUN pip install \
    ase \
    numpy  \
    scipy  \
    matplotlib \
    pandas \
    quadpy  \
    schnetpack  \
    gym  \
--
RUN pip install git+https://github.com/risilab/cormorant.git@6a4b6370e8a7cfd7bf253ecfb5783b6d7787ba3f#egg=cormorant

# link sparrow for python
ENV PYTHONPATH=$PYTHONPATH:/opt/sparrow/install/lib/python3.9/site-packages
ENV SCINE_MODULE_PATH=/opt/sparrow/install/lib

# install this package as well
COPY molgym/ molgym/
COPY scripts/ scripts/
COPY tests/ tests/
COPY setup.py .
COPY README.md .
RUN pip install .