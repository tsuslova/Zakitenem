import webapp2
import logging
import request_utils
from model import user_model
from constants import error_definitions
import datetime

#TODO remove global loggers?
logger = logging.getLogger()

class AuthHandler(webapp2.RequestHandler):
        
    def set_cookie(self):
        import os
        logger.info("HERE")
        cookie = os.urandom(64).encode('base-64')
        #TODO check cookie generation
        logger.info("%s"%cookie) 
        #TODO: normal date
        self.response.set_cookie("session_id", cookie, expires=datetime.datetime(2030, 11, 10))
        logger.info("Cookie is set")
        return cookie
    

    def post(self, *args):
        try:
            logger.info("Authentication request")
            login_info = user_model.login_info_from_data(self.request.body) #
            logger.info("login_info %s"%login_info)
            
            if len(login_info.login) < 3: 
                request_utils.out_error(self.response, error_definitions.msg_wrong_login, 
                                        error_definitions.code_wrong_param)
                return
            if len(login_info.device_id) == 0:
                request_utils.out_error(self.response, error_definitions.msg_wrong_device_id, 
                                        error_definitions.code_wrong_param)
                return
            
            user = user_model.user_by_login(login_info.login)
            if (user):
                if not login_info.password:
                    request_utils.out_error(self.response, error_definitions.msg_account_used, 
                                            error_definitions.code_account_used)
                    return
                    
                if user.validate_password(login_info.password):
                    user.create_installation(login_info.device_id, login_info.device_token, 
                                             self.set_cookie())
                    #TODO: create app installation
                    # a) if exists with the device_id - update cookie etc
                    # b) else create the installation
                else:
                    request_utils.out_error(self.response, error_definitions.msg_wrong_password,
                                            error_definitions.code_wrong_password)
            else:
                logger.info("Going to create a user")
                user = user_model.create_user_from_login_info(login_info, self.set_cookie())
                
                self.response.headers.add_header("Content-Type", "application/json")
                self.response.out.write(user.resp())
                
                self.response.set_status(200)
        except Exception, err:
            request_utils.out_error(self.response, err, 400, 400)


