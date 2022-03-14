from os import remove
from subprocess import run
from urllib.parse import quote_plus

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from titansapi import __version__


# create app
app = FastAPI()

# allow cors access
app.add_middleware(
    CORSMiddleware,
    allow_headers=["*"],
    allow_methods=["*"],
    allow_origins=[
        'http://titansfileserverdev.z13.web.core.windows.net/',
        'https://titansfileserverdev.z13.web.core.windows.net/'
    ],
)

# read in azure connection key
key = open('titans-fileserver', 'r').read().strip()


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
    cmd = (
        f'azcopy cp {email} '
        'https://titansfileserver.blob.core.windows.net/subscribe/'
        f'{email}{key}'
    )
    run(cmd.split())
    remove(email)
    return f'Uploaded {email}'
