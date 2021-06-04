import unittest
from unittest.mock import patch, call

import requests
import urllib
from requests import HTTPError

from scheduler import AzkabanScheduler


class AzkabanSchedulerSpec(unittest.TestCase):
    _url = "url"
    _port = "7443"
    _environment_1 = "environment_1"
    _environment_2 = "environment_2"
    _session_id = "session_id"
    _project = "project"
    _flow_1 = "flow_1"
    _flow_2 = "flow_2"
    _expression_1 = "1 * * * *"
    _expression_2 = "2 * * * *"
    _headers = {
        "Content-Type": "application/x-www-form-urlencoded"
    }

    @patch("requests.get")
    def test_schedules_single_flow(self, get):
        get.return_value = self._successful_response()

        scheduler = self._scheduler()
        scheduler.schedule_flows(self._project, {
            self._flow_1: {
                self._environment_1: self._expression_1,
                self._environment_2: self._expression_1
            }
        })

        get.assert_called_once_with(f"https://{self._url}:{self._port}/schedule", params=self._data_1().encode('utf-8'), verify=False, headers=self._headers)

    @patch("requests.get")
    def test_does_not_schedule_other_environments(self, get):
        scheduler = self._scheduler()
        scheduler.schedule_flows(self._project, {
            self._flow_1: {
                self._environment_2: self._expression_1
            },
            self._flow_2: {
                self._environment_2: self._expression_1
            }
        })
        get.assert_not_called()

    @patch("requests.get")
    def test_schedules_multiple_flows(self, get):
        get.return_value = self._successful_response()
        scheduler = self._scheduler()
        scheduler.schedule_flows(self._project, {
            self._flow_1: {
                self._environment_1: self._expression_1
            },
            self._flow_2: {
                self._environment_1: self._expression_2,
                self._environment_2: self._expression_1
            }
        })

        call_1 = call(f"https://{self._url}:{self._port}/schedule", params=self._data_1().encode('utf-8'), verify=False, headers=self._headers)
        call_2 = call(f"https://{self._url}:{self._port}/schedule", params=self._data_2().encode('utf-8'), verify=False, headers=self._headers)
        get.assert_has_calls([call_1, call_2])

    @patch("requests.get")
    def test_throws_error_on_failure(self, get):
        get.return_value = self._unsuccessful_response()

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
        return AzkabanScheduler(self._url, self._port, self._environment_1, self._session_id)

    def _data_1(self):
        data = {
            "session.id": self._session_id,
            "ajax": "scheduleCronFlow",
            "projectName": self._project,
            "flow": self._flow_1,
            "cronExpression": self._expression_1
        }
        return urllib.parse.urlencode(data)

    def _data_2(self):
        data = {
            "session.id": self._session_id,
            "ajax": "scheduleCronFlow",
            "projectName": self._project,
            "flow": self._flow_2,
            "cronExpression": self._expression_2
        }
        return urllib.parse.urlencode(data)
