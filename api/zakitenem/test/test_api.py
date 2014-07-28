import logging
import unittest
# from google.appengine.api import memcache
# from google.appengine.ext import db
from google.appengine.ext import testbed
import webtest
import webapp2
import main
import json
from constants import constants
from constants import error_definitions
import sys
import time
from User import user_model

import endpoints

logging.basicConfig()
logger = logging.getLogger()
logger.setLevel(logging.DEBUG)

  
# class Error404TestCase(unittest.TestCase):
# 
#     def setUp(self):
#         self.testbed = testbed.Testbed()
#         self.testbed.activate()
#         
#     def tearDown(self):
#         self.testbed.deactivate()
#     
#     def test_error_format(self):
#         class NullWriter:
#             def write(self, s):
#                 pass
#         sys.stderr = NullWriter()
#           
#         request = webapp2.Request.blank('/page404_which_was_never_created')
#         response = request.get_response(main.application)
#         response_dict = json.loads(response.body)
#         self.assertNotEqual(response_dict, None)
#         self.assertEqual(response_dict[constants.error_key], u"No such page")

#Test-data helpers
def login_info_pass():
    login = "Toto_no_tools"
    device_id = "dsfbg4i"
    device_token = ""
    password = "4dssfgsf3"
    return user_model.create_login_info(login, device_id, device_token, password)
    
def login_info_device_token():
    login = "Toto4"
    device_id = "dsfbg4i"
    device_token = "dsfbg4i"
    password = "4dssfgsf3"
    return user_model.create_login_info(login, device_id, device_token, password)

def login_info_no_pass():
    login = "Toto4"
    device_id = "dsfbg4i"
    return user_model.create_login_info(login, device_id, "", "")

def authorized_cookie(login_info):
    request = webapp2.Request.blank('/_ah/api/api/v1/auth')
    request.method = 'POST'
    request.body = login_info.data()
    # Create a user:
    response = request.get_response(main.application)
    return response.headers["Set-Cookie"]
    
class AuthHandlerTestCase(unittest.TestCase):

    def setUp(self):
        from google.appengine.datastore import datastore_stub_util
        
        app = endpoints.api_server([main.Api], restricted=False)
        self.testapp = webtest.TestApp(app)
        self.testbed = testbed.Testbed()
        
        self.testbed.setup_env(current_version_id='testbed.version') #needed because endpoints expects a . in this value
        self.policy = datastore_stub_util.PseudoRandomHRConsistencyPolicy(probability=1)

        self.testbed.activate()        
        self.testbed.init_datastore_v3_stub(consistency_policy=self.policy)
        self.testbed.init_memcache_stub(True)

        
    def tearDown(self):
        self.testbed.deactivate()
    
    # Tests:
         
    def test_new_user_auth_ok(self):
        logger.info("test_new_user_auth_ok")
        login_info = login_info_no_pass()
        msg = login_info.login_json()
        response = self.testapp.post_json('/_ah/spi/Api.auth', msg)
        response_dict = json.loads(response.body)
        login = response_dict.get(constants.login_key)
        self.assertNotEqual(login, None, 
                            "Auth should return a login (got: %s)" % response_dict)
 
# the test is returning a stringe error:
# Content-Length is different from actual app_iter length (512!=63)
# Need return to it later
# http://stackoverflow.com/questions/24219654/content-length-error-in-google-cloud-endpoints-testing
#     def test_auth_existing_no_pass_nok(self):
#         logger.info("test_auth_existing_no_pass_nok")
#         login_info = login_info_no_pass()
#         user_model.create_user_from_login_info(login_info)
#          
#         login_info = login_info_no_pass()
#         msg = login_info.login_json()
#         self.testapp.post_json('/_ah/spi/Api.auth', msg, expect_errors=True)
#         user_model.debug_print_users()
#         print response
#         self.assertEqual(response.status_int, 400)
#         self.assertNotEqual(response.json_body['faultstring'], None, 
#             "Existing account authorization without password should return an error")
#         self.assertEqual(response_dict[constants.error_key], error_definitions.msg_account_used)
     
    def test_auth_existing_with_pass_ok(self):
        logger.info("test_auth_existing_with_pass_ok")
        login_info = login_info_pass()
        user_model.create_user_from_login_info(login_info)
           
        msg = login_info.login_json()
        response = self.testapp.post_json('/_ah/spi/Api.auth', msg)

        response_dict = json.loads(response.body)
          
        self.assertEqual(response_dict.get(constants.error_key), None, 
            "Auth with existing account with correct password should not return an error")
        
        self.assertEqual(login_info.login, response_dict.get(constants.login_key), 
                        "Requested login differs from response")
        # TODO: check that a new AppInstallation was created for the account
          
    def test_auth_with_pass_ok(self):
        logger.info("test_auth_with_pass_ok")
        login_info = login_info_pass()
        user_model.create_user_from_login_info(login_info)
        
        msg = login_info.login_json()
        response = self.testapp.post_json('/_ah/spi/Api.auth', msg)
        response_dict = json.loads(response.body)
        self.assertEqual(login_info.login, response_dict.get(constants.login_key), 
                         "Requested login differs from response")
#         
#     def test_logout(self):
#         logger.info("test_logout")
#         request = webapp2.Request.blank('/api/auth')
#         request.method = 'POST'
#         login_info = login_info_pass()
#         request.body = login_info.data()
#         request.get_response(main.application)
#         
#         logout_request = webapp2.Request.blank('/api/logout')
#         logout_request.method = 'POST'
#         logout_request.get_response(main.application)
#         
#         response = request.get_response(main.application)
#         response_dict = json.loads(response.body)
#         self.assertEqual(response_dict.get(constants.error_key), None, 
#             "Auth request (with password) after logout should not return an error")
#         

# class PasswordHandlerTestCase(unittest.TestCase):
# 
#     def setUp(self):
#         from google.appengine.datastore import datastore_stub_util
#         self.testbed = testbed.Testbed()
#         self.testbed.activate()
#         
#         # Create a consistency policy that will simulate the High Replication consistency model.
#         self.policy = datastore_stub_util.PseudoRandomHRConsistencyPolicy(probability=1)
#         
#         self.testbed.init_datastore_v3_stub(consistency_policy=self.policy)
#         self.testbed.init_memcache_stub(True)
#         
#     def tearDown(self):
#         self.testbed.deactivate()
#         
#     def test_no_password_tools(self):
#         cookie = authorized_cookie(login_info_pass())
#         request = webapp2.Request.blank('/api/password/tools')
#         request.headers["Cookie"] = cookie
#         response = request.get_response(main.application)
#         response_dict = json.loads(response.body)
#         self.assertEqual(int(response_dict.get(constants.error_code_key)), 
#                          error_definitions.code_no_tools)
#         
#     
#     def test_password_tools_after_2login(self):
#         authorized_cookie(login_info_device_token())
#         cookie = authorized_cookie(login_info_device_token())
#         request = webapp2.Request.blank('/api/password/tools')
#         request.headers["Cookie"] = cookie
#         response = request.get_response(main.application)
#         response_dict = json.loads(response.body)
#         self.assertNotEqual(response_dict.get(constants.tools_key), None)
#         
# 
# class UserHandlerTestCase(unittest.TestCase):
# 
#     def setUp(self):
#         from google.appengine.datastore import datastore_stub_util
#         self.testbed = testbed.Testbed()
#         self.testbed.activate()
#         
#         # Create a consistency policy that will simulate the High Replication consistency model.
#         self.policy = datastore_stub_util.PseudoRandomHRConsistencyPolicy(probability=1)
#         
#         self.testbed.init_datastore_v3_stub(consistency_policy=self.policy)
#         self.testbed.init_memcache_stub(True)
#         
#     def tearDown(self):
#         self.testbed.deactivate()
#         
#     def test_update_user(self):
#         cookie = authorized_cookie(login_info_pass())
#         request = webapp2.Request.blank('/api/user/set')
#         request.method = 'POST'
#         update_body = {constants.email_key:constants.zakitenem_email}
#         request.body = json.dumps(update_body)
#         request.get_response(main.application)
#         
#         request.headers["Cookie"] = cookie
#         
#         response = request.get_response(main.application)
#         response_dict = json.loads(response.body)
#         self.assertNotEqual(response_dict.get(constants.user_key), None)
#         user_dict = response_dict.get(constants.user_key)
#         self.assertEqual(user_dict.get(constants.email_key), constants.zakitenem_email)


# No way to test mail sending from testbed((         
#     def test_request_password(self):
#         cookie = authorized_cookie(login_info_device_token())
#         request = webapp2.Request.blank('/api/password/request')
#         request.method = 'POST'
#         tool_data = {constants.tool_key:constants.option_email}
#         request.body = json.dumps(tool_data)
#         request.headers["Cookie"] = cookie
#         response = request.get_response(main.application)
#         response_dict = json.loads(response.body)
#         self.assertEqual(response_dict.get(constants.tool_key)), 
#                          constants.push_key)
        
        

