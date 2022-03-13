from os import remove
from subprocess import run

from fastapi import FastAPI

from titansapi import __version__


# create app
app = FastAPI()


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
    run(f'az storage blob upload -c subscribe -f {email} -n {email}'.split())
    remove(email)
