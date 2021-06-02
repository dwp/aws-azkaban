import logging

import requests


class AzkabanScheduler:

    def __init__(self, url: str, environment: str, session_id: str):
        self._url = f"{url}/schedule"
        self._environment = environment
        self._session_id = session_id
        self._logger = logging.getLogger(__name__)

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
        response = requests.post(self._url, data=data)
        response.raise_for_status()

