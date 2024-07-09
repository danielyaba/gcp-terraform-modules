#!/usr/bin/env python3
import os
import smtplib
import functions_framework
from email.mime.text import MIMEText
from google.auth import default
from googleapiclient.discovery import build


credentials, _ = default()
crm_v1 = build('cloudresourcemanager', 'v1', credentials=credentials)
crm_v2 = build('cloudresourcemanager', 'v2', credentials=credentials)
MANDATORY_LABELS = [
    "business_project_number",
    "created_by",
    "created_date",
    "department",
    "environment",
    "finops_tag",
    "office_name",
    "office_number",
    "owner_email",
    "owner_role",
    "project_name",
    "purchase_order_number",
    "team_email",
    "team_name",
]


def send_email(subject: str, message_body: str) -> None:
    """Function for sending emails with a given subject and body"""

    # SMTP server details
    smtp_server = os.environ.get('SMTP_SERVER')
    smtp_port = int(os.environ.get('SMTP_PORT', 25))  # Default to port 25 if not provided
    
    email_from = os.environ.get('EMAIL_FROM')
    email_to = os.environ.get('EMAIL_TO')

    if not smtp_server and not email_from and not email_from and not email_from:
        return 'Missing environment variables', 400

    # Create the email content
    msg = MIMEText(message_body, "html")
    msg['Subject'] = subject
    msg['From'] = email_from
    msg['To'] = email_to

    # Connect and send the email
    server = smtplib.SMTP(smtp_server, smtp_port)
    server.sendmail(email_from, [email_to], msg.as_string())
    server.quit()


def list_all_projects(folder_number: str) -> list[str]:
    """Function for collecting all projects within a given folder ID"""
    filter=f'parent.type="folder" AND parent.id="{folder_number}"'
    projects_under_folder = crm_v1.projects().list(filter=filter).execute()
    
    all_projects = []
    if "projects" in projects_under_folder:
        all_projects = [project['projectId'] for project in projects_under_folder['projects']]

    parent = f"folders/{folder_number}"
    folders_under_folder = crm_v2.folders().list(parent=parent).execute()
    if not folders_under_folder:
        return all_projects

    folder_ids = [folder['name'].split('/')[1] for folder in folders_under_folder['folders']]

    while folder_ids:
        current_id = folder_ids.pop()
        subfolders = crm_v2.folders().list(parent=f"folders/{current_id}").execute()

        if subfolders:
            folder_ids.extend([folder['name'].split('/')[1] for folder in subfolders['folders']])

        filter=f'parent.type="folder" AND parent.id="{current_id}"'
        projects_under_folder = crm_v1.projects().list(filter=filter).execute()

        if projects_under_folder:
            all_projects.extend([project['projectId'] for project in projects_under_folder['projects']])

    return all_projects


@functions_framework.http
def labels_checker(request) -> None:
    """Function for checking labels in all projects"""
    
    folder_number = os.environ.get('FOLDER_NUMBER')
    folder_name = crm_v2.folders().get(name=f"folders/{folder_number}").execute().get("displayName")
    projects = list_all_projects(folder_number)

    projects_without_labels = []
    projects_without_mandatory_labels = []

    for project in projects:
        project = crm_v1.projects().get(projectId=project).execute()

        if 'labels' not in project: 
            projects_without_labels.append(project['name'])
            continue

        for label in MANDATORY_LABELS:
            if label not in project['labels']:
                projects_without_mandatory_labels.append(project['name'])
                break
    
    if projects_without_labels or projects_without_mandatory_labels:
        message_body = f"""
        <html>
        <body>
            <p>Folder {folder_name} has projects without labels:</p>
        """

        if projects_without_labels:
            message_body += """
            <p>Projects without labels:</p>
            <ul>
        """
            for project in projects_without_labels:
                message_body += f"<li>{project}</li>\n"
            message_body += "</ul>"

        if projects_without_mandatory_labels:
            message_body += """
            <p>Projects without mandatory labels:</p>
            <ul>
        """
            for project in projects_without_mandatory_labels:
                message_body += f"<li>{project}</li>\n"
            message_body += "</ul>"

        message_body += """
        </body>
        </html>
        """
        
        # Send the notification email
        subject = os.environ.get('SUBJECT')
        send_email(subject, message_body)

    return "Finished Successfully", 200