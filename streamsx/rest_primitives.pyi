# coding=utf-8
# Licensed Materials - Property of IBM
# Copyright IBM Corp. 2017
from typing import Any, List, Union
import streamsx.topology.context

class _ResourceElement(object): ...

class View(_ResourceElement):
    def __init__(self, json_view: Any, rest_client: Any) -> None: ...
    def get_domain(self) -> Domain: ...
    def get_instance(self) -> Instance: ...
    def get_job(self) -> Job: ...
    def stop_data_fetch(self) -> None: ...
    def start_data_fetch(self) -> Any: ...
    def get_view_items(self) -> Any: ...

class ViewItem(_ResourceElement): ...

class Host(_ResourceElement): ...

class Job(_ResourceElement):
    def get_views(self, name: str=None) -> List[View]: ...
    def get_domain(self) -> Domain: ...
    def get_instance(self) -> Instance: ...
    def get_hosts(self) -> List[Host]: ...
    def get_operator_connections(self) -> Any: ...
    def get_operators(self) -> List[Operator]: ...
    def get_pes(self) -> List[PE]: ...
    def get_pe_connections(self) -> List[PEConnection]: ...
    def get_resource_allocations(self) -> Any: ...
    def cancel(self, force: Any=bool) -> Union[Any, bool]: ...


class Operator(_ResourceElement):
    def get_metrics(self, name: str=None) -> List[Metric]: ...

class OperatorConnection(_ResourceElement): ...


class OperatorOutputPort(_ResourceElement): ...


class Metric(_ResourceElement): ...


class PE(_ResourceElement): ...


class PEConnection(_ResourceElement): ...


class ResourceAllocation(_ResourceElement):
    def get_resource(self) -> Resource: ...
    def get_pes(self) -> List[PE]: ...
    def get_jobs(self, name: str=None) -> List[Job]: ...

class Resource(_ResourceElement):
    def get_metrics(self, name: str=None) -> List[Metric]: ...

class ActiveService(_ResourceElement): ...


class Installation(_ResourceElement): ...


class ImportedStream(_ResourceElement): ...


class ExportedStream(_ResourceElement):
    def get_operator_output_port(self) -> OperatorOutputPort: ...


class Instance(_ResourceElement):
    def get_operators(self) -> List[Operator]: ...
    def get_operator_connections(self) -> Any: ...
    def get_pes(self) -> List[PE]: ...
    def get_pe_connections(self) -> List[PEConnection]: ...
    def get_views(self, name: str=None) -> List[View]: ...
    def get_hosts(self) -> List[Host]: ...
    def get_domain(self) -> Domain: ...
    def get_jobs(self, name: str=None) -> List[Job]: ...
    def get_job(self, id: str) -> Job: ...
    def get_imported_streams(self) -> Any: ...
    def get_exported_streams(self) -> Any: ...
    def get_active_services(self) -> Any: ...
    def get_resource_allocations(self) -> Any: ...
    def get_published_topics(self) -> List[PublishedTopic]: ...
    def upload_bundle(self, bundle:str): -> 'ApplicationBundle'
    def submit_job(self, bundle:str, job_config: streamsx.topology.context.JobConfig=None): -> Job


class ApplicationBundle(_ResourceElement):
    def submit_job(self, job_config: streamsx.topology.context.JobConfig=None): -> Job


class ResourceTag(object): ...


class ActiveVersion(object): ...


class PublishedTopic(object): ...


class Domain(_ResourceElement):
    def get_instances(self) -> List[Instance]: ...
    def get_hosts(self) -> List[Host]: ...
    def get_active_services(self) -> Any: ...
    def get_resource_allocations(self) -> Any: ...
    def get_resources(self) -> Any: ...

class RestResource(_ResourceElement):
    def get_resource(self) -> Any: ...
       
class StreamingAnalyticsService(object):
    def __init__(self, rest_client: Any, credentials: Any) -> None: ...
    def cancel_job(self, job_id: Any=None, job_name: Any=None) -> Any: ...
    def start_instance(self) -> Any: ...
    def stop_instance(self) -> Any: ...
    def get_instance_status(self) -> Any: ...
