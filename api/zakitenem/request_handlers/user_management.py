import webapp2
import json
import logging
import request_utils
from model import user_model
from constants import error_definitions
from constants import constants
import datetime

#TODO remove global loggers?
logger = logging.getLogger()

class AuthHandler(webapp2.RequestHandler):
        
    def set_cookie(self):
        import os
        logger.warning("HERE")
        cookie = os.urandom(42)
        #TODO check cookie generation
        logger.warning("%s"%cookie) 
        #TODO: normal date
        self.response.set_cookie("session_id", cookie, expires=datetime.datetime(2030, 11, 10)) 
        self.response.set_status(200)
        return cookie

    def post(self, *args):
        try:
            logger.warning("Authentication request")
            login_info = json.loads(self.request.body)
            login = login_info[constants.login_key]
            device_id = login_info[constants.device_id_key]
            if len(login) < 3: 
                request_utils.out_error(self.response, error_definitions.msg_wrong_login, 
                                        error_definitions.code_wrong_param)
                return
            if len(device_id) == 0:
                request_utils.out_error(self.response, error_definitions.msg_wrong_device_id, 
                                        error_definitions.code_wrong_param)
                return
            
            password = login_info.get(constants.password_key)
            device_token = login_info.get(constants.device_token_key)
            
            user = user_model.user_by_login(login)
                
            if (user):
                if not password:
                    request_utils.out_error(self.response, error_definitions.msg_account_used, 
                                            error_definitions.code_account_used)
                    return
                    
                    if user.validate_password(password):
                        user.create_installation(device_id, device_token, self.set_cookie())
                        #new app installation
                        #TODO: create app installation
                        # a) if exists with the device_id - update cookie etc
                        # b) else create the installation
                    else:
                        request_utils.out_error(self.response, error_definitions.msg_wrong_password,
                                                error_definitions.code_wrong_password)
                        return
            else:
                logger.warning("Going to create a user")
                user = user_model.create_user(login, password, device_id, device_token, 
                                              self.set_cookie())
                    
        except Exception, err:
            request_utils.out_error(self.response, err, 400, 400)


