import unittest
from unittest.mock import patch, call

import requests
from requests import HTTPError

from scheduler import AzkabanScheduler


class AzkabanSchedulerSpec(unittest.TestCase):

    @patch("requests.post")
    def test_schedules_single_flow(self, post):
        post.return_value = self._successful_response()

        scheduler = self._scheduler()
        scheduler.schedule_flows(self._project, {
            self._flow_1: {
                self._environment_1: self._expression_1,
                self._environment_2: self._expression_1
            }
        })

        post.assert_called_once_with(f"{self._url}/schedule", data=self._data_1())

    @patch("requests.post")
    def test_does_not_schedule_other_environments(self, post):
        scheduler = self._scheduler()
        scheduler.schedule_flows(self._project, {
            self._flow_1: {
                self._environment_2: self._expression_1
            },
            self._flow_2: {
                self._environment_2: self._expression_1
            }
        })
        post.assert_not_called()

    @patch("requests.post")
    def test_schedules_multiple_flows(self, post):
        post.return_value = self._successful_response()
        scheduler = self._scheduler()
        scheduler.schedule_flows(self._project, {
            self._flow_1: {
                self._environment_1: self._expression_1
            },
            self._flow_2: {
                self._environment_1: self._expression_2
            }
        })

        call_1 = call(f"{self._url}/schedule", data=self._data_1())
        call_2 = call(f"{self._url}/schedule", data=self._data_2())
        post.assert_has_calls([call_1, call_2])

    @patch("requests.post")
    def test_throws_error_on_failure(self, post):
        post.return_value = self._unsuccessful_response()

        scheduler = self._scheduler()

        self.assertRaises(HTTPError, scheduler.schedule_flows, self._project, {
            self._flow_1: {
                self._environment_1: self._expression_1
            }
        })

    def _successful_response(self) -> requests.Response:
        return self._response(200)

    def _unsuccessful_response(self) -> requests.Response:
        return self._response(500)

    @staticmethod
    def _response(status_code: int) -> requests.Response:
        response = requests.Response()
        response.status_code = status_code
        return response

    def _scheduler(self) -> AzkabanScheduler:
        return AzkabanScheduler(self._url, self._environment_1, self._session_id)

    def _data_1(self):
        return {
            "session.id": self._session_id,
            "ajax": "scheduleCronFlow",
            "projectName": self._project,
            "flow": self._flow_1,
            "cronExpression": self._expression_1
        }

    def _data_2(self):
        return {
            "session.id": self._session_id,
            "ajax": "scheduleCronFlow",
            "projectName": self._project,
            "flow": self._flow_2,
            "cronExpression": self._expression_2
        }

    _url = "https://url"
    _environment_1 = "environment_1"
    _environment_2 = "environment_2"
    _session_id = "session_id"
    _project = "project"
    _flow_1 = "flow_1"
    _flow_2 = "flow_2"
    _expression_1 = "1 * * * *"
    _expression_2 = "2 * * * *"
