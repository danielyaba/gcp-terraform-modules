import base64
import os
import smtplib
import json
from email.mime.text import MIMEText


def send_email(subject: str, message_body: str) -> None:
    """
    Function for sending emails with a given subject and body.
    """
    # SMTP server details
    smtp_server = os.environ.get('SMTP_SERVER')
    smtp_port = int(os.environ.get('SMTP_PORT', 25))  # Default to port 25 if not provided
    
    email_from = os.environ.get('EMAIL_FROM')
    email_to = os.environ.get('EMAIL_TO')

    # Create the email content
    msg = MIMEText(message_body)
    msg['Subject'] = subject
    msg['From'] = email_from
    msg['To'] = email_to

    # Connect and send the email
    server = smtplib.SMTP(smtp_server, smtp_port)
    server.sendmail(email_from, [email_to], msg.as_string())
    server.quit()


def get_topic_message(event, context) -> None:
    """
    Triggered by a creation of psc interface in VM instance logged to Pub/Sub.
    """
    pubsub_message = base64.b64decode(event['data']).decode('utf-8')
    pubsub_message_dict = json.loads(pubsub_message)
    method = pubsub_message_dict["protoPayload"]["methodName"]
    user = pubsub_message_dict["protoPayload"]["authenticationInfo"]["principalEmail"]
    resource = pubsub_message_dict["protoPayload"]["resourceName"]
    project_id = pubsub_message_dict["resource"]["labels"]["project_id"]

    
    message_body = f"""
Method: {method}
Project ID: {project_id}
User: {user}
Resource: {resource}

"""
    
    # Create the email subject and body
    subject = os.environ.get('SUBJECT')
    disclaimer = os.environ.get('DISCLAIMER')
    message_body = f"{disclaimer}. Details: {message_body}"

    # Send the notification email
    send_email(subject, message_body)