import webapp2
import logging
from request_handlers import request_utils
import user_model
from constants import error_definitions, constants
import json

#TODO remove global loggers?
logger = logging.getLogger()
        

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
        app_install = user_model.user_installation(user, login_info.device_id)
        error_text = None
        if not app_install:
            error_text = user.validate_password(login_info.password)
        else:
            logger.info("user with the login&device_id was already logged in - it is normal to \
                login without password from the same device (%s)"%app_install)
             
        if error_text:
            raise endpoints.BadRequestException(error_text)
        else:
            app_install = user_model.create_installation(user, login_info.device_id,
                                                         login_info.device_token, app_install)
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
    for inst in user_model.user_app_installations(user):
        if inst.device_token and len (inst.device_token) > 0:
            pushable_installations.append(request_utils.human_datetime(inst.date))
    if len(pushable_installations) > 0:
        tools.push = pushable_installations
    return tools

def password_request(request):
    logger.info("request password")
    cookie = request.session.cookie
    logger.info("cookie = %s"%cookie)
    user = user_model.user_by_cookie(cookie)
    
    result = user.send_password(request.tool)
    resp = message.Tools()
    setattr(resp, request.tool, result)
    return resp

def user_update(request):
    cookie = request.session.cookie
    user = user_model.user_by_cookie(cookie)
    user.set_properties(request)
    return user.to_message()

def region_list(request):
    import ConfigParser
    import math
    config_file='./resources/regions_config.cfg'
    parser = ConfigParser.RawConfigParser()
    parser.read(config_file)
    my_region_name = None
    if request:
        if request.name and request.name in parser.sections():
            my_region_name = request.name
        
    region_list = message.RegionList()
    nearest_region = None
    min_distanse = -1
    for section in parser.sections():
        region = message.Region()
        unicode_content = parser.get(section, "name").decode('utf-8')
        region.name = unicode_content 
        region.latitude = float(parser.get(section, "latitude"))
        region.longitude = float(parser.get(section, "longitude"))
        region_list.regions.append(region)
        if my_region_name and my_region_name.lower() == section.lower():
            region_list.possible_region = region
        else :
            if request and request.latitude and request.longitude:
                distanse = math.hypot(region.latitude - request.latitude, 
                                 region.longitude - request.longitude)
                if min_distanse < 0 or distanse < min_distanse:
                    min_distanse = distanse 
                    nearest_region = region
    if not region_list.possible_region and nearest_region:
        region_list.possible_region = nearest_region
    return region_list


from Forecast import message as ForecastMessage

def forecasts(request):
    logger.info("forecasts")
    cookie = request.cookie
    logger.info("cookie = %s"%cookie)
    #user = user_model.user_by_cookie(cookie)
    region = "Novosibirsk"
    return ForecastMessage.region_spots(region)
