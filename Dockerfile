FROM python:3.9-slim

# set workdir
WORKDIR /code

# setup python
COPY requirements.txt .
RUN python -m pip install --upgrade pip
RUN python -m pip install -r requirements.txt
RUN rm requirements.txt
ENV PYTHONPATH .

# setup azure cli
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
env AZURE_STORAGE_CONNECTION_STRING $AZURE_STORAGE_CONNECTION_STRING

# setup app
COPY titansapi/ titansapi/
CMD ["uvicorn", "titansapi.app:app", "--host", "0.0.0.0", "--port", "80"]
