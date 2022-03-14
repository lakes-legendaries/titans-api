FROM python:3.9-slim

# set workdir
WORKDIR /code

# setup unix
RUN apt-get update
RUN apt-get install -y wget

# setup python
COPY requirements.txt .
RUN python -m pip install --upgrade pip
RUN python -m pip install -r requirements.txt
RUN rm requirements.txt
ENV PYTHONPATH .

# setup azcopy
RUN wget https://aka.ms/downloadazcopy-v10-linux -O azcopy.tar
RUN mkdir azcopy
RUN tar xvf azcopy.tar -C azcopy --strip-components=1
RUN mv azcopy/azcopy /usr/bin/azcopy
RUN rm -rfd azcopy.tar azcopy

# setup app
COPY titansapi/ titansapi/
CMD [ \
    "uvicorn", "titansapi.app:app", "--host", "0.0.0.0", "--port", "443", \
    "--ssl-keyfile=./privkey.pem", "--ssl-certfile=./fullchain.pem" \
]

# copy secrets
COPY titans-fileserver .
COPY fullchain.pem .
COPY privkey.pem .
