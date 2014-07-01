import webapp2
import json
import logging
import random
import request_utils
import constants
import model

#TODO remove global loggers?
logger = logging.getLogger()

class AuthHandler(webapp2.RequestHandler):
        
    def post(self, *args):
        try:
            logger.warning("Authentication request")
            login_info = json.loads(self.request.body)
            if len(login_info[constants.login_key]) > 0:
                login = login_info[constants.login_key]
                password = login_info[constants.password_key]
#                 result = model.user_by_login(login, password)
#                 logger.warning(login)
#                 if result: 
#                     hostname = self.request.headers.get('host')
#                     user_json = json.dumps({"user-profile":result.to_dict(hostname)})
#                     self.response.out.write(user_json)
#                     set_response_headers(self.response)
#                     
#                     self.response.set_cookie("auth-token", result.cookie, expires=datetime(2030, 11, 10))
#                     self.response.set_status(200)
#                 else:
#                     request_utils.out_error(self.response, "wrong login-info", 403)    
            
        except Exception, err:
            request_utils.out_error(self.response, err, 400)


