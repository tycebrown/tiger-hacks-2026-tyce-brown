from fastapi import APIRouter


router = APIRouter()


@router.post('/user/{id}/one-time-record-measures')
def _(): 
    

@router.post('/user/{id}/get')
def _(): pass

@router.post('/user/{id}/one-time-share/{caretaker_id}')
def _(): pass

@router.post('/user/{id}/share/{caretaker_id}')
def _(): pass

@router.post('/user/{id}/caretakers')
def _(): pass

@router.post('/user/{id}/remove-caretaker/{caretaker_id}')
def _(): pass

@router.websocket('/user/{id}/stream-measures')