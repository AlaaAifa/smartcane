from fastapi import APIRouter, HTTPException, BackgroundTasks
from backend.schemas import MessageReplyRequest
from backend.services.email_service import EmailService

router = APIRouter(prefix="/messages", tags=["Messages"])

@router.post("/reply")
async def reply_to_message(request: MessageReplyRequest, background_tasks: BackgroundTasks):
    try:
        # Use BackgroundTasks to send email asynchronously so the API response is fast
        background_tasks.add_task(
            EmailService.send_reply_email,
            client_email=request.email,
            subject=request.subject,
            reply_body=request.reply_body,
            original_message=request.original_message
        )
        return {"status": "success", "message": "Email queued for sending"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
