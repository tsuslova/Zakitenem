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
        
# app = webapp2.WSGIApplication([
#     #('/api/main', MainHandler),
#     ('/api/auth', user_management.AuthHandler),
#     ('/api/logout', user_management.LogoutHandler),
#     ('/api/password/(.*)', user_management.PasswordRequestsHandler),
#     ('/api/user/(.*)', user_management.UserRequestsHandler),
#     ('/unit_tests', run_unit_tests.RunUnitTests),
#     ('/api/update_schema', UpdateHandler),
# ], debug=True)
# 
# app.error_handlers[404] = handle_404



CLIENT_ID = 'YOUR-CLIENT-ID'

import endpoints
from protorpc import remote
import utility_messages
import logging

from model import user_model
    
from constants import error_definitions,constants

logger = logging.getLogger()

@endpoints.api(name='zakitenemapi', version='v1',
               description='Zakitenem API',
               allowed_client_ids=[CLIENT_ID, endpoints.API_EXPLORER_CLIENT_ID])

class ZakitenemApi(remote.Service):
    
    @endpoints.method(utility_messages.MainListResponse,response_message = utility_messages.MainListResponse,
                      path='main', http_method='GET',
                      name='main')
    def main(self, request):
        #TODO: how to retrieve hostname????
        return utility_messages.main_with_host("localhost:8080/_ah/api/zakitenemapi/v1/")
        
    @endpoints.method(user_model.LoginInfoMessage, 
                      user_model.UserMessage,
                      path='auth', http_method='POST',
                      name='auth')
    def auth(self, request):
        try:
            logger.info("Authentication request")
            login_info = user_model.LoginInfo.from_message(request) #
            logger.info("login_info %s"%login_info)
            
            if len(login_info.login) < 3: 
                raise endpoints.BadRequestException(error_definitions.msg_wrong_login)
            if len(login_info.device_id) == 0:
                raise endpoints.BadRequestException(error_definitions.msg_wrong_device_id)
            
            logger.info("user_by_login")
            user = user_model.user_by_login(login_info.login)
            logger.info("user_by_login %s"%user)
            if (user):
                (error_text, error_code) = user.validate_password(login_info.password) 
                if error_text or error_code:
                    raise endpoints.BadRequestException(error_text)
                else:
                    user_model.create_installation(user,login_info.device_id,login_info.device_token)
                    return user.to_message()
            else:
                logger.info("Going to create a user")
                user = user_model.create_user_from_login_info(login_info)
                
                return user.to_message()
        except endpoints.ServiceException:
            logger.error("endpoints.ServiceException")
            raise
        except Exception, err:
            logger.error(err)
            raise endpoints.BadRequestException(error_definitions.msg_server_error)

      
application = endpoints.api_server([ZakitenemApi], restricted=False)
# application = manage_session(application)
