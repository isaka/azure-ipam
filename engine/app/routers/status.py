from fastapi.responses import JSONResponse

from fastapi import APIRouter

import os

from app.models import *

from app.globals import globals

router = APIRouter(
    prefix="/status",
    tags=["status"]
)

@router.get(
    "",
    summary="Get Azure IPAM Status",
    response_model=Status,
    status_code = 200
)
async def get_status():
    status_message = {
        "status": "OK",
        "version": globals.IPAM_VERSION,
        "container": {
            "image_id": os.environ.get('VITE_CONTAINER_IMAGE_ID'),
            "image_version": os.environ.get('VITE_CONTAINER_IMAGE_VERSION'),
            "image_codename": os.environ.get('VITE_CONTAINER_IMAGE_CODENAME'),
            "image_pretty_name": os.environ.get('VITE_CONTAINER_IMAGE_PRETTY_NAME')
        }
    }

    return JSONResponse(status_message)
