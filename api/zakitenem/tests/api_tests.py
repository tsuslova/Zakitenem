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
from model import user_model

logging.basicConfig()

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
        response = request.get_response(main.app)
        response_dict = json.loads(response.body)
        self.assertNotEqual(response_dict, None)
        self.assertEqual(response_dict[constants.error_key], u"No such page")


class AuthHandlerTestCase(unittest.TestCase):

    def setUp(self):
        self.testbed = testbed.Testbed()
        self.testbed.activate()
        self.testbed.init_datastore_v3_stub()
        self.testbed.init_memcache_stub(True)
    
    def tearDown(self):
        self.testbed.deactivate()
        
        
    def test_error_auth_get(self):
        request = webapp2.Request.blank('/api/auth')
        request.method = 'GET'
        response = request.get_response(main.app)
        self.assertEqual(response.status_int, 405)
         
    def test_new_user_auth_ok(self):
        request = webapp2.Request.blank('/api/auth')
        request.method = 'POST'
        login = "Toto"
        password = "398dnjfkeH3"
        login_info = user_model.login_info(login, password)
        request.body = login_info.data()
        response = request.get_response(main.app)
        response_dict = json.loads(response.body)
        self.assertEqual(login, response_dict[constants.login_key], 
                         "Requested login differs from response")
        login_info = json.loads(self.request.body)
            
    def test_auth_existing_no_pass(self):
        request = webapp2.Request.blank('/api/auth')
        request.method = 'POST'
        login = "Toto4"
        device_id = "dsfbg4i"
        login_info = user_model.login_info(login, device_id, "", "")
        request.body = login_info.data()
        request.get_response(main.app)
        
        #Login the same time with the existing account 
        login_info = user_model.login_info(login, device_id, "", "")
        request.body = login_info.data()
        response = request.get_response(main.app)
        response_dict = json.loads(response.body)
        
        self.assertNotEqual(response_dict.get(constants.error_key), None, 
            "Existing account authorization without password should return an error")
        self.assertEqual(int(response_dict.get(constants.error_code_key)), 
                         error_definitions.code_account_used)
        self.assertEqual(response_dict[constants.error_key], error_definitions.msg_account_used)
        
        
    def test_auth_with_pass_ok(self):
        request = webapp2.Request.blank('/api/auth')
        request.method = 'POST'
        login = "Toto1"
        login_info = user_model.login_info(login, "123", "", "test")
        request.body = login_info.data()
        # Create a user:
        request.get_response(main.app)
        # sleep after creation to avoid "too frequent request" error
        time.sleep(0.5)
        # try login with created user with a password:
        response = request.get_response(main.app)
        response_dict = json.loads(response.body)
        print response_dict
        self.assertEqual(login, response_dict[constants.login_key], 
                         "Requested login differs from response")
        
        
if __name__ == "__main__":
    unittest.main()
        
        