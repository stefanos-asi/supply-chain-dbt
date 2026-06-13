import os
import requests
from dagster import run_failure_sensor, RunFailureSensorContext


@run_failure_sensor(monitor_all_code_locations=True)
def slack_on_failure(context: RunFailureSensorContext):
    webhook_url = os.getenv("SLACK_WEBHOOK_URL")
    if not webhook_url:
        context.log.warning("No SLACK_WEBHOOK_URL configured — skipping notification")
        return

    run = context.dagster_run
    job_name = run.job_name
    run_id = run.run_id

    message = {
        "text": f":rotating_light: *Pipeline failure*",
        "blocks": [
            {
                "type": "header",
                "text": {"type": "plain_text", "text": "🚨 Supply Chain Pipeline Failed"}
            },
            {
                "type": "section",
                "fields": [
                    {"type": "mrkdwn", "text": f"*Job:*\n{job_name}"},
                    {"type": "mrkdwn", "text": f"*Run ID:*\n`{run_id[:8]}`"},
                ]
            },
            {
                "type": "section",
                "text": {"type": "mrkdwn", "text": f"*Failure:*\n```{context.failure_event.message[:500]}```"}
            }
        ]
    }
 
    response = requests.post(webhook_url, json=message, timeout=10)
    if response.status_code != 200:
        context.log.error(f"Slack notification failed: {response.text}")