from contextlib import asynccontextmanager

from fastapi import FastAPI

import api
from db import create_tables


@asynccontextmanager
async def lifespan(_: FastAPI):
    create_tables()
    yield
    

def init_app():
    app = FastAPI(lifespan=lifespan)
    app.include_router(api.router)
    return app

app = init_app()