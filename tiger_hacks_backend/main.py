from contextlib import asynccontextmanager

from fastapi import FastAPI

import api
import db


@asynccontextmanager
async def lifespan(_: FastAPI):
    db.init()
    yield
    db.cleanup()


def init_app():
    app = FastAPI(lifespan=lifespan)
    app.include_router(api.router)
    return app

app = init_app()