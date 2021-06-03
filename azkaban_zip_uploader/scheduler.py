import logging

import requests
import urllib

class AzkabanScheduler:

    def __init__(self, url: str, environment: str, session_id: str):
        self._url = f"https://{url}:7443/schedule"
        self._environment = environment
        self._session_id = session_id
        self._logger = logging.getLogger(__name__)
        self._logger.setLevel(logging.getLevelName("INFO"))

    def schedule_flows(self, project: str, schedules: dict):
        for flow in schedules.keys():
            self._logger.info(f"Scheduling {project}/{flow}")
            if self._environment in schedules[flow]:
                cron_expression = schedules[flow][self._environment]
                self._logger.info(f"Scheduling {project}/{flow}/{self._environment}, schedule is {cron_expression}")
                self.schedule(project, flow, cron_expression)
            else:
                self._logger.info(f"Scheduling {project}/{flow} no entry for {self._environment}")

    def schedule(self, project, flow, cron_expression):
        data = {
            "session.id": self._session_id,
            "ajax": "scheduleCronFlow",
            "projectName": project,
            "flow": flow,
            "cronExpression": cron_expression
        }
        query = urllib.parse.urlencode(data).encode('utf-8')
        self._logger.info(f"Attempting to post schedule. Data is '{data}', query is '{query}'")
        response = requests.get(self._url, data=query, verify=False)
        self._logger.info(f"Request response '{response.text}' with a status of '{response.status_code}'")
        response.raise_for_status()

