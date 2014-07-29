#!/usr/bin/env python

from User import user_management

raise_unauthorized = True

CLIENT_ID = '939540881750-5oq9op7ap76a0373m1q957e0pa5qu9qn.apps.googleusercontent.com'

import endpoints
from protorpc import remote, message_types 

from User import message as user_message 

import logging

#from model import user_model
    
from constants import error_definitions

logger = logging.getLogger()

@endpoints.api(name='api', version='v1',
               description='Zakitenem API',
               allowed_client_ids=[CLIENT_ID, endpoints.API_EXPLORER_CLIENT_ID])

class Api(remote.Service):
        
    @endpoints.method(user_message.LoginInfo, 
                      user_message.User,
                      path='auth', http_method='POST',
                      name='auth')
    def auth(self, request):
        try:
            logger.info("Authentication request")
            return user_management.auth(request)
        except endpoints.ServiceException:
            raise
        except Exception, err:
            logger.error(err)
            raise endpoints.BadRequestException(error_definitions.msg_server_error)

      
    @endpoints.method(user_message.Session, 
                      message_types.VoidMessage,
                      path='logout', http_method='POST',
                      name='logout')
    def logout(self, request):
        try:
            logger.info("Logout request")
            return user_management.logout(request)
        except endpoints.ServiceException:
            raise
        except Exception, err:
            logger.error(err)
            raise endpoints.BadRequestException(error_definitions.msg_server_error)
        
    @endpoints.method(user_message.Session, 
                      user_message.Tools,
                      path='password_tools', http_method='GET',
                      name='password_tools')
    def password_tools(self, request):
        try:
            logger.info("password_tools request")
            return user_management.password_tools(request)
        except endpoints.ServiceException:
            raise
        except Exception, err:
            logger.error(err)
            raise endpoints.BadRequestException(error_definitions.msg_server_error)
        

    @endpoints.method(user_message.PasswordRequsest, 
                      user_message.Tools,
                      path='password_request', http_method='POST',
                      name='password_request')
    def password_request(self, request):
        try:
            logger.info("password_request request")
            return user_management.password_request(request)
        except endpoints.ServiceException:
            raise
        except Exception, err:
            logger.error(err)
            raise endpoints.BadRequestException(error_definitions.msg_server_error)
        

    @endpoints.method(user_message.User, 
                      user_message.User,
                      path='user_update', http_method='POST',
                      name='user_update')
    def user_update(self, request):
        try:
            logger.info("user_update request")
            return user_management.user_update(request)
        except endpoints.ServiceException:
            raise
        except Exception, err:
            logger.error(err)
            raise endpoints.BadRequestException(error_definitions.msg_server_error)
        
application = endpoints.api_server([Api], restricted=False)
# application = manage_session(application)
