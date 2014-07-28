import logging
import unittest
# from google.appengine.api import memcache
# from google.appengine.ext import db
from google.appengine.ext import testbed
import webapp2
import main
import json
from constants import constants
from constants import error_definitions
import sys
import time
from User import user_model

logging.basicConfig()
logger = logging.getLogger()
logger.setLevel(logging.DEBUG)

class Error404TestCase(unittest.TestCase):

    def setUp(self):
        self.testbed = testbed.Testbed()
        self.testbed.activate()
        
    def tearDown(self):
        self.testbed.deactivate()
    
    def test_error_format(self):
        class NullWriter:
            def write(self, s):
                pass
        sys.stderr = NullWriter()
          
        request = webapp2.Request.blank('/page404_which_was_never_created')
        response = request.get_response(main.application)
        response_dict = json.loads(response.body)
        self.assertNotEqual(response_dict, None)
        self.assertEqual(response_dict[constants.error_key], u"No such page")

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
    request = webapp2.Request.blank('/api/auth')
    request.method = 'POST'
    request.body = login_info.data()
    # Create a user:
    response = request.get_response(main.application)
    return response.headers["Set-Cookie"]
    
class AuthHandlerTestCase(unittest.TestCase):

    def setUp(self):
        from google.appengine.datastore import datastore_stub_util
        self.testbed = testbed.Testbed()
        self.testbed.activate()
        
        # Create a consistency policy that will simulate the High Replication consistency model.
        self.policy = datastore_stub_util.PseudoRandomHRConsistencyPolicy(probability=1)
        
        self.testbed.init_datastore_v3_stub(consistency_policy=self.policy)
        self.testbed.init_memcache_stub(True)
        
    def tearDown(self):
        self.testbed.deactivate()
    
    # Tests:
    def test_error_auth_get(self):
        logger.info("test_error_auth_get")
        request = webapp2.Request.blank('/api/auth')
        request.method = 'GET'
        response = request.get_response(main.application)
        self.assertEqual(response.status_int, 405)
         
    def test_new_user_auth_ok(self):
        logger.info("test_new_user_auth_ok")
        request = webapp2.Request.blank('/api/auth')
        request.method = 'POST'
        login_info = login_info_no_pass()
        request.body = login_info.data()
        response = request.get_response(main.application)
        response_dict = json.loads(response.body)
        user_dict = response_dict.get(constants.user_key)
        self.assertNotEqual(user_dict, None, 
                            "Login should return a user dictionary (got: %s)" % user_dict)
        self.assertEqual(login_info.login, user_dict[constants.login_key], 
                         "Requested login differs from response")

    def test_auth_existing_no_pass_nok(self):
        logger.info("test_auth_existing_no_pass_nok")
        login_info = login_info_no_pass()
        #
        user_model.create_user_from_login_info(login_info,"testcookie")
        
        request = webapp2.Request.blank('/api/auth')
        request.method = 'POST'
        request.body = login_info.data()
        user_model.debug_print_users()
        
        response = request.get_response(main.application)
        response_dict = json.loads(response.body)
        
        self.assertNotEqual(response_dict.get(constants.error_key), None, 
            "Existing account authorization without password should return an error")
        self.assertEqual(int(response_dict.get(constants.error_code_key)), 
                         error_definitions.code_account_used)
        self.assertEqual(response_dict[constants.error_key], error_definitions.msg_account_used)
    
    def test_auth_existing_with_pass_ok(self):
        logger.info("test_auth_existing_with_pass_ok")
        login_info = login_info_pass()
        user_model.create_user_from_login_info(login_info, "123")
          
        request = webapp2.Request.blank('/api/auth')
        request.method = 'POST'
        request.body = login_info.data()
        response = request.get_response(main.application)
          
        response_dict = json.loads(response.body)
         
        self.assertEqual(response_dict.get(constants.error_key), None, 
            "Auth with existing account with correct password should not return an error")
        user_dict = response_dict.get(constants.user_key)
        self.assertEqual(login_info.login, user_dict[constants.login_key], 
                        "Requested login differs from response")
        # TODO: check that a new AppInstallation was created for the account
         
    def test_auth_with_pass_ok(self):
        logger.info("test_auth_with_pass_ok")
        request = webapp2.Request.blank('/api/auth')
        request.method = 'POST'
        login_info = login_info_pass()
        request.body = login_info.data()
        # Create a user:
        request.get_response(main.application)
        # sleep after creation to avoid "too frequent request" error
        time.sleep(0.5)
        # try login with created user with a password:
        response = request.get_response(main.application)
        response_dict = json.loads(response.body)
        user_dict = response_dict.get(constants.user_key)
        self.assertEqual(login_info.login, user_dict[constants.login_key], 
                         "Requested login differs from response")
        
    def test_logout(self):
        logger.info("test_logout")
        request = webapp2.Request.blank('/api/auth')
        request.method = 'POST'
        login_info = login_info_pass()
        request.body = login_info.data()
        request.get_response(main.application)
        
        logout_request = webapp2.Request.blank('/api/logout')
        logout_request.method = 'POST'
        logout_request.get_response(main.application)
        
        response = request.get_response(main.application)
        response_dict = json.loads(response.body)
        self.assertEqual(response_dict.get(constants.error_key), None, 
            "Auth request (with password) after logout should not return an error")
        

class PasswordHandlerTestCase(unittest.TestCase):

    def setUp(self):
        from google.appengine.datastore import datastore_stub_util
        self.testbed = testbed.Testbed()
        self.testbed.activate()
        
        # Create a consistency policy that will simulate the High Replication consistency model.
        self.policy = datastore_stub_util.PseudoRandomHRConsistencyPolicy(probability=1)
        
        self.testbed.init_datastore_v3_stub(consistency_policy=self.policy)
        self.testbed.init_memcache_stub(True)
        
    def tearDown(self):
        self.testbed.deactivate()
        
    def test_no_password_tools(self):
        cookie = authorized_cookie(login_info_pass())
        request = webapp2.Request.blank('/api/password/tools')
        request.headers["Cookie"] = cookie
        response = request.get_response(main.application)
        response_dict = json.loads(response.body)
        self.assertEqual(int(response_dict.get(constants.error_code_key)), 
                         error_definitions.code_no_tools)
        
    
    def test_password_tools_after_2login(self):
        authorized_cookie(login_info_device_token())
        cookie = authorized_cookie(login_info_device_token())
        request = webapp2.Request.blank('/api/password/tools')
        request.headers["Cookie"] = cookie
        response = request.get_response(main.application)
        response_dict = json.loads(response.body)
        self.assertNotEqual(response_dict.get(constants.tools_key), None)
        

class UserHandlerTestCase(unittest.TestCase):

    def setUp(self):
        from google.appengine.datastore import datastore_stub_util
        self.testbed = testbed.Testbed()
        self.testbed.activate()
        
        # Create a consistency policy that will simulate the High Replication consistency model.
        self.policy = datastore_stub_util.PseudoRandomHRConsistencyPolicy(probability=1)
        
        self.testbed.init_datastore_v3_stub(consistency_policy=self.policy)
        self.testbed.init_memcache_stub(True)
        
    def tearDown(self):
        self.testbed.deactivate()
        
    def test_update_user(self):
        cookie = authorized_cookie(login_info_pass())
        request = webapp2.Request.blank('/api/user/set')
        request.method = 'POST'
        update_body = {constants.email_key:constants.zakitenem_email}
        request.body = json.dumps(update_body)
        request.get_response(main.application)
        
        request.headers["Cookie"] = cookie
        
        response = request.get_response(main.application)
        response_dict = json.loads(response.body)
        self.assertNotEqual(response_dict.get(constants.user_key), None)
        user_dict = response_dict.get(constants.user_key)
        self.assertEqual(user_dict.get(constants.email_key), constants.zakitenem_email)


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
        
        
class MainHandlerTestCase(unittest.TestCase):

    def setUp(self):
        self.testbed = testbed.Testbed()
        self.testbed.activate()
        self.testbed.init_datastore_v3_stub()
        self.testbed.init_memcache_stub(True)
    
    def tearDown(self):
        self.testbed.deactivate()
         
    def test_main(self):
        logger.info("test_auth_with_pass_ok")
        request = webapp2.Request.blank('/api/main')
        response = request.get_response(main.application)
        response_dict = json.loads(response.body)
        self.assertNotEqual(response_dict, None, "Main returns not json (%s)"%response)

if __name__ == "__main__":
    unittest.main()

