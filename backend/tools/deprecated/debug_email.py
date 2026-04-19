import os
from dotenv import load_dotenv

# Test if config.env is loaded properly
print("=== DEBUG EMAIL CONFIGURATION ===")
load_dotenv('config.env')

print(f"MAIL_USERNAME: {os.getenv('MAIL_USERNAME')}")
print(f"MAIL_PASSWORD: {os.getenv('MAIL_PASSWORD')}")
print(f"MAIL_FROM: {os.getenv('MAIL_FROM')}")
print(f"MAIL_SERVER: {os.getenv('MAIL_SERVER')}")
print(f"MAIL_PORT: {os.getenv('MAIL_PORT')}")

# Check if values exist
mail_configured = bool(os.getenv("MAIL_USERNAME") and os.getenv("MAIL_PASSWORD"))
print(f"Email configured: {mail_configured}")

if not mail_configured:
    print("ERROR: Email credentials not found in config.env")
    print("Please check that config.env file exists and contains proper values")
else:
    print("Email configuration found, testing SMTP connection...")
    
    import smtplib
    from email.mime.text import MIMEText
    from email.mime.multipart import MIMEMultipart
    
    try:
        server = smtplib.SMTP(os.getenv("MAIL_SERVER"), int(os.getenv("MAIL_PORT")))
        server.starttls()
        server.login(os.getenv("MAIL_USERNAME"), os.getenv("MAIL_PASSWORD"))
        print("SUCCESS: SMTP authentication successful!")
        
        # Try sending a test email
        msg = MIMEMultipart()
        msg['From'] = os.getenv("MAIL_FROM")
        msg['To'] = "aifaalaa97@gmail.com"
        msg['Subject'] = "Test Email - Smart Cane"
        body = "This is a test email from Smart Cane system."
        msg.attach(MIMEText(body, 'plain'))
        
        server.send_message(msg)
        print("SUCCESS: Test email sent!")
        server.quit()
        
    except Exception as e:
        print(f"ERROR: SMTP connection failed: {e}")
        print(f"ERROR TYPE: {type(e).__name__}")

print("=== END DEBUG ===")
