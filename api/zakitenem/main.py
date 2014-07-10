#!/usr/bin/env python
#
# Copyright 2007 Google Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
import webapp2
from errors_handlers import handle_404
from request_handlers import user_management
from tools import update_schema 
from google.appengine.ext import deferred
import run_unit_tests

class MainHandler(webapp2.RequestHandler):
    def get(self):
        hostname = self.request.headers.get('host')
        self.response.headers.add_header("Content-Type", "application/json")
        self.response.out.write("""
              {
                  "auth": "http://%s/api/auth",
                  "logout": "http://%s/api/logout", 
                  "password_tools": "http://%s/api/password/tools", 
                  "password_request": "http://%s/api/password/request"
              }""" % (hostname, hostname, hostname, hostname))

class UpdateHandler(webapp2.RequestHandler):
    def get(self):
        deferred.defer(update_schema.UpdateSchema)
        self.response.out.write('Schema migration successfully initiated.')
        
app = webapp2.WSGIApplication([
    ('/api/main', MainHandler),
    ('/api/auth', user_management.AuthHandler),
    ('/api/logout', user_management.LogoutHandler),
    
    ('/unit_tests', run_unit_tests.RunUnitTests),
    ('/api/update_schema', UpdateHandler),
], debug=True)

app.error_handlers[404] = handle_404

        
