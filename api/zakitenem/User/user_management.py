import webapp2
import logging
from request_handlers import request_utils
import user_model
from constants import error_definitions, constants
import datetime
import json

#TODO remove global loggers?
logger = logging.getLogger()

class AuthHandler(webapp2.RequestHandler):
        
    def set_cookie(self):
        import os
        logger.info("HERE")
        cookie = os.urandom(64).encode("base-64")
        cookie = cookie.replace("\n", "")
        #TODO check cookie generation
        logger.info("%s"%cookie) 
        expires = datetime.datetime.utcnow() + datetime.timedelta(days=6*30) # expires in 6 months
        self.response.set_cookie(constants.cookie_key, cookie, expires=expires)
        logger.info("Cookie is set")
        return cookie
    
    def write_user_2_resp(self, user):
        self.response.headers.add_header("Content-Type", "application/json")
        self.response.out.write(user.resp())
        self.response.set_status(200)
        
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
                (error_text, error_code) = user.validate_password(login_info.password) 
                if error_text or error_code:
                    request_utils.out_error(self.response, error_text, error_code)
                else:
                    user.create_installation(login_info.device_id, login_info.device_token, 
                                             self.set_cookie())
                    self.write_user_2_resp(user)
            else:
                logger.info("Going to create a user")
                user, inst = user_model.create_user_from_login_info(login_info, self.set_cookie())
                if user and inst:
                    self.write_user_2_resp(user)
        except Exception, err:
            request_utils.out_error(self.response, err, 400, 400)



class PasswordRequestsHandler(webapp2.RequestHandler):
    
    def get(self, api_method):
        try:
            if api_method == "tools":
                logger.info("tools request")
                cookie = self.request.cookies.get(constants.cookie_key)
                logger.info("cookie = %s"%cookie)
                user = user_model.user_by_cookie(cookie)
                tools = {}
                if user.email and len(user.email) > 0:
                    tools[constants.option_email] = user.email
                pushable_installations = []
                for inst in user.app_installations:
                    if inst.device_token and len (inst.device_token) > 0:
                        pushable_installations.append(request_utils.human_datetime(inst.date))
                if len(pushable_installations) > 0:
                    tools[constants.option_push] = pushable_installations
                if len(tools.keys()) > 0:
                    self.response.headers.add_header("Content-Type", "application/json")
                    resp = {constants.tools_key:tools}
                    self.response.out.write(json.dumps(resp))
                else:
                    request_utils.out_error(self.response, error_definitions.msg_no_tools, 
                        error_definitions.code_no_tools)
        except Exception, err:
            request_utils.out_error(self.response, err, 400, 400)
            

    def post(self, api_method):
        try:
            resp = None
            if api_method == "request":
                logger.info("request password")
                tool_json = json.loads(self.request.body)
                tool = tool_json[constants.tool_key]
                cookie = self.request.cookies.get(constants.cookie_key)
                logger.info("cookie = %s"%cookie)
                user = user_model.user_by_cookie(cookie)
                
                user.send_password(tool)
                resp = {constants.tool_key:tool}
            if resp:
                self.response.headers.add_header("Content-Type", "application/json")
                self.response.out.write(json.dumps(resp))
        except Exception, err:
            request_utils.out_error(self.response, err, 400, 400)
        

class UserRequestsHandler(webapp2.RequestHandler):
    
    def post(self, api_method):
        try:
            resp = None
            if api_method == "set":
                logger.info("update user")
                update_json = json.loads(self.request.body)
                
                cookie = self.request.cookies.get(constants.cookie_key)
                user = user_model.user_by_cookie(cookie)
                user.set_properties(update_json)
                resp = user.resp()
            if api_method == "upload_userpic":
                logger.info("upload_userpic")
            
            if resp:
                self.response.headers.add_header("Content-Type", "application/json")
                self.response.out.write(resp)
                
        except Exception, err:
            request_utils.out_error(self.response, err, 400, 400)

import endpoints
from User import message

def check_auth_success(user, app_install, is_new_user):
    # It's not possible to create a user and an app_install in transaction as it's redundant
    # to set them common parent (so I cannot make an ancestor query, so if it fails cleanup 
    # and return an error    
    if user and app_install:
        return user.to_message(app_install)
    if not user and app_install:
        app_install.key.delete()
        raise endpoints.BadRequestException("Fail to create user")
    if user and not app_install:
        if is_new_user:
            # If it was an auth with a new user we should remove the user entity (without 
            # AppInstallation user will not be able to login - so it have to re-register in any case
            user.key.delete()
        raise endpoints.BadRequestException("Fail to create app_install")
    raise endpoints.BadRequestException("Fail to create user and app_install")
    
def auth(request):
    logger.info("Authentication request")
    login_info = user_model.LoginInfoItem.from_message(request) #
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
            app_install = user_model.create_installation(user,login_info.device_id,
                                                         login_info.device_token)
            return check_auth_success(user, app_install, False)
    else:
        logger.info("Going to create a user")
        user, app_install = user_model.create_user_from_login_info(login_info)
        return check_auth_success(user, app_install, True)
        
    
def logout(request):
    logger.info("Logout does nothing now. Before it removed the cookie from request, but it is not necessary any more")
    
def password_tools(request):
    logger.info("tools request")
    cookie = request.cookie
    logger.info("cookie = %s"%cookie)
    user = user_model.user_by_cookie(cookie)
    tools = message.Tools()
    if user.email and len(user.email) > 0:
        tools.email = user.email
    pushable_installations = []
    for inst in user.app_installations:
        if inst.device_token and len (inst.device_token) > 0:
            pushable_installations.append(request_utils.human_datetime(inst.date))
    if len(pushable_installations) > 0:
        tools.push = pushable_installations
    return tools
