from __future__ import annotations

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from src.routes import router


def create_app() -> FastAPI:
    app = FastAPI(title="CourseFlow API", version="1.0.0")

    app.add_middleware(
        CORSMiddleware,
        allow_origins=["*"],
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    if router is not None:
        app.include_router(router, prefix="/api", tags=["courseflow"])

    return app


app = create_app()