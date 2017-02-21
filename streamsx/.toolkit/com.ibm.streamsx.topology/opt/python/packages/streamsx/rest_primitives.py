# Licensed Materials - Property of IBM
# Copyright IBM Corp. 2016,2017
import logging
import requests
import queue
import threading
import time
import json
import re

from pprint import pprint, pformat
from requests.packages.urllib3.exceptions import InsecureRequestWarning

requests.packages.urllib3.disable_warnings(InsecureRequestWarning)

logger = logging.getLogger('streamsx.rest')


class _ResourceElement(object):
    """A class whose fields are populated by the JSON returned from a REST call.
    """
    def __init__(self, json_rep, rest_client):
        """
        :param json_rep: The JSON response from a REST call.
        :param rest_client: The client used to make the REST call.
        """
        self.rest_client=rest_client
        for key in json_rep:
            if key == 'self':
                self.__dict__["rest_self"] = json_rep['self']
            else:
                self.__dict__[key] = json_rep[key]

    def __str__(self):
        return pformat(self.__dict__)


class StreamsRestClient(object):
    """Handles the session connection with the Streams REST API.

    :param username: The username of an authorized Streams user.
    :type username: str.
    :param password: The password associated with the username.
    :type password: str.
    :param resource_url: The resource endpoint of the instance. Can be found with `st geturl --api` for local Streams
    installs.
    :type resource_url: str.
    """
    def __init__(self, username, password, resource_url):
        self.resource_url = resource_url
        # Create session to reuse TCP connection
        # https authentication
        self._username = username
        self._password = password

        session = requests.Session()
        session.auth = (username, password)
        session.verify = False

        self.session = session

    def make_request(self, url):
        logger.debug('Beginning a REST request to: ' + url)
        return self.session.get(url).json()

    def __str__(self):
        return pformat(self.__dict__)


class ViewThread(threading.Thread):
    """A thread which, when invoked, begins fetching data from the supplied view and populates the `View.items` queue.
    """
    def __init__(self, view):
        super(ViewThread, self).__init__()
        self.view = view
        self.stop = threading.Event()
        self.items = queue.Queue()

        self._last_collection_time = -1
        self._last_collection_time_count = 0

    def __call__(self):
        while not self._stopped():
            time.sleep(1)
            _items = self._get_deduplicated_view_items()
            if _items is not None:
                for itm in _items:
                    self.items.put(itm)

    def _get_deduplicated_view_items(self):
        # Retrieve the view object
        data_name = self.view.attributes[0]['name']
        items = self.view.get_view_items()
        data = []

        # The number of already seen tuples to ignore on the last millisecond time boundary
        ignore_last_collection_time_count = self._last_collection_time_count

        for item in items:
            # Ignore tuples from milliseconds we've already seen
            if item.collectionTime < self._last_collection_time:
                continue
            elif item.collectionTime == self._last_collection_time:
                # Ignore tuples within the millisecond which we've already seen.
                if ignore_last_collection_time_count > 0:
                    ignore_last_collection_time_count -= 1
                    continue

                # If we haven't seen it, continue
                data.append(json.loads(item.data[data_name]))
            else:
                data.append(json.loads(item.data[data_name]))

        if len(items) > 0:
            # Record the current millisecond time boundary.
            _last_collection_time = items[-1].collectionTime
            _last_collection_time_count = 0
            backwards_counter = len(items) - 1
            while backwards_counter >= 0 and items[backwards_counter].collectionTime == _last_collection_time:
                _last_collection_time_count += 1
                backwards_counter -= 1

            self._last_collection_time = _last_collection_time
            self._last_collection_time_count = _last_collection_time_count

        return data

    def _stopped(self):
        return self.stop.isSet()


class View(_ResourceElement):
    """The view element resource provides access to information about a view that is associated with an active job, and
    exposes methods to retrieve data from the View's Stream.
    """
    def __init__(self, json_view, rest_client):
        super(View, self).__init__(json_view, rest_client)
        self.view_thread = ViewThread(self)

    def get_domain(self):
        return Domain(self.rest_client.make_request(self.domain), self.rest_client)

    def get_instance(self):
        return Instance(self.rest_client.make_request(self.instance), self.rest_client)

    def get_job(self):
        return Job(self.rest_client.make_request(self.job), self.rest_client)

    def stop_data_fetch(self):
        self.view_thread.stop.set()

    def start_data_fetch(self):
        self.view_thread.stop.clear()
        t = threading.Thread(target=self.view_thread)
        t.start()
        return self.view_thread.items

    def get_view_items(self):
        view_items = []
        for json_view_items in self.rest_client.make_request(self.viewItems)['viewItems']:
            view_items.append(ViewItem(json_view_items, self.rest_client))
        logger.debug("Retrieved " + str(len(view_items)) + " items from view " + self.name)
        return view_items

class ActiveView(_ResourceElement):
    """
    The deprecated active view element resource provides access to information about a view that is active.
    """
    pass


class ViewItem(_ResourceElement):
    """
    Represents the data of a tuple, it's type, and the time when it was collected from the stream.
    """
    pass


class ConfiguredView(_ResourceElement):
    """
    The deprecated configured view element resource provides access to configuration information for a view.
    """
    pass


class Host(_ResourceElement):
    """The host element resource provides access to information about a host that is allocated to a domain as a
    resource for running Streams services and applications.
    """
    pass


class Job(_ResourceElement):
    """The job element resource provides access to information about a submitted job within a specified instance.
    """
    def get_views(self):
        views = []
        for json_view in self.rest_client.make_request(self.views)['views']:
            views.append(View(json_view, self.rest_client))
        return views

    def get_active_views(self):
        views = []
        for json_view in self.rest_client.make_request(self.activeViews)['activeViews']:
            views.append(ActiveView(json_view, self.rest_client))
        return views

    def get_domain(self):
        return Domain(self.rest_client.make_request(self.domain), self.rest_client)

    def get_instance(self):
        return Instance(self.rest_client.make_request(self.instance), self.rest_client)

    def get_hosts(self):
        hosts = []
        for json_rep in self.rest_client.make_request(self.hosts)['hosts']:
            hosts.append(Host(json_rep, self.rest_client))
        return hosts

    def get_operator_connections(self):
        operators_connections = []
        for json_rep in self.rest_client.make_request(self.operatorConnections)['operatorConnections']:
            operators_connections.append(OperatorConnection(json_rep, self.rest_client))
        return operators_connections

    def get_operators(self):
        operators = []
        for json_rep in self.rest_client.make_request(self.operators)['operators']:
            operators.append(Operator(json_rep, self.rest_client))
        return operators

    def get_pes(self):
        pes = []
        for json_rep in self.rest_client.make_request(self.pes)['pes']:
            pes.append(PE(json_rep, self.rest_client))
        return pes

    def get_pe_connections(self):
        pe_connections = []
        for json_rep in self.rest_client.make_request(self.peConnections)['peConnections']:
            pe_connections.append(PEConnection(json_rep, self.rest_client))
        return pe_connections

    def get_resource_allocations(self):
        resource_allocations = []
        for json_rep in self.rest_client.make_request(self.resourceAllocations)['resourceAllocations']:
            resource_allocations.append(ResourceAllocation(json_rep, self.rest_client))
        return resource_allocations


class Operator(_ResourceElement):
    """The operator element resource provides access to information about a specific operator in a job.
    """
    def get_metrics(self, name=None):
        """
        Get metrics for an operator.

        Args:
            name(str): Only return metrics matching ``name`` as a regular
                expression using ``re.match(name, metric_name``.
                If name is not supplied then all metrics for this operator are returned.

        Returns:
             list(Metric): List of matching metrics.
        """
        metrics = []
        for json_rep in self.rest_client.make_request(self.metrics)['metrics']:
            if name is not None:
                if not re.match(name, json_rep['name']):
                    continue
            metrics.append(Metric(json_rep, self.rest_client))
        return metrics

class OperatorConnection(_ResourceElement):
    """The operator connection element resource provides access to information about a connection between two operator
    ports.
    """
    pass

class Metric(_ResourceElement):
    """
    Metric resource provides access to information about a Streams metric.
    """
    pass

class PE(_ResourceElement):
    """The processing element (PE) resource provides access to information about a PE.
    """
    pass


class PEConnection(_ResourceElement):
    """The processing element (PE) connection resource provides access to information about a connection between two
    processing element (PE) ports.
    """
    pass


class ResourceAllocation(_ResourceElement):
    pass


class ActiveService(_ResourceElement):
    pass


class Installation(_ResourceElement):
    pass


class ImportedStream(_ResourceElement):
    pass


class ExportedStream(_ResourceElement):
    pass


class Instance(_ResourceElement):
    """The instance element resource provides access to information about a Streams instance."""
    def get_operators(self):
        operators = []
        for json_rep in self.rest_client.make_request(self.operators)['operators']:
            operators.append(Operator(json_rep, self.rest_client))
        return operators

    def get_operator_connections(self):
        operators_connections = []
        for json_rep in self.rest_client.make_request(self.operatorConnections)['operatorConnections']:
            operators_connections.append(OperatorConnection(json_rep, self.rest_client))
        return operators_connections

    def get_pes(self):
        pes = []
        for json_rep in self.rest_client.make_request(self.pes)['pes']:
            pes.append(PE(json_rep, self.rest_client))
        return pes

    def get_pe_connections(self):
        pe_connections = []
        for json_rep in self.rest_client.make_request(self.peConnections)['peConnections']:
            pe_connections.append(PEConnection(json_rep, self.rest_client))
        return pe_connections

    def get_views(self):
        views = []
        for json_view in self.rest_client.make_request(self.views)['views']:
            views.append(View(json_view, self.rest_client))
        return views

    def get_hosts(self):
        hosts = []
        for json_rep in self.rest_client.make_request(self.hosts)['hosts']:
            hosts.append(Host(json_rep, self.rest_client))
        return hosts

    def get_domain(self):
        return Domain(self.rest_client.make_request(self.domain), self.rest_client)

    def get_active_views(self):
        views = []
        for json_view in self.rest_client.make_request(self.activeViews)['activeViews']:
            views.append(ActiveView(json_view, self.rest_client))
        return views

    def get_configured_views(self):
        views = []
        for json_view in self.rest_client.make_request(self.configuredViews)['configuredViews']:
            views.append(ConfiguredView(json_view, self.rest_client))
        return views

    def get_jobs(self):
        jobs = []
        for json_rep in self.rest_client.make_request(self.jobs)['jobs']:
            jobs.append(Job(json_rep, self.rest_client))
        return jobs

    def get_imported_streams(self):
        imported_streams = []
        for json_rep in self.rest_client.make_request(self.importedStreams)['importedStreams']:
            imported_streams.append(ImportedStream(json_rep, self.rest_client))
        return imported_streams

    def get_exported_streams(self):
        exported_streams = []
        for json_rep in self.rest_client.make_request(self.exportedStreams)['exportedStreams']:
            exported_streams.append(ExportedStream(json_rep, self.rest_client))
        return exported_streams

    def get_active_services(self):
        active_services = []
        for json_rep in self.rest_client.make_request(self.activeServices)['activeServices']:
            active_services.append(ActiveService(json_rep, self.rest_client))
        return active_services

    def get_resource_allocations(self):
        resource_allocations = []
        for json_rep in self.rest_client.make_request(self.resourceAllocations)['resourceAllocations']:
            resource_allocations.append(ResourceAllocation(json_rep, self.rest_client))
        return resource_allocations


class ResourceTag(object):
    def __init__(self, json_resource_tag):
        self.definition_format_properties = json_resource_tag['definitionFormatProperties']
        self.description = json_resource_tag['description']
        self.name = json_resource_tag['name']
        self.properties_definition = json_resource_tag['propertiesDefinition']
        self.reserved = json_resource_tag['reserved']

    def __str__(self):
        return pformat(self.__dict__)


class ActiveVersion(object):
    def __init__(self, json_active_version):
        self.architecture = json_active_version['architecture']
        self.build_version = json_active_version['buildVersion']
        self.edition_name = json_active_version['editionName']
        self.full_product_version = json_active_version['fullProductVersion']
        self.minimum_os_base_version = json_active_version['minimumOSBaseVersion']
        self.minimum_os_patch_version = json_active_version['minimumOSPatchVersion']
        self.minimum_os_version = json_active_version['minimumOSVersion']
        self.product_name = json_active_version['productName']
        self.product_version = json_active_version['productVersion']

    def __str__(self):
        return pformat(self.__dict__)


class Domain(_ResourceElement):
    """The domain element resource provides access to information about an InfoSphere Streams domain."""
    def get_instances(self):
        instances = []
        for json_instance in self.rest_client.make_request(self.instances)['instances']:
            instances.append(Instance(json_instance, self.rest_client))
        return instances

    def get_hosts(self):
        hosts = []
        for json_rep in self.rest_client.make_request(self.hosts)['hosts']:
            hosts.append(Host(json_rep, self.rest_client))
        return hosts

    def get_active_services(self):
        active_services = []
        for json_rep in self.rest_client.make_request(self.activeServices)['activeServices']:
            active_services.append(ActiveService(json_rep, self.rest_client))
        return active_services

    def get_resource_allocations(self):
        resource_allocations = []
        for json_rep in self.rest_client.make_request(self.resourceAllocations)['resourceAllocations']:
            resource_allocations.append(ResourceAllocation(json_rep, self.rest_client))
        return resource_allocations

    def get_resources(self):
        resources = []
        json_resources = self.rest_client.make_request(self.resource_url)['resources']
        for json_resource in json_resources:
            resources.append(Resource(json_resource, self.rest_client))
        return resources

    def get_resources(self):
        resources = []
        json_resources = self.rest_client.make_request(self.resource_url)['resources']
        for json_resource in json_resources:
            resources.append(Resource(json_resource, self.rest_client))
        return resources


class Resource(_ResourceElement):
    def get_resource(self):
        return self.rest_client.make_request(self.resource)


def get_view_obj(_view, rc):
    for domain in rc.get_domains():
        for instance in domain.get_instances():
            for view in instance.get_views():
                if view.name == _view.name:
                    return view
    return None

