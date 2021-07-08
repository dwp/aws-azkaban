import requests

from requests import RequestException
from bs4 import BeautifulSoup


class AzkabanService:

    def __init__(self, url, **kwargs):
        self.__url = url
        if "session_id" in kwargs:
            self.__session_id = kwargs["session_id"]
        elif "username" in kwargs and "password" in kwargs:
            self.__username = kwargs["username"]
            self.__password = kwargs["password"]
            self.__session_id = None
        else:
            raise AzkabanException(message="Either 'username' and 'password' or 'session_id' kwargs must be supplied")

        self.__headers = {
            "Content-type": "application/x-www-form-urlencoded",
            "X-Requested-With": "XMLHttpRequest"
        }

    def currently_running(self):
        executing = {}
        for project, flows in self.flows():
            running = [self.running_executions(project, flow) for flow in flows]
            for flow, execution_ids in zip(flows, running):
                if len(execution_ids) > 0:
                    executing[project] = executing[project] if project in executing else {}
                    executing[project][flow] = execution_ids

        return executing

    def running_executions(self, project: str, flow: str):
        try:
            self.__authenticate()
            response = requests.get(f"{self.__url}/executor", params={
                "session.id": self.__session_id,
                "ajax": "getRunning",
                "project": project,
                "flow": flow
            })
            response.raise_for_status()
            body = response.json()
            return body['execIds'] if 'execIds' in body else []
        except RequestException as e:
            raise AzkabanException(cause=e)

    def flows(self):
        projects = self.projects()
        flows = [self.project_flows(project) for project in projects]
        return zip(projects, flows)

    def project_flows(self, project: str):
        try:
            self.__authenticate()
            response = requests.get(f"{self.__url}/manager", params={
                "session.id": self.__session_id,
                "ajax": "fetchprojectflows",
                "project": project
            })
            response.raise_for_status()
            return [x["flowId"] for x in response.json()["flows"]]
        except RequestException as e:
            raise AzkabanException(cause=e)

    def projects(self):
        try:
            self.__authenticate()
            response = requests.get(f"{self.__url}/index?all", params={"session.id": self.__session_id})
            response.raise_for_status()
            soup = BeautifulSoup(response.text, features="html.parser")
            return [x["id"] for x in soup.find_all("div", class_="project-expander")]
        except RequestException as e:
            raise AzkabanException(cause=e)

    def __authenticate(self):
        try:
            if self.__session_id is None:
                response = requests.post(self.__url,
                                         headers=self.__headers,
                                         data={
                                             "action": "login",
                                             "username": self.__username,
                                             "password": self.__password
                                         })
                response.raise_for_status()
                body = response.json()

                if "error" in body:
                    error = body["error"]
                    raise AzkabanException(message=f"Authentication failed: '{error}'.")
                self.__session_id = body["session.id"]
        except RequestException as e:
            raise AzkabanException(cause=e)


class AzkabanException(Exception):
    def __init__(self, **kwargs):
        if "cause" in kwargs:
            self.__cause__ = kwargs["cause"]
        if "message" in kwargs:
            self.message = kwargs["message"]
