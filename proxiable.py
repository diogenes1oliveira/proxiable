#!/usr/bin/env python3
# -*- coding: utf-8

'''
Override requests by files in the corresponding path in the filesystem.
'''

from pathlib import Path
import os
from typing import Optional
from urllib.parse import urlparse

from mitmproxy.http import HTTPFlow, HTTPResponse, HTTPRequest

# PROXIABLE_SITES_LOCATION must be set a directory with the overriding
# files in the same structure as the URL. For example, to replace
# https://nginx.org/nginx.png you should set the following file structure:
#
# sites/
# └─── nginx.org/
#      └─── nginx.png
#
SITES_LOCATION = Path(os.getenv('PROXIABLE_SITES_LOCATION') or 'sites')

# Name of a file to lookup when requesting for URLs ending with '/'
INDEX_FILE = os.getenv('PROXIABLE_INDEX_FILE') or 'INDEX'


def disable_cache(flow: HTTPFlow) -> None:
    '''
    Disables the cache headers in the flow (!)
    '''
    flow.request.anticache()
    flow.response.headers['Cache-Control'] = (
        'no-cache, no-store, must-revalidate')
    flow.response.headers['Pragma'] = 'no-cache'
    flow.response.headers['Expires'] = '0'


def get_overriding_path(
        request: HTTPRequest,
        base_location: str = SITES_LOCATION) -> Optional[str]:
    '''
    Returns the path segment of the request (!)
    '''
    host = request.host
    full_path = urlparse(request.path).path
    if full_path.endswith('/'):
        full_path = full_path + 'index'
    path = SITES_LOCATION / host / Path(*full_path.split('/'))
    if path.exists():
        return str(path)


def override_response(response: HTTPResponse, buffer: bytes):
    '''
    Overrides the response content by the binary buffer
    '''
    response.headers['Content-Length'] = str(len(buffer))
    response.content = buffer


def response(flow: HTTPFlow):
    disable_cache(flow)
    path = get_overriding_path(flow.request)

    if path and flow.response.status_code == 200:
        with open(path, 'rb') as fp:
            content = fp.read()

        override_response(flow.response, content)
