# -*- coding: cp1251 -*-
import webapp2
import logging
from request_handlers import request_utils
import user_model
from constants import error_definitions, constants
import json
import ConfigParser
import datetime

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
        logger.info("app_install= %s (%s)"%(app_install, login_info.device_id))
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
    installation = user_model.installation_by_cookie(cookie)
    user = user_model.user_by_installation(installation)
    
    # if a region for user wasn't really set yet (only region was set), we have to use a region 
    # from config file (to insert to database)
    
    if request and request.region:
        regionlist = None 
        if not request.region.name:
            regionlist = region_list(request.region.id, None, None)
        if not request.region.id:
            logger.info("Strange situation: request.region.id is None, but request.region!=None")
            regionlist = region_list(constants.default_region, None, None)
        if regionlist:
            request.region = regionlist.possible_region
    user.set_properties(request)
    return user.to_message(installation)

def region_list(region_id, latitude, longitude):
    import math
    config_file='./resources/regions_config.cfg'
    parser = ConfigParser.RawConfigParser()
    parser.read(config_file)
        
    regionlist = message.RegionList()
    nearest_region = None
    min_distanse = -1
    for section in parser.sections():
        region = message.Region()
        region.id = section
        unicode_content = parser.get(section, "name").decode('utf-8')
        region.name = unicode_content 
        region.latitude = float(parser.get(section, "latitude"))
        region.longitude = float(parser.get(section, "longitude"))
        regionlist.regions.append(region)
        if region_id and region_id.lower() == section.lower():
            regionlist.possible_region = region
        else :
            if latitude and longitude:
                distanse = math.hypot(region.latitude - latitude, region.longitude - longitude)
                if min_distanse < 0 or distanse < min_distanse:
                    min_distanse = distanse 
                    nearest_region = region
    if not regionlist.possible_region and nearest_region:
        regionlist.possible_region = nearest_region
    return regionlist

def request_region_list(request):
    return region_list(request.id, request.latitude, request.longitude)

from Forecast import message as ForecastMessage

def utc_today():
    today = datetime.date.today()
    today_time = datetime.datetime(today.year, today.month, today.day)
    logger.info("today_time = %s"%str(today_time))
    return today_time

def calculate_next_update_time(current_time):
    config_file='./resources/forecast_settings.cfg'
    parser = ConfigParser.RawConfigParser()
    parser.read(config_file)
    today_time = utc_today()
    logger.info("current_time %s"%str(current_time))
    for section in parser.sections():
        startHour = int(parser.get(section, "startHour"))
        startMinute = int(parser.get(section, "startMinute"))
        refreshPeriod = int(parser.get(section, "refreshPeriod"))
        
        next_period_start = today_time + datetime.timedelta(hours=startHour, minutes=startMinute)
        logger.info("check period %s"%next_period_start)
        if current_time < next_period_start:
            logger.info("period found %s"%str(next_period_start))
            return next_period_start
        elif current_time < next_period_start + datetime.timedelta(minutes=refreshPeriod):
            logger.info("in refreshPeriod, forecast updates are possible, check a minute later")
            logger.info("%s"%str(current_time + datetime.timedelta(minutes=1)))
            return current_time + datetime.timedelta(minutes=1)
    logger.info("the last period in current day is checked, use first period of next day")
    startHour = int(parser.get("UpdateTime0", "startHour"))
    startMinute = int(parser.get("UpdateTime0", "startMinute"))
    return today_time+datetime.timedelta(days=1, hours=startHour, minutes=startMinute)

def test_calculate_next_update_time():
    logger.info("forecasts")
    today_time = utc_today()
    logger.info("UTC 00:00")
    calculate_next_update_time(today_time)
    logger.info("UTC 04:00")
    calculate_next_update_time(today_time+datetime.timedelta(hours=4))
    logger.info("UTC 04:50")
    calculate_next_update_time(today_time+datetime.timedelta(hours=4, minutes=50))
    logger.info("UTC 12:00")
    calculate_next_update_time(today_time+datetime.timedelta(hours=12))
    logger.info("UTC 24:00")
    calculate_next_update_time(today_time+datetime.timedelta(hours=24))
    
    logger.info("Current time %s (%s)"%(datetime.datetime.now(), datetime.datetime.utcnow()))
    calculate_next_update_time(datetime.datetime.utcnow())
    
def get_user_forecasts(request):
    logger.info("get_user_forecasts")
    user = user_model.user_by_cookie(request.cookie)
    
    next_update_time = calculate_next_update_time(datetime.datetime.utcnow())

    region = constants.default_region 
    if user and user.region:
        region = user.region.id 
    else:
        logger.info("No user region found - use default one")
        
    user.forecast_get_time = datetime.datetime.now()
    user.put()
    return ForecastMessage.get_region_spots(region, next_update_time)

    
forecast_top_max_count = 10
def get_user_top_spots(request):
    
    logger.info("get_user_top_spots")
    user = user_model.user_by_cookie(request.cookie)
    #TODO : plus here user spot ratings at the top:
    user_ratings = []
    rest_count = forecast_top_max_count - len(user_ratings)
    
    region_ratings = user_model.SpotRatingItem.get_top_ratings(user, rest_count) 

    ratings = [rating.to_message() for rating in user_ratings+region_ratings]
    
    return ForecastMessage.SpotRatingList(ratings = ratings)

def add_status(request):
    logger.info("add_user_status")
    #print "add_user_status", request
    cookie = request.session.cookie
    logger.info("cookie = %s"%cookie)
    user = user_model.user_by_cookie(cookie)
    status_item = user_model.UserStatusItem.from_message(request, user)
    
    if not status_item:
        raise endpoints.BadRequestException(error_definitions.msg_wrong_parameters)
    
    user_model.SpotRatingItem.update_rating(status_item)
    status_item.put()
    
    


def get_user_status_list(request):
    logger.info("user_status_list")
    cookie = request.cookie
    logger.info("cookie = %s"%cookie)
    user = user_model.user_by_cookie(cookie)
    status_list = user_model.UserStatusItem.get_user_status_list(user)
    return status_list

def get_spot_status_list(request):
    logger.info("spot_status_list")
    logger.info("spot_id = %s" % request)
    status_list = user_model.UserStatusItem.get_spot_status_list(request)
    return status_list




    
