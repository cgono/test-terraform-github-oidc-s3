import json
import os
import requests

WEBHOOK_URL = os.environ["WEBHOOK_URL"]

def lambda_handler(event, context):
    findings = event.get('detail', {}).get('findings', [])
    for finding in findings:
        severity = finding.get("severity", "Unknown")
        description = finding.get("description", "No description")
        resource = finding.get("resource", {}).get("s3Object", {}).get("path", "Unknown file")

        message = {
            "text": f"🚨 GuardDuty Malware Finding 🚨\nSeverity: {severity}\nFile: {resource}\nDescription: {description}"
        }

        # POST the finding to the webhook
        response = requests.post(WEBHOOK_URL, json=message)
        response.raise_for_status()

    return {
        'statusCode': 200,
        'body': json.dumps('Webhook sent successfully')
    }