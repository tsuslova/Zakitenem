import logging
import unittest
# from google.appengine.api import memcache
# from google.appengine.ext import db
from google.appengine.ext import testbed
import webtest
import main
import json
from constants import constants
from User import user_model

import endpoints

logging.basicConfig()
logger = logging.getLogger()
logger.setLevel(logging.DEBUG)

#Test-data helpers
def login_info_pass(password = "0000", device_id = "dsfbg4i"):
    login = "Toto_no_tools"
    device_token = ""
    return user_model.create_login_info(login, device_id, device_token, password)
    
def login_info_device_token():
    login = "Toto6"
    device_id = "dsfbg4i"
    device_token = "dsfbg4i"
    password = "4dssfgsf3"
    return user_model.create_login_info(login, device_id, device_token, password)

def region_device_token():
    login = "Toto5"
    device_id = "dsfbg4i"
    device_token = "dsfbg4i"
    password = "4dssfgsf3"
    return user_model.create_login_info(login, device_id, device_token, password)

def login_info_no_pass(device_id = "dsfbg4i"):
    login = "Toto4"
    return user_model.create_login_info(login, device_id, "", "")

class MyTestCase(unittest.TestCase):

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
        
    def authorized_session(self, login_info):
        msg = login_info.login_json()
        response = self.testapp.post_json('/_ah/spi/Api.auth', msg)
        response_dict = json.loads(response.body)
        session = response_dict.get(constants.session_key)
        return session
    
     
class AuthHandlerTestCase(MyTestCase):
   
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
     
# the test is returning a strange error:
# Content-Length is different from actual app_iter length (512!=63)
# Need return to it later
# http://stackoverflow.com/questions/24219654/content-length-error-in-google-cloud-endpoints-testing
    def test_auth_existing_no_pass_nok(self):
        logger.info("test_auth_existing_no_pass_nok")
        login_info = login_info_no_pass()
        user_model.create_user_from_login_info(login_info)
          
        login_info = login_info_no_pass(device_id="new id")
        msg = login_info.login_json()
        response = self.testapp.post_json('/_ah/spi/Api.auth', msg, expect_errors=True)
        #user_model.debug_print_users()
        response_dict = json.loads(response.body)
              
        self.assertNotEqual(response_dict.get(constants.error_key), None, 
            "Auth with existing account without password(with new device_id) should return an error")
         
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
             
    def test_auth_no_pass_same_device_ok(self):
        logger.info("test_auth_with_pass_ok")
        login_info = login_info_no_pass()
        user_model.create_user_from_login_info(login_info)
            
        msg = login_info.login_json()
        response = self.testapp.post_json('/_ah/spi/Api.auth', msg)
        response_dict = json.loads(response.body)
        self.assertEqual(login_info.login, response_dict.get(constants.login_key), 
                         "Requested login differs from response")
         
    def test_logout(self):
        logger.info("test_logout")
        login_info = login_info_pass()
        user_model.create_user_from_login_info(login_info)
            
        msg = login_info.login_json()
        response = self.testapp.post_json('/_ah/spi/Api.auth', msg)
            
        response_dict = json.loads(response.body)
        self.assertEqual(response_dict.get(constants.error_key), None, 
            "Auth request (with password) after logout should not return an error")
            
   
class PasswordHandlerTestCase(MyTestCase):
         
    def test_no_password_tools(self):
        session = self.authorized_session(login_info_pass())
        response = self.testapp.post_json('/_ah/spi/Api.password_tools', session)
        #no tools - empty response
        self.assertEqual(response.body, "{}")
   
    def test_password_tools_after_2login(self):
        self.authorized_session(login_info_device_token())
        session = self.authorized_session(login_info_device_token())
        response = self.testapp.post_json('/_ah/spi/Api.password_tools', session)
           
        response_dict = json.loads(response.body)
        self.assertNotEqual(response_dict.get(constants.option_push), None)
           
   
class UserHandlerTestCase(MyTestCase):
 
    def test_update_user(self):
        session = self.authorized_session(login_info_device_token())
        birthday = "1990-07-30T23:29:24"
        
        user_json = {constants.email_key:constants.zakitenem_email, "session":session,
                     constants.birthday_key:birthday}
        response = self.testapp.post_json('/_ah/spi/Api.user_update', user_json)
        response_dict = json.loads(response.body)
        self.assertEqual(response_dict.get(constants.birthday_key), birthday)
   
    def test_update_user_region(self):
        session = self.authorized_session(region_device_token())
        user_json = {constants.region_key:{constants.id_key:constants.default_region}, 
                     "session":session}
        response = self.testapp.post_json('/_ah/spi/Api.user_update', user_json)
        response_dict = json.loads(response.body)
        region = response_dict.get(constants.region_key)
        self.assertNotEqual(region, None)
        self.assertEqual(region.get(constants.id_key), constants.default_region)
        self.assertNotEqual(response_dict.get(constants.session_key), None)

    def test_update_user_password(self):
        session = self.authorized_session(login_info_pass())
        new_password = "2222"
        user_json = {constants.password_key:new_password, "session":session}
        self.testapp.post_json('/_ah/spi/Api.user_update', user_json)
        
        #Login with old password should fail:
        msg = login_info_pass(device_id="new_device_id").login_json()
        response = self.testapp.post_json('/_ah/spi/Api.auth', msg, expect_errors=True)
        response_dict = json.loads(response.body)
        session = response_dict.get(constants.session_key)
        self.assertEqual(session, None)
        
        #After user update we should check that we can login with the new password
        session = self.authorized_session(login_info_pass(new_password, "new_device_id"))
        self.assertNotEqual(session, None)

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

        
 
class ForecastHandlerTestCase(MyTestCase):
      
    def test_forecasts(self):
        session = self.authorized_session(login_info_device_token())
        response = self.testapp.post_json('/_ah/spi/Api.user_forecasts', session)
        response_dict = json.loads(response.body)
        self.assertNotEqual(response_dict.get(constants.spots_key), None)
