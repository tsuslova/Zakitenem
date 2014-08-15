#!/usr/bin/env python

from User import user_management

raise_unauthorized = True

CLIENT_ID = '939540881750-5oq9op7ap76a0373m1q957e0pa5qu9qn.apps.googleusercontent.com'

import endpoints
from protorpc import remote, message_types 

from User import message as UserMessage
from Forecast import message as ForecastMessage 

import logging

#from model import user_model
    
from constants import error_definitions

logger = logging.getLogger()

@endpoints.api(name='api', version='v1',
               description='Zakitenem API',
               allowed_client_ids=[CLIENT_ID, endpoints.API_EXPLORER_CLIENT_ID])

class Api(remote.Service):
        
    def safe_execute(self, func):
        try:
            return func()
        except endpoints.ServiceException:
            raise
        except Exception, err:
            logger.error(err)
            raise endpoints.BadRequestException(error_definitions.msg_server_error)

    @endpoints.method(UserMessage.LoginInfo, 
                      UserMessage.User,
                      path='auth', http_method='POST',
                      name='auth')
    def auth(self, request):
        return self.safe_execute(lambda:user_management.auth(request))
      
    @endpoints.method(UserMessage.Session, 
                      message_types.VoidMessage,
                      path='logout', http_method='POST',
                      name='logout')
    def logout(self, request):
        return self.safe_execute(lambda:user_management.logout(request))
        
    @endpoints.method(UserMessage.Session, 
                      UserMessage.Tools,
                      path='password_tools', http_method='GET',
                      name='password_tools')
    def password_tools(self, request):
        return self.safe_execute(lambda:user_management.password_tools(request))
        

    @endpoints.method(UserMessage.PasswordRequsest, 
                      UserMessage.Tools,
                      path='password_request', http_method='POST',
                      name='password_request')
    def password_request(self, request):
        return self.safe_execute(lambda:user_management.password_request(request))

    @endpoints.method(UserMessage.User, 
                      UserMessage.User,
                      path='user_update', http_method='POST',
                      name='user_update')
    def user_update(self, request):
        return self.safe_execute(lambda:user_management.user_update(request))
    
    @endpoints.method(UserMessage.Session, 
                      ForecastMessage.SpotList,
                      path='user_forecasts', http_method='POST',
                      name='user_forecasts')
    def user_forecasts(self, request):
        return self.safe_execute(lambda:user_management.forecasts(request))
    
    # Return list of regions. If request is filled and contains user coordinate, 
    # RegionList.possible_region object will contain possible user region
    @endpoints.method(UserMessage.Region, 
                      UserMessage.RegionList,
                      path='regions_list', http_method='GET',
                      name='regions_list')
    def region_list(self, request):
        return self.safe_execute(lambda:user_management.region_list(request))

application = endpoints.api_server([Api], restricted=False)

from Test import test_api
import unittest
suite = unittest.TestLoader().loadTestsFromModule(test_api)
unittest.TextTestRunner(verbosity=2).run(suite)
