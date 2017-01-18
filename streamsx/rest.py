# Licensed Materials - Property of IBM
# Copyright IBM Corp. 2016
import requests
import time
import numpy as np
import matplotlib.pyplot as plt
import json

from .rest_primitives import Domain, Instance, Installation, Resource, StreamsRestClient
from pprint import pformat
from requests.packages.urllib3.exceptions import InsecureRequestWarning

requests.packages.urllib3.disable_warnings(InsecureRequestWarning)


class StreamsContext:
    def __init__(self, username, password, resource_url):
        self.rest_client = StreamsRestClient(username, password, resource_url)
        self.resource_url = resource_url

    def get_domains(self):
        domains = []
        for resource in self.get_resources():
            # Get list of domains
            if resource.name == "domains":
                for json_domain in resource.get_resource()['domains']:
                    domains.append(Domain(json_domain, self.rest_client))
        return domains

    def get_instances(self):
        instances = []
        for resource in self.get_resources():
            # Get list of domains
            if resource.name == "instances":
                for json_rep in resource.get_resource()['instances']:
                    instances.append(Instance(json_rep, self.rest_client))
        return instances

    def get_installations(self):
        installations = []
        for resource in self.get_resources():
            # Get list of domains
            if resource.name == "installations":
                for json_rep in resource.get_resource()['installations']:
                    installations.append(Installation(json_rep, self.rest_client))
        return installations

    def get_resources(self):
        resources = []
        json_resources = self.rest_client.make_request(self.resource_url)['resources']
        for json_resource in json_resources:
            resources.append(Resource(json_resource, self.rest_client))
        return resources

    def __str__(self):
        return pformat(self.__dict__)

def get_view_obj(_view, rc):
    for domain in rc.get_domains():
        for instance in domain.get_instances():
            for view in instance.get_views():
                if view.name == _view.name:
                    return view
    return None


def multi_graph_every(views, key, time_step):
    colors = 'bgrcmykw'
    _views = []
    for view in views:
        view.initialize_rest()
        v = get_view_obj(view,view.get_streams_context())
        if v is not None:
            _views.append(v)
    views = _views

    fig, ax = plt.subplots()

    ydata = []
    xdata = []
    ydatas = []
    for view, color in zip(views, colors):
        ax.plot(xdata,
                ydata, linewidth=2, color=color, label='target')

    data_name = view.attributes[0]['name']

    while True:
        time.sleep(time_step)
        count = 0
        for view, color in zip(views, colors):
            itms = view.get_view_items()

            ar = [json.loads(item.data[data_name])[key] for item in itms]

            if (len(ar) == 0):
                ydatas.insert(0, [0])
                continue
            else:
                ydatas.insert(0, ar)
            xdata = [x for x in range(len(ydatas[0]))]
            ax.lines[count].set_ydata(ydatas[0])
            ax.lines[count].set_xdata(xdata)
            ax.set_xlim(count, len(ydatas[0]))
            ax.set_ylim(np.amin(ydatas[0]) - 1.0, np.amax(ydatas[0]) + 1.0)
            count += 1
        fig.canvas.draw()
        ydatas = []


def graph_every(view, key, time_step):
    view.initialize_rest()
    view = get_view_obj(view, view.get_streams_context())
    if view is None:
        return None
    fig, ax = plt.subplots()
    
    ydata = []
    xdata = []
    
    ax.plot(xdata,
            ydata, linewidth = 2, color = 'green', label = 'target')
    
    data_name = view.attributes[0]['name']
    
    while True:
        time.sleep(time_step)
        itms = view.get_view_items()
        
        del ydata[:]
        for item in itms:
            ydata.append(json.loads(item.data[data_name])[key])
        if(len(ydata) == 0):
            continue
        xdata = [x for x in range(len(ydata))]
        ax.lines[0].set_ydata(ydata)
        ax.lines[0].set_xdata(xdata)
        ax.set_xlim(0, len(ydata))
        ax.set_ylim(np.amin(ydata)-1.0, np.amax(ydata)+1.0)
        fig.canvas.draw()
