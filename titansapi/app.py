from typing import Optional

from fastapi import FastAPI


# create app
app = FastAPI()


# root prompt
@app.get("/")
def home():
    return {
        "service": "titans-api",
        "version": "0.0.0",
    }
