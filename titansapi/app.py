from datetime import datetime
import json
import os
from os import remove
from os.path import join
from subprocess import run
from typing import Optional
from urllib.parse import quote_plus

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from titansemail import SendEmails
import yaml

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
key = open(join(secrets_dir, 'titans-fileserver-sas'), 'r').read().strip()


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

    # send welcome email
    try:
        SendEmails(**yaml.safe_load(open('/email/config.yaml', 'r')))
    except Exception:
        pass

    # return status
    return f'Subscribed {email}'


@app.get('/unsubscribe/{email}')
def subscribe(email: str):
    """Unsubscribe form submission"""

    # create file as subscription email
    print('', end='', file=open(email, 'w'))

    # upload to azure
    cmd = (
        f'azcopy cp {email} '
        'https://titansfileserver.blob.core.windows.net/unsubscribe/'
        f'{email}{key}'
    )
    run(cmd.split())

    # clean up
    remove(email)

    # return status
    return f'Unsubscribed {email}'


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

    # send email
    try:
        SendEmails(
            subject='New Question / Comment',
            body=content,
            use_ci=True,
        )

    # upload comments
    finally:

        # write comments to file
        fname = datetime.now().strftime('%Y-%m-%d@%H:%M:%S')
        print(content, file=open(fname, 'w'))

        # upload comments
        cmd = (
            f'azcopy cp {fname} '
            'https://titansfileserver.blob.core.windows.net/comments/'
            f'{fname}{key}'
        )
        run(cmd.split())

        # clean-up
        remove(fname)

    # return status
    return 'Comments emailed and uploaded.'
