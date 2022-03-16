from datetime import datetime
import os
from os import remove
from os.path import join
from subprocess import run
from typing import Optional
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
    allow_origins=["*"],
)

# read in azure connection key
secrets_dir = os.environ['SECRETS_DIR']
key = open(join(secrets_dir, 'titans-fileserver'), 'r').read().strip()


@app.get('/')
def home():
    """Root prompt"""
    return {
        'service': 'titans-api',
        'version': __version__,
    }


@app.get('/subscribe/{email}')
def subscribe(email: str):
    """Subscribe form submission"""

    # create file as subscription email
    print('', end='', file=open(email, 'w'))

    # upload to azure
    cmd = (
        f'azcopy cp {email} '
        'https://titansfileserver.blob.core.windows.net/subscribe/'
        f'{email}{key}'
    )
    run(cmd.split())

    # clean up
    remove(email)

    # return status
    return f'Uploaded {email}'


@app.get('/comments/{comments}')
def comment(
    comments: str,
    email: Optional[str] = None,
):
    """Comments form submission"""

    # create email content
    content = comments
    if email:
        content += f'\n\nRespond to: {email}'

    # create email json
    email = {
        'message': {
            'subject': 'New Question / Comment',
            'body': {
                'contentType': 'Text',
                'content': content,
            },
            'toRecipients': [
                {
                    'emailAddress': {
                        'address': 'mike@lakeslegendaries.com',
                    },
                },
            ],
        },
        'saveToSentItems': False,
    }

    # send email
    rez = run(
        ['/code/email/send.sh', email],
        capture_output=True,
        text=True,
    )

    # return status
    return rez
