import os
from os import remove
from subprocess import run
from urllib.parse import quote_plus

from fastapi import FastAPI

from titansapi import __version__


# create app
app = FastAPI()

# read in connection key
key = os.environ['AZURE_KEY']


# root prompt
@app.get('/')
def home():
    return {
        'service': 'titans-api',
        'version': __version__,
    }


@app.get('/subscribe/{email}')
def subscribe(email: str):
    print('', end='', file=open(email, 'w'))
    run(
        (
            f'azcopy cp {email} '
            'https://titansfileserver.blob.core.windows.net/subscribe/'
            f'{email}{key}'
        ).split()
    )
    remove(email)
    return f'Uploaded {email}'
