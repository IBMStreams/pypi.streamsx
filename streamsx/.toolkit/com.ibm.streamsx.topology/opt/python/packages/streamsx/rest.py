# Licensed Materials - Property of IBM
# Copyright IBM Corp. 2016
import requests
import os
import json
import logging

from .rest_primitives import Domain, Instance, Installation, Resource, StreamsRestClient
from .rest_errors import ViewNotFoundError
from pprint import pformat
from requests.packages.urllib3.exceptions import InsecureRequestWarning

requests.packages.urllib3.disable_warnings(InsecureRequestWarning)

logger = logging.getLogger('streamsx.rest')


class StreamsConnection:
    """Creates a connection to a  running Streams installation and exposes methods to retrieve the state of that instance.

    Streams maintains information regarding the state of its resources. For example, these resources could include the
    currently running Jobs, Views, PEs, Operators, and Domains. The StreamsConnection provides methods to retrieve that
    information.

    Example:
        >>> _resource_url = "https://streamsqse.localdomain:8443/streams/rest/resources"
        >>> sc = StreamsConnection(username="streamsadmin", password="passw0rd", resource_url=_resource_url)
        >>> instances = sc.get_instances()
        >>> jobs_count = 0
        >>> for instance in instances:
        ...    jobs_count += len(instance.get_jobs())
        >>> print("There are " + jobs_count + " jobs across all instances.")

    """
    def __init__(self, username=None, password=None, resource_url=None, config=None):
        """
        :param username: The username of an authorized Streams user.
        :type username: str.
        :param password: The password associated with the username.
        :type password: str.
        :param resource_url: The resource endpoint of the instance. Can be found with `st geturl --api`.
        :type resource_url: str.
        :param config: Connection information for Bluemix. Should not be used in conjunction with username, password,
        and resource_url.
        :type config: dict.
        """
        # manually specify username, password, and resource_url
        if username and password and resource_url:
            self.rest_client = StreamsRestClient(username, password, resource_url)
            self.resource_url = resource_url

        # Connect to Bluemix service using VCAP
        elif config:
            vcap_services = VcapUtils.get_vcap_services(config)
            credentials = VcapUtils.get_credentials(config, vcap_services)

            # Obtain the streams SWS REST URL
            rest_api_url = VcapUtils.get_rest_api_url_from_creds(credentials)

            # Create rest connection to remote Bluemix SWS
            self.rest_client = StreamsRestClient(credentials['userid'], credentials['password'], rest_api_url)
            self.resource_url = rest_api_url
        else:
            logger.error("Invalid arguments for StreamsContext.__init__: must supply either a BlueMix VCAP Services or "
                         "a username, password, and resource url.")
            raise ValueError("Must supply either a BlueMix VCAP Services or a username, password, and resource url"
                             " to the StreamsContext constructor.")

    def get_domains(self):
        """Retrieves a list of all Domain resources across all known streams installations.

        :return: Returns a list of all Domain resources.
        :type return: list.
        """
        domains = []
        for resource in self.get_resources():
            # Get list of domains
            if resource.name == "domains":
                for json_domain in resource.get_resource()['domains']:
                    domains.append(Domain(json_domain, self.rest_client))
        return domains

    def get_instances(self):
        """Retrieves a list of all Instance resources across all known streams installations.

        :return: Returns a list of all Instance resources.
        :type return: list.
        """
        instances = []
        for resource in self.get_resources():
            # Get list of domains
            if resource.name == "instances":
                for json_rep in resource.get_resource()['instances']:
                    instances.append(Instance(json_rep, self.rest_client))
        return instances

    def get_installations(self):
        """Retrieves a list of all known streams Installations.

        :return: Returns a list of all Installation resources.
        :type return: list.
        """
        installations = []
        for resource in self.get_resources():
            # Get list of domains
            if resource.name == "installations":
                for json_rep in resource.get_resource()['installations']:
                    installations.append(Installation(json_rep, self.rest_client))
        return installations

    def get_views(self):
        """Gets a list of all View resources across all known streams installations.

        :return: Returns a list of all View resources.
        :type return: list.
        """
        views = []
        for domain in self.get_domains():
            for instance in domain.get_instances():
                for view in instance.get_views():
                    views.append(view)
        return views

    def get_view(self, name):
        """Gets a view with the specified `name`. If there are multiple views with the same name, it will return
        the first one encountered.

        :param name: The name of the View resource.
        :return: The view resource with the specified `name`.
        """
        for domain in self.get_domains():
            for instance in domain.get_instances():
                for view in instance.get_views():
                    if view.name == name:
                        return view
        raise ViewNotFoundError("Could not locate view: " + name)

    def get_resources(self):
        resources = []
        json_resources = self.rest_client.make_request(self.resource_url)['resources']
        for json_resource in json_resources:
            resources.append(Resource(json_resource, self.rest_client))
        return resources

    def __str__(self):
        return pformat(self.__dict__)


class VcapUtils(object):
    """Contains convenience methods for retrieving the VCAP Services, credentials, and REST API URL from a provided
    `config` dictionary.
    """
    @staticmethod
    def get_vcap_services(config):
        """Retrieves the VCAP Services information from the `ConfigParams.VCAP_SERVICES` field in the config object. If
        the field is a string, it attempts to parse it as a dict. If the field is a file, it reads the file and attempts
        to parse the contents as a dict.

        :param config: Connection information for Bluemix.
        :type config: dict.
        :return: A dict representation of the VCAP Services information.
        :type return: dict.
        """
        # Attempt to retrieve from config
        try:
            vs = config[ConfigParams.VCAP_SERVICES]
        except KeyError:
            # If that fails, try to get it from the environment
            try:
                vs = os.environ['VCAP_SERVICES']
            except KeyError:
                raise ValueError(
                    "VCAP_SERVICES information must be supplied in config[ConfigParams.VCAP_SERVICES] or as environment variable 'VCAP_SERVICES'")

        # If it was passed to config as a dict, simply return it
        if isinstance(vs, dict):
            return vs
        try:
            # Otherwise, if it's a string, try to load it as json
            vs = json.loads(vs)
        except json.JSONDecodeError:
            # If that doesn't work, attempt to open it as a file path to the json config.
            try:
                with open(vs) as vcap_json_data:
                    vs = json.load(vcap_json_data)
            except:
                raise ValueError("VCAP_SERVICES information is not JSON or a file containing JSON:", vs)
        return vs

    @staticmethod
    def get_credentials(config, vcap_services):
        """Retrieves the credentials of the VCAP Service specified by the `ConfigParams.SERVICE_NAME` field in `config`.

        :param config: Connection information for Bluemix.
        :type config: dict.
        :param vcap_services: A dict representation of the VCAP Services information.
        :type vcap_services: dict.
        :return: A dict representation of the credentials.
        :type return: dict.
        """
        # Get the credentials for the selected service, from VCAP_SERVICES config param
        try:
            service_name = config[ConfigParams.SERVICE_NAME]
        except KeyError:
            raise ValueError("Service name was not supplied in config[ConfigParams.SERVICE_NAME.")

        # Get the service corresponding to the SERVICE_NAME
        services = vcap_services['streaming-analytics']
        creds = None
        for service in services:
            if service['name'] == service_name:
                creds = service['credentials']
                break

        # If no corresponding service is found, error
        if creds is None:
            raise ValueError("Streaming Analytics service " + service_name + " was not found in VCAP_SERVICES")
        return creds

    @staticmethod
    def get_rest_api_url_from_creds(credentials):
        """Retrieves the Streams REST API URL from the provided credentials.

        :param credentials: A dict representation of the credentials.
        :type credentials: dict.
        :return: The remote Streams REST API URL.
        :type return: str.
        """
        resources_url = credentials['rest_url'] + credentials['resources_path']
        try:
            response = requests.get(resources_url, auth=(credentials['userid'], credentials['password'])).json()
        except:
            logger.exception("Error while retrieving SWS REST url from: " + resources_url)
            raise

        rest_api_url = response['streams_rest_url'] + '/resources'
        return rest_api_url


class ConfigParams(object):
    """
    Configuration options which may be used as keys in the config parameter of the StreamsContext constructor.

    VCAP_SERVICES - a json object containing the VCAP information used to submit to Bluemix
    SERVICE_NAME - the name of the streaming analytics service to use from VCAP_SERVICES.
    """
    VCAP_SERVICES = 'topology.service.vcap'
    SERVICE_NAME = 'topology.service.name'

